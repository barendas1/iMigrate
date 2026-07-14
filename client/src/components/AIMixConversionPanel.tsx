import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { AlertCircle, Brain, ChevronRight, Loader2, RotateCcw, Sparkles } from "lucide-react";
import { useState } from "react";
import * as XLSX from "xlsx";
import { convertMixesWithPlan } from "../converters/mixes/universal";
import type { MixConversionPlan, MixConversionResult, MixSkipBreakdown, ValidationIssue } from "../converters/mixes/universal";

// ── Types ────────────────────────────────────────────────────────────────────

interface AIQuestion {
  id: string;
  question: string;
  type: "select" | "boolean" | "text";
  options?: string[];
  default: string;
  context?: string;
}

interface FileAnalysis {
  fileName: string;
  headers: string[];
  plantColumn: string | null;
  mixIdColumn: string | null;
  mixNameColumn: string | null;
  externalIdColumn: string | null;
  airFactorColumn: string | null;
  slumpColumn: string | null;
  waterTargetColumn: string | null;
  constituentColumns: {
    aggregates: { id: string; target: string }[];
    cements: { id: string; target: string }[];
    admixtures: { id: string; target: string }[];
  };
  // Present when the file is long-format (one row PER CONSTITUENT, mix info
  // repeated across rows) rather than the wide Agg1../Cem1../Adm1.. layout.
  dataShape?: "wide" | "long";
  constituentIdColumn?: string | null;
  constituentNameColumn?: string | null;
  quantityColumn?: string | null;
  unitColumn?: string | null;
}

interface AnalysisResult {
  analysis: string;
  fileAnalyses: FileAnalysis[];
  questions: AIQuestion[];
}

interface AIMixConversionPanelProps {
  files: File[];
  fileToArray: (f: File) => Promise<any[][]>;
  onConversionComplete: (
    workbook: XLSX.WorkBook,
    issues: ValidationIssue[],
    stats: { totalInput: number; totalOutput: number; skipped: number }
  ) => void;
  onError: (error: string) => void;
}

type Phase = "idle" | "analyzing" | "questioning" | "converting";

// ── AI Prompts ───────────────────────────────────────────────────────────────

