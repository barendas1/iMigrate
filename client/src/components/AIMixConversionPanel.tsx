import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { AlertCircle, Brain, ChevronRight, Loader2, RotateCcw, Sparkles } from "lucide-react";
import { useState } from "react";
import * as XLSX from "xlsx";
import { convertMixesWithPlan } from "../converters/mixes/universal";
import type { MixConversionPlan, MixConversionResult, ValidationIssue } from "../converters/mixes/universal";

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

CRITICAL MAPPING RULES:
- Each mix creates MULTIPLE rows — one row per constituent material (Agg, Cem, Adm)
- Mix header columns (Plant Code through Dispatch) repeat on EVERY constituent row
- Aggregate and Cement → unit "kg"; Admixture → unit "ml/ckg CM"
- Mix Name AND Description BOTH come from the full descriptive name column (e.g. "Name", "Description") — NOT from the short code/ID column
- Constituent Item Description is always LEFT EMPTY in the output
- Strength (MPA) is extracted from the mix name (e.g., "20 MPa 10mm N" → 20)
- Min/Max Slump extracted from aggregate size pattern in name (e.g., "10/14mm" → Min=10 Max=14)
- All other output columns (Short Description, Item Category, Strength Age, Design Air Content, Design Slump, Max Water, etc.) are left EMPTY
- Constituents with non-empty material IDs ARE included in output even when target quantity is 0
- Only mixes where WaterTarget > 0 should be converted (skip zero-water mixes)

Return ONLY valid JSON (no markdown) with this exact structure:
{
  "analysis": "brief description of what was detected",
  "fileAnalyses": [
    {
      "fileName": "...",
      "headers": ["col1", "col2", "..."],
      "plantColumn": "column name or null",
      "mixIdColumn": "short mix code/identifier column or null",
      "mixNameColumn": "full descriptive name column (used for both Mix Name and Description output)",
      "waterTargetColumn": "water quantity column or null",
      "constituentColumns": {
        "aggregates": [{"id": "Agg1ID", "target": "Agg1Target"}, ...],
        "cements": [{"id": "Cem1ID", "target": "Cem1Target"}, ...],
        "admixtures": [{"id": "Adm1ID", "target": "Adm1Target"}, ...]
      }
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
- extract_strength: ask if mix names appear to contain MPa strength values. Default: "Yes - extract from name"
- extract_slump_range: ask if mix names contain size patterns like "10mm" or "10/14mm". Default: "Yes - extract min/max from name"
- adm_unit: ONLY ask if admixture unit is genuinely ambiguous. Default: "ml/ckg CM"

Do NOT ask about:
- Whether to include zero-quantity constituents (always include non-empty-ID rows)
- Whether to skip zero-water mixes (always skip)
- Constituent Item Description (always empty)
- Short Description, Item Category, Strength Age, Air Content, Design Slump, Max Water (always empty)`;

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

    try {
      const filePayloads = await Promise.all(
        files.map(async (f) => ({ data: await fileToArray(f), fileName: f.name }))
      );
      setFileDataCache(filePayloads);

      setStatusMessage("Analyzing column structure with AI...");

      const fileSummaries = filePayloads.map(({ data, fileName }) => {
        const headers = (data[0] || []).map((h) => String(h).replace(/^\uFEFF/, "").trim());
        const sampleRows = data.slice(1, 4);
        return { fileName, headers, sampleRows };
      });

      const analysis: AnalysisResult = await callOpenAI([
        { role: "system", content: ANALYSIS_SYSTEM_PROMPT },
        {
          role: "user",
          content: `Analyze these concrete mix files:\n${JSON.stringify(fileSummaries, null, 2)}`,
        },
      ]);

      // Initialize answers with AI-suggested defaults
      const defaultAnswers: Record<string, string> = {};
      for (const q of analysis.questions || []) {
        defaultAnswers[q.id] = q.default || (q.options?.[0] ?? "");
      }

      setAnalysisResult(analysis);
      setAnswers(defaultAnswers);
      setStatusMessage("");
      setPhase("questioning");
    } catch (err: any) {
      setPhase("idle");
      setAiError(err.message || "Failed to analyze files");
    }
  };

  const handleConvert = async () => {
    if (!analysisResult) return;
    setPhase("converting");
    setAiError(null);
    setStatusMessage("Building conversion plan...");

    try {
      const plan = buildPlanFromAnalysis(analysisResult, answers);

      setStatusMessage("Converting mixes...");
      const result: MixConversionResult = convertMixesWithPlan(fileDataCache, plan);

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

  return {
    plantColumn: primary.plantColumn ?? null,
    mixIdColumn: primary.mixIdColumn ?? null,
    // mixNameColumn drives both Mix Name and Description in the output
    mixNameColumn: primary.mixNameColumn ?? null,
    // These columns are detected but not used in output (fields are always empty)
    externalIdColumn: null,
    airFactorColumn: null,
    slumpColumn: null,
    waterTargetColumn: primary.waterTargetColumn ?? null,

    padPlantToTwoDigits: padPlant,
    extractStrengthFromName: extractStrength,
    extractSlumpRangeFromName: extractSlumpRange,
    // Always include non-empty-ID constituents regardless of quantity
    includeZeroQuantityConstituents: true,
    // Always skip mixes with no water target (they are inactive/template rows)
    skipZeroWaterMixes: true,

    admUnit,
    aggUnit: "kg",
    cemUnit: "kg",
    strengthAgeDefault: 28,
  };
}