const ANALYSIS_SYSTEM_PROMPT = `You are an expert data migration assistant for concrete batch plant management software.

Analyze uploaded CSV files containing concrete mix formulas and identify how to map them to the Quadrel Command Series import format.

TARGET OUTPUT FORMAT columns:
Plant Code, Mix Name, Description, Short Description, Item Category,
Strength Age (Default 28), Strength (MPA), Design Air Content (%),
Min Air Content (%), Max Air Content (%), Design Slump (mm), Min Slump (mm),
Max Slump (mm), Max Batch Size, Max Water Liters, Max W/C+P, Max W/C,
"Mix Class Names, separate with semicolon", Mix Usage, Dispatch Slump Range, Dispatch,
Constituent Item Code, Constituent Item Description, Quantity, Unit Name

SOURCE FILES COME IN TWO POSSIBLE SHAPES — figure out which one you're looking at:

1. WIDE format: one row PER MIX, with constituents in repeated slot columns
   like Agg1Id/Agg1Target, Agg2Id/Agg2Target, ..., Cem1Id/Cem1Target, ...,
   Adm1Id/Adm1Target, ... (typical of MPAQ-style plant-control exports).

2. LONG format: one row PER CONSTITUENT — the mix ID/name, and often the
   plant/location, repeat across many rows, and each row carries a single
   constituent's ID, name, quantity, and unit of measure directly (typical
   of relational/junction-table exports, e.g. a "mix component" or
   "custom-location-design" table joined to a mix header table). A single
   row's plant/location field may itself list MULTIPLE plant codes
   separated by commas (e.g. "01, 02, 05") meaning the row applies to all
   of them — note this but do not try to resolve it yourself, the app
   explodes it automatically.

Set "dataShape" to "wide" or "long" based on which pattern the headers and
sample rows actually match. Do not force wide-format field names onto a file
that is clearly long-format, and vice versa.

CRITICAL MAPPING RULES:
- WIDE: each mix creates MULTIPLE output rows — one row per constituent material (Agg, Cem, Adm). Mix header columns (Plant Code through Dispatch) repeat on every constituent row. Aggregate and Cement → unit "kg"; Admixture → unit "ml/ckg CM".
- LONG: each source row already IS one constituent — map constituentIdColumn/constituentNameColumn/quantityColumn/unitColumn directly; do not invent Agg/Cem/Adm slot columns that don't exist in the file.
- Mix Name AND Description BOTH come from the full descriptive name column (e.g. "Name", "Description", "Mix Design Name") — NOT from the short code/ID column
- Constituent Item Description is always LEFT EMPTY in the output
- Strength (MPA) is extracted from the mix name (e.g., "20 MPa 10mm N" → 20; a US file with "3000 PSI" is converted automatically downstream — just confirm extractStrengthFromName)
- Min/Max Slump extracted from aggregate size pattern in name (e.g., "10/14mm" → Min=10 Max=14)
- All other output columns (Short Description, Item Category, Strength Age, Design Air Content, Design Slump, Max Water, etc.) are left EMPTY
- Constituents with non-empty material IDs ARE included in output even when target quantity is 0
- If a water-target-style column exists, only mixes where it's > 0 should be converted (skip zero-water mixes); if no such column exists in a long-format file, don't invent one

Return ONLY valid JSON (no markdown) with this exact structure:
{
  "analysis": "brief description of what was detected",
  "fileAnalyses": [
    {
      "fileName": "...",
      "headers": ["col1", "col2", "..."],
      "dataShape": "wide" or "long",
      "plantColumn": "column name or null",
      "mixIdColumn": "short mix code/identifier column or null",
      "mixNameColumn": "full descriptive name column (used for both Mix Name and Description output)",
      "waterTargetColumn": "water quantity column or null",
      "constituentColumns": {
        "aggregates": [{"id": "Agg1ID", "target": "Agg1Target"}, ...],
        "cements": [{"id": "Cem1ID", "target": "Cem1Target"}, ...],
        "admixtures": [{"id": "Adm1ID", "target": "Adm1Target"}, ...]
      },
      "constituentIdColumn": "column with the constituent material ID (long format only) or null",
      "constituentNameColumn": "column with the constituent material name (long format only) or null",
      "quantityColumn": "column with the constituent quantity (long format only) or null",
      "unitColumn": "column with the unit of measure for that quantity (long format only) or null"
    }
  ],
  "questions": [
    {
      "id": "unique_snake_case_id",
      "question": "clear concise question for the user",
      "type": "select",
      "options": ["Option A", "Option B"],
      "default": "Option A",
      "context": "why this matters (optional)"
    }
  ]
}

Only ask 2-4 questions about genuinely ambiguous cases. Avoid asking about things that are clear from the data.
Common questions to consider (only ask if truly ambiguous):
- plant_format: ONLY ask if plant values are numeric AND you cannot determine whether zero-padding is intended. Default: "As-is (no padding)"
- extract_strength: ask if mix names appear to contain MPa/PSI strength values. Default: "Yes - extract from name"
- extract_slump_range: ask if mix names contain size patterns like "10mm" or "10/14mm". Default: "Yes - extract min/max from name"
- adm_unit: ONLY ask if admixture unit is genuinely ambiguous. Default: "ml/ckg CM"

Do NOT ask about:
- Whether to include zero-quantity constituents (always include non-empty-ID rows)
- Whether to skip zero-water mixes (always skip, only when a water-target column actually exists)
- Constituent Item Description (always empty)
- Short Description, Item Category, Strength Age, Air Content, Design Slump, Max Water (always empty)

IMPORTANT — NEVER LEAVE THE USER STUCK:
If you cannot confidently identify the required structure for EITHER format
(no mixIdColumn, or no usable constituent columns in either shape), do NOT
just describe the limitation in "analysis" and stop there — that leaves the
user with no way to proceed. Instead, ask 1-3 questions of type "text" that
directly ask the user to name the exact column(s) you couldn't determine
(e.g. "Which column contains the constituent material ID/code for each
row?"), with your best guess pre-filled as the "default" so the user only
has to confirm or correct it, not start from a blank field.`;

// ── Deterministic safety net ────────────────────────────────────────────────
// The AI is instructed to always ask clarifying questions when it can't map
// a file, but LLM output can't be trusted 100% of the time (it might still
// return an "analysis" sentence with no usable columns and no questions).
// This client-side check runs regardless of what the AI actually did, so the
// user is NEVER left with a dead-end "Convert" button that's guaranteed to
// fail — if the structure genuinely can't be determined, we always inject
// manual-mapping questions ourselves.

function guessHeader(headers: string[], keywords: string[]): string {
  const lower = headers.map((h) => h.toLowerCase());
  for (const kw of keywords) {
    const idx = lower.findIndex((h) => h === kw);
    if (idx !== -1) return headers[idx];
  }
  for (const kw of keywords) {
    const idx = lower.findIndex((h) => h.includes(kw));
    if (idx !== -1) return headers[idx];
  }
  return "";
}

function hasWideStructure(a: FileAnalysis | undefined): boolean {
  if (!a) return false;
  const cc = a.constituentColumns;
  const wideCount =
    (cc?.aggregates?.length ?? 0) + (cc?.cements?.length ?? 0) + (cc?.admixtures?.length ?? 0);
  return !!a.mixIdColumn && wideCount > 0;
}

function hasLongStructure(a: FileAnalysis | undefined): boolean {
  if (!a) return false;
  return a.dataShape === "long" && !!a.mixIdColumn && !!a.constituentIdColumn && !!a.quantityColumn;
}

function needsManualMapping(a: FileAnalysis | undefined): boolean {
  return !hasWideStructure(a) && !hasLongStructure(a);
}

// Builds a guaranteed-actionable set of manual mapping questions from the raw
// file headers alone (no AI needed), pre-filled with best guesses so the user
// mostly just confirms rather than typing column names from scratch.
function buildManualMappingQuestions(headers: string[]): AIQuestion[] {
  return [
    {
      id: "manual_data_shape",
      question: "How is each row in this file structured?",
      type: "select",
      options: [
        "One row per constituent (mix info repeats across multiple rows)",
        "One row per mix (constituents are in separate Agg/Cem/Adm columns)",
      ],
      default: "One row per constituent (mix info repeats across multiple rows)",
      context: "We couldn't determine this automatically — pick whichever matches your file.",
    },
    {
      id: "manual_mix_id_column",
      question: "Which column identifies the mix design (a code or ID shared by every row of that mix)?",
      type: "text",
      default: guessHeader(headers, ["mix design id", "mix id", "mixid", "mix code", "id"]),
    },
    {
      id: "manual_mix_name_column",
      question: "Which column has the full mix name/description?",
      type: "text",
      default: guessHeader(headers, ["mix design name", "mix name", "description", "name"]),
    },
    {
      id: "manual_plant_column",
      question: "Which column has the plant/location code? (If a row can list multiple plants separated by commas, that's fine — it'll be split automatically.)",
      type: "text",
      default: guessHeader(headers, ["location id", "plant code", "plant id", "plant", "location"]),
    },
    {
      id: "manual_constituent_id_column",
      question: "Only if one row = one constituent: which column has the constituent material ID/code?",
      type: "text",
      default: guessHeader(headers, ["mix component id", "component id", "material id", "constituent id", "item code"]),
    },
    {
      id: "manual_quantity_column",
      question: "Only if one row = one constituent: which column has the quantity for that constituent?",
      type: "text",
      default: guessHeader(headers, ["quantity", "target", "amount"]),
    },
    {
      id: "manual_unit_column",
      question: "Only if one row = one constituent: which column has the unit of measure for that quantity?",
      type: "text",
      default: guessHeader(headers, ["unit of measure", "uom", "unit"]),
    },
  ];
}

// A plan that "looks" convertible (passes planLooksConvertible below) can
// still legitimately produce zero output rows — e.g. a mismapped water-target
// column filters out every row. That's just as much a dead end as a failed
// analysis, so it gets the same treatment: explain exactly why, and offer a
// concrete, pre-filled way to fix it rather than a bare "0 output rows".

function buildZeroOutputQuestions(
  headers: string[],
  breakdown: MixSkipBreakdown,
  waterTargetColumnUsed: string | null
): AIQuestion[] {
  const qs: AIQuestion[] = [];
  const dominantKey = (Object.entries(breakdown) as [keyof MixSkipBreakdown, number][])
    .sort((a, b) => b[1] - a[1])[0]?.[0];

  if (breakdown.zeroWaterFiltered > 0) {
    qs.push({
      id: "disable_zero_water_filter",
      question: "Every affected row was removed by the zero-water-mix filter. Disable it and keep those rows?",
      type: "select",
      options: ["Yes - disable filter", "No - keep filtering"],
      default: "Yes - disable filter",
      context: waterTargetColumnUsed
        ? `This filter checked column "${waterTargetColumnUsed}", which was empty or zero for every affected row — it may not be a real water-target column for this file.`
        : "A water-target column was applied here even though none should have been — this usually means the wrong column got mapped.",
    });
  }

  // If the water filter wasn't the dominant cause, the structural column
  // mapping itself is probably wrong (not just one filter) — offer a full
  // manual remap so the user isn't stuck re-running the same bad guess.
  if (dominantKey !== "zeroWaterFiltered") {
    qs.push(...buildManualMappingQuestions(headers));
  }

  return qs;
}

function describeZeroOutput(breakdown: MixSkipBreakdown, totalInput: number): string {
  const parts: string[] = [];
  if (breakdown.zeroWaterFiltered) parts.push(`${breakdown.zeroWaterFiltered} filtered out by the zero-water-mix rule`);
  if (breakdown.missingIdentifiers) parts.push(`${breakdown.missingIdentifiers} missing a Mix ID/Constituent ID`);
  if (breakdown.noPlantAssigned) parts.push(`${breakdown.noPlantAssigned} with no plant/location assigned`);
  if (breakdown.noConstituents) parts.push(`${breakdown.noConstituents} with no constituents found`);
  if (breakdown.other) parts.push(`${breakdown.other} for other reasons`);
  const detail = parts.length ? parts.join("; ") : "for reasons that couldn't be categorized";
  return `That produced 0 output rows — all ${totalInput} input row(s) were skipped (${detail}). Fix the item(s) below and convert again.`;
}

// ── Component ────────────────────────────────────────────────────────────────

export function AIMixConversionPanel({
  files,
  fileToArray,
  onConversionComplete,
  onError,
}: AIMixConversionPanelProps) {
  const apiKey = import.meta.env.VITE_OPENAI_API_KEY || "";

  const [phase, setPhase] = useState<Phase>("idle");
  const [analysisResult, setAnalysisResult] = useState<AnalysisResult | null>(null);
  const [answers, setAnswers] = useState<Record<string, string>>({});
  const [fileDataCache, setFileDataCache] = useState<{ data: any[][]; fileName: string }[]>([]);
  const [statusMessage, setStatusMessage] = useState("");
  const [aiError, setAiError] = useState<string | null>(null);

  const callOpenAI = async (messages: { role: string; content: string }[]) => {
    const response = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: "gpt-4o-mini",
        messages,
        temperature: 0.1,
        response_format: { type: "json_object" },
      }),
    });

    if (!response.ok) {
      const err = await response.json();
      throw new Error(err.error?.message || "OpenAI API request failed");
    }

    const result = await response.json();
    return JSON.parse(result.choices[0].message.content);
  };

  const handleAnalyze = async () => {
    if (!files.length) return;
    setPhase("analyzing");
    setAiError(null);
    setStatusMessage("Reading files...");

    let filePayloads: { data: any[][]; fileName: string }[];
    try {
      filePayloads = await Promise.all(
        files.map(async (f) => ({ data: await fileToArray(f), fileName: f.name }))
      );
      setFileDataCache(filePayloads);
    } catch (err: any) {
      // Genuinely can't proceed \u2014 the file itself couldn't be read.
      setPhase("idle");
      setAiError(err.message || "Failed to read the uploaded file(s).");
      return;
    }

    setStatusMessage("Analyzing column structure with AI...");

    const fileSummaries = filePayloads.map(({ data, fileName }) => {
      const headers = (data[0] || []).map((h) => String(h).replace(/^\uFEFF/, "").trim());
      const sampleRows = data.slice(1, 4);
      return { fileName, headers, sampleRows };
    });

    let analysis: AnalysisResult | null = null;
    let analyzeError: string | null = null;
    try {
      analysis = await callOpenAI([
        { role: "system", content: ANALYSIS_SYSTEM_PROMPT },
        {
          role: "user",
          content: `Analyze these concrete mix files:\n${JSON.stringify(fileSummaries, null, 2)}`,
        },
      ]);
    } catch (err: any) {
      analyzeError = err.message || "AI analysis failed.";
    }

    // Never dead-end: whether the AI call failed outright, or it returned but
    // couldn't confidently identify the file's structure, fall back to a
    // deterministic manual-mapping question set built from the raw headers \u2014
    // the user always has a way to proceed without needing the AI to succeed.
    const primaryHeaders = fileSummaries[0]?.headers ?? [];
    const primaryAnalysis = analysis?.fileAnalyses?.[0];
    const stuck = !analysis || needsManualMapping(primaryAnalysis);

    if (!analysis) {
      analysis = {
        analysis:
          "AI analysis couldn't run, so we've prepared manual mapping questions instead \u2014 please fill these in from your file's columns.",
        fileAnalyses: [],
        questions: [],
      };
    } else if (stuck) {
      analysis = {
        ...analysis,
        analysis:
          (analysis.analysis ? analysis.analysis + " " : "") +
          "We couldn't fully determine this file's structure automatically \u2014 please confirm the columns below.",
      };
    }

    if (stuck) {
      analysis.questions = [...(analysis.questions || []), ...buildManualMappingQuestions(primaryHeaders)];
    }

    // Initialize answers with AI-suggested (or manual-fallback) defaults
    const defaultAnswers: Record<string, string> = {};
    for (const q of analysis.questions || []) {
      defaultAnswers[q.id] = q.default || (q.options?.[0] ?? "");
    }

    setAnalysisResult(analysis);
    setAnswers(defaultAnswers);
    setStatusMessage("");
    // Surface the AI failure as a non-blocking note \u2014 manual questions above still let them proceed.
    setAiError(analyzeError);
    setPhase("questioning");
  };

  const handleConvert = async () => {
    if (!analysisResult) return;
    setPhase("converting");
    setAiError(null);
    setStatusMessage("Building conversion plan...");

    try {
      const plan = buildPlanFromAnalysis(analysisResult, answers);

      const problem = planLooksConvertible(plan);
      if (problem) {
        setPhase("questioning");
        setAiError(problem);
        return;
      }

      setStatusMessage("Converting mixes...");
      const result: MixConversionResult = convertMixesWithPlan(fileDataCache, plan);

      // A plan that passed the preflight check can still legitimately convert
      // to nothing (e.g. a mismapped water-target column filters out every
      // row). Never report that as a silent/blank success — diagnose it and
      // hand the user a concrete, pre-filled way to fix it.
      if (result.totalOutputRows === 0) {
        const headers = (fileDataCache[0]?.data?.[0] ?? []).map((h: any) =>
          String(h ?? "").replace(/^﻿/, "").trim()
        );
        const newQuestions = buildZeroOutputQuestions(headers, result.skipBreakdown, plan.waterTargetColumn ?? null);

        setAnalysisResult((prev) => {
          const base: AnalysisResult = prev ?? { analysis: "", fileAnalyses: [], questions: [] };
          const existingIds = new Set((base.questions || []).map((q) => q.id));
          const filteredNew = newQuestions.filter((q) => !existingIds.has(q.id));
          return {
            ...base,
            analysis: describeZeroOutput(result.skipBreakdown, result.totalInputMixes),
            questions: [...(base.questions || []), ...filteredNew],
          };
        });
        setAnswers((prev) => {
          const merged = { ...prev };
          for (const q of newQuestions) {
            if (merged[q.id] === undefined) merged[q.id] = q.default || (q.options?.[0] ?? "");
          }
          return merged;
        });
        setPhase("questioning");
        return;
      }

      const wb = XLSX.utils.book_new();
      const ws = XLSX.utils.aoa_to_sheet(result.rows);
      XLSX.utils.book_append_sheet(wb, ws, "Mix Import");

      onConversionComplete(wb, result.issues, {
        totalInput: result.totalInputMixes,
        totalOutput: result.totalOutputRows,
        skipped: result.skippedMixes,
      });
    } catch (err: any) {
      setPhase("questioning");
      setAiError(err.message || "Conversion failed");
      onError(err.message || "Conversion failed");
    }
  };

  const handleReset = () => {
    setPhase("idle");
    setAnalysisResult(null);
    setAnswers({});
    setFileDataCache([]);
    setAiError(null);
    setStatusMessage("");
  };

  // ── Render ────────────────────────────────────────────────────────────────

  if (phase === "idle") {
    return (
      <div className="flex items-center justify-end gap-3 mt-4">
        <Button
          size="lg"
          className="bg-primary hover:bg-primary-hover text-white shadow-md hover:shadow-lg transition-all"
          disabled={files.length === 0 || !apiKey}
          onClick={handleAnalyze}
        >
          <Brain className="mr-2 h-5 w-5" />
          Analyze & Convert with AI
        </Button>
        {!apiKey && (
          <p className="text-xs text-destructive">VITE_OPENAI_API_KEY not set in .env</p>
        )}
      </div>
    );
  }

  if (phase === "analyzing" || phase === "converting") {
    return (
      <div className="flex items-center justify-end gap-3 mt-4">
        <div className="flex items-center gap-3 text-primary">
          <Loader2 className="h-5 w-5 animate-spin" />
          <span className="text-sm font-medium">{statusMessage || "Processing..."}</span>
        </div>
      </div>
    );
  }

  // phase === "questioning"
  return (
    <div className="mt-4 space-y-4">
      {/* Analysis summary */}
      {analysisResult?.analysis && (
        <div className="bg-primary/5 border border-primary/20 rounded-lg px-4 py-3 flex items-start gap-3">
          <Sparkles className="h-4 w-4 text-primary mt-0.5 shrink-0" />
          <p className="text-sm text-dark">{analysisResult.analysis}</p>
        </div>
      )}

      {/* AI error */}
      {aiError && (
        <div className="bg-destructive/10 border border-destructive/20 rounded-lg p-3 flex items-start gap-2 text-destructive">
          <AlertCircle className="h-4 w-4 mt-0.5 shrink-0" />
          <p className="text-sm">{aiError}</p>
        </div>
      )}

      {/* Questions */}
      {analysisResult?.questions && analysisResult.questions.length > 0 && (
        <Card className="border-border">
          <CardContent className="pt-4 pb-4 space-y-4">
            <p className="text-sm font-semibold text-dark flex items-center gap-2">
              <Brain className="h-4 w-4 text-primary" />
              AI needs your input on {analysisResult.questions.length} item
              {analysisResult.questions.length !== 1 ? "s" : ""}:
            </p>

            {analysisResult.questions.map((q) => (
              <div key={q.id} className="space-y-1.5">
                <Label className="text-sm font-medium text-dark">{q.question}</Label>
                {q.context && (
                  <p className="text-xs text-muted-foreground">{q.context}</p>
                )}

                {q.type === "select" && q.options && q.options.length > 0 ? (
                  <Select
                    value={answers[q.id] ?? q.default}
                    onValueChange={(val) =>
                      setAnswers((prev) => ({ ...prev, [q.id]: val }))
                    }
                  >
                    <SelectTrigger className="w-full max-w-md">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {q.options.map((opt) => (
                        <SelectItem key={opt} value={opt}>
                          {opt}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                ) : q.type === "boolean" ? (
                  <Select
                    value={answers[q.id] ?? q.default}
                    onValueChange={(val) =>
                      setAnswers((prev) => ({ ...prev, [q.id]: val }))
                    }
                  >
                    <SelectTrigger className="w-full max-w-md">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="Yes">Yes</SelectItem>
                      <SelectItem value="No">No</SelectItem>
                    </SelectContent>
                  </Select>
                ) : (
                  <Textarea
                    rows={2}
                    className="max-w-md resize-none"
                    value={answers[q.id] ?? q.default}
                    onChange={(e) =>
                      setAnswers((prev) => ({ ...prev, [q.id]: e.target.value }))
                    }
                  />
                )}
              </div>
            ))}
          </CardContent>
        </Card>
      )}

      {/* Action buttons */}
      <div className="flex items-center justify-end gap-3">
        <Button
          size="lg"
          variant="outline"
          className="border-muted-foreground/30 text-muted-foreground hover:bg-secondary/10"
          onClick={handleReset}
        >
          <RotateCcw className="mr-2 h-4 w-4" />
          Re-analyze
        </Button>
        <Button
          size="lg"
          className="bg-primary hover:bg-primary-hover text-white shadow-md hover:shadow-lg transition-all"
          onClick={handleConvert}
        >
          <ChevronRight className="mr-2 h-5 w-5" />
          Convert with AI
        </Button>
      </div>
    </div>
  );
}

// ── Plan builder ─────────────────────────────────────────────────────────────

/**
 * Build a deterministic MixConversionPlan from AI analysis + user Q&A answers.
 * No second AI call needed — the plan is derived directly from the analysis data
 * and confirmed user choices.
 */
function buildPlanFromAnalysis(
  analysis: AnalysisResult,
  answers: Record<string, string>
): MixConversionPlan {
  // Use first file's analysis as the primary mapping source
  const primary = analysis.fileAnalyses?.[0] ?? ({} as FileAnalysis);

  const ans = (id: string) => answers[id] ?? "";
  const isNo = (id: string) =>
    ans(id).toLowerCase().startsWith("no") || ans(id) === "false";
  const trimmedOrNull = (v: string) => (v && v.trim() ? v.trim() : null);

  // Manual mapping answers (present when the deterministic fallback questions
  // were shown, see buildManualMappingQuestions) always win — they're the
  // user's explicit confirmation/correction, not a guess.
  const hasManualAnswers = ans("manual_data_shape") !== "";

  const dataShape: "wide" | "long" | undefined = hasManualAnswers
    ? (ans("manual_data_shape").toLowerCase().startsWith("one row per mix") ? "wide" : "long")
    : primary.dataShape;

  const plantColumn = hasManualAnswers
    ? trimmedOrNull(ans("manual_plant_column"))
    : primary.plantColumn ?? null;
  const mixIdColumn = hasManualAnswers
    ? trimmedOrNull(ans("manual_mix_id_column"))
    : primary.mixIdColumn ?? null;
  const mixNameColumn = hasManualAnswers
    ? trimmedOrNull(ans("manual_mix_name_column"))
    : primary.mixNameColumn ?? null;
  const constituentIdColumn = hasManualAnswers
    ? trimmedOrNull(ans("manual_constituent_id_column"))
    : primary.constituentIdColumn ?? null;
  const constituentNameColumn = hasManualAnswers ? null : primary.constituentNameColumn ?? null;
  const quantityColumn = hasManualAnswers
    ? trimmedOrNull(ans("manual_quantity_column"))
    : primary.quantityColumn ?? null;
  const unitColumn = hasManualAnswers
    ? trimmedOrNull(ans("manual_unit_column"))
    : primary.unitColumn ?? null;

  // Plant zero-padding: only if the user explicitly chose a padded option
  const padPlant =
    ans("plant_format").toLowerCase().includes("zero") ||
    ans("plant_format").toLowerCase().includes("pad");

  // Strength extraction: default YES unless user said No
  const extractStrength = !isNo("extract_strength");

  // Slump range extraction: default YES unless user said No
  const extractSlumpRange = !isNo("extract_slump_range");

  // Admixture unit: user choice or standard default
  const admUnitAns = ans("adm_unit");
  const admUnit = admUnitAns && admUnitAns !== "" ? admUnitAns : "ml/ckg CM";

  // Zero-water-mix filter: on by default (inactive/template mixes usually
  // have no water target), but the zero-output diagnosis flow
  // (buildZeroOutputQuestions) offers to disable it when it turns out to be
  // wiping out every row — e.g. a mismapped or nonexistent water column.
  const skipZeroWaterMixes = !ans("disable_zero_water_filter").toLowerCase().startsWith("yes");

  return {
    plantColumn,
    mixIdColumn,
    // mixNameColumn drives both Mix Name and Description in the output
    mixNameColumn,
    // These columns are detected but not used in output (fields are always empty)
    externalIdColumn: null,
    airFactorColumn: null,
    slumpColumn: null,
    waterTargetColumn: primary.waterTargetColumn ?? null,

    dataShape,
    constituentIdColumn,
    constituentNameColumn,
    quantityColumn,
    unitColumn,

    padPlantToTwoDigits: padPlant,
    extractStrengthFromName: extractStrength,
    extractSlumpRangeFromName: extractSlumpRange,
    // Always include non-empty-ID constituents regardless of quantity
    includeZeroQuantityConstituents: true,
    skipZeroWaterMixes,

    admUnit,
    aggUnit: "kg",
    cemUnit: "kg",
    strengthAgeDefault: 28,
  };
}

/**
 * Preflight check before running the actual conversion. Returns a
 * user-actionable message if the plan is missing something essential, or
 * null if it's safe to proceed. This turns a would-be thrown error deep in
 * the converter into a clear "here's what to fix" message that keeps the
 * user in the questioning phase instead of dead-ending on a generic failure.
 */
function planLooksConvertible(plan: MixConversionPlan): string | null {
  if (!plan.mixIdColumn) {
    return "Could not determine which column is the Mix ID — please answer the mapping question above and try again.";
  }
  if (plan.dataShape === "long" && (!plan.constituentIdColumn || !plan.quantityColumn)) {
    return "This file needs both a constituent ID column and a quantity column identified above before it can be converted.";
  }
  return null;
}
