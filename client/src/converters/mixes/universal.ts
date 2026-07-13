/**
 * Universal Mixes Converter
 *
 * Converts any customer mix export to the Quadrel Command Series import format.
 *
 * Key features:
 * - Auto-detects column structure from uploaded file headers (flexible naming)
 * - Supports AI-assisted conversion via MixConversionPlan
 * - Expands each mix into one row per constituent material
 * - Supports merging output from multiple mix files into one consolidated sheet
 * - Units: kg for aggregates/cement, ml/ckg CM for admixtures
 */

// ---------- CONFIG ----------
export const PLANTS = ["01", "02", "03", "05", "06"];

const AGG_COUNT = 6;  // Agg1..Agg6
const CEM_COUNT = 4;  // Cem1..Cem4
const ADM_COUNT = 8;  // Adm1..Adm8

// ---------- OUTPUT COLUMNS ----------
export const MIX_TEMPLATE_COLUMNS = [
  "Plant Code",
  "Mix Name",
  "Description",
  "Short Description",
  "Item Category",
  "Strength Age (Default 28)",
  "Strength (MPA)",
  "Design Air Content (%)",
  "Min Air Content (%)",
  "Max Air Content (%)",
  "Design Slump (mm)",
  "Min Slump (mm)",
  "Max Slump (mm)",
  "Max Batch Size",
  "Max Water Liters",
  "Max W/C+P",
  "Max W/C",
  "Mix Class Names, separate with semicolon",
  "Mix Usage",
  "Dispatch Slump Range",
  "Dispatch",
  "Constituent Item Code",
  "Constituent Item Description",
  "Quantity",
  "Unit Name",
];

// ---------- VALIDATION ----------
export interface ValidationIssue {
  type: "error" | "warning";
  message: string;
  row?: number;
  field?: string;
}

export interface MixConversionResult {
  rows: any[][];
  issues: ValidationIssue[];
  skippedMixes: number;
  totalInputMixes: number;
  totalOutputRows: number;
  unitSystem: UnitSystem;
}

// Valid recipe quantity units — SI mixes (metric plant, slump in mm)
export const VALID_RECIPE_UNITS_SI = new Set(
  ["lb","ga","oz","fl oz","fluid oz","l","lt","liters","litre","kg","ml","ml-liter",
   "gal","gl","lq oz","ounces","oz/cwt cm","pounds","gallons","cubic yards","each","cc","gr",
   "ml/ckg cm"].map((u) => u.toLowerCase())
);

// Valid recipe quantity units — US mixes (imperial plant, slump in inches)
export const VALID_RECIPE_UNITS_US = new Set(
  ["ml/m3","ml/100kg","ml/100kg cm","oz/cwt","cy","lb","ga","oz","fl oz","fluid oz","fo",
   "l","lt","liters","kg","kilograms","ml","milliliters","gal","gl","lq oz","ounces",
   "oz/cwt cm","pounds","gallons","per cubic yard","cubic yards","ea","each","cc","gr",
   "bg","bag","bags","ml/ckg cm"].map((u) => u.toLowerCase())
);

// Combined: a unit valid in either system passes
const VALID_RECIPE_UNITS_ANY = new Set([
  ...Array.from(VALID_RECIPE_UNITS_SI),
  ...Array.from(VALID_RECIPE_UNITS_US),
]);

// ---------- AI CONVERSION PLAN ----------

/**
 * Plan produced by AI analysis + user Q&A answers.
 * Drives the AI-assisted conversion path.
 */
export type UnitSystem = "SI" | "US";

export interface MixConversionPlan {
  // Column mappings (detected by AI from file headers)
  plantColumn: string | null;
  mixIdColumn: string | null;       // fallback identifier (only used if mixNameColumn absent)
  mixNameColumn: string | null;     // full descriptive name → both Mix Name AND Description
  externalIdColumn: string | null;  // reserved
  airFactorColumn: string | null;   // reserved
  slumpColumn: string | null;       // reserved
  waterTargetColumn: string | null; // used only for zero-water filter

  // Data shape: "wide" = one row per mix with Agg1..Agg6/Cem1..Cem4/Adm1..Adm8
  // slot columns (e.g. MPAQ-style exports). "long" = one row PER CONSTITUENT,
  // with the mix identifier/name repeated across rows (e.g. relational/
  // junction-table exports). Omit to use the wide-format detection path.
  dataShape?: "wide" | "long";
  // Only used when dataShape === "long"
  constituentIdColumn?: string | null;
  constituentNameColumn?: string | null;
  quantityColumn?: string | null;
  unitColumn?: string | null;

  // Unit system (omit to auto-detect from file data)
  unitSystem?: UnitSystem;

  // Transformation rules (confirmed by user)
  padPlantToTwoDigits: boolean;
  extractStrengthFromName: boolean;
  extractSlumpRangeFromName: boolean;
  includeZeroQuantityConstituents: boolean;
  admUnit: string;
  aggUnit: string;
  cemUnit: string;
  strengthAgeDefault: number;
  skipZeroWaterMixes: boolean;
}

// ---------- HELPER FUNCTIONS ----------

function isEmptyValue(val: any): boolean {
  return (
    val === null ||
    val === undefined ||
    String(val).trim() === "" ||
    (typeof val === "number" && isNaN(val))
  );
}

function isZeroOrEmpty(val: any): boolean {
  return isEmptyValue(val) || val === 0 || val === "0" || parseFloat(String(val)) === 0;
}

function safeStr(val: any): string {
  return isEmptyValue(val) ? "" : String(val).trim();
}

// Raw UOM/inventory codes some source systems use instead of display-ready
// unit names (e.g. "STN" for tons, "GLL"/"GLI" for gallons). Normalize these
// to a friendly unit name before validating/outputting; anything not in this
// map is passed through unchanged.
const UOM_CODE_NORMALIZE: Record<string, string> = {
  lbr: "lb", onz: "oz", oza: "oz", gll: "ga", gli: "ga",
  stn: "ton", ydq: "yd", ea: "ea",
};

function normalizeUnitCode(raw: any): string {
  const s = safeStr(raw);
  if (!s) return s;
  return UOM_CODE_NORMALIZE[s.toLowerCase()] ?? s;
}

// Some sources list multiple plant/location codes in a single cell
// (e.g. "01, 02, 05") meaning the same mix/constituent applies to each —
// split those into an explicit list so the row can be exploded downstream.
function splitPlantList(raw: any): string[] {
  const s = safeStr(raw);
  if (!s) return [];
  return s.split(/[,;]/).map((p) => p.trim()).filter(Boolean);
}

// ---------- UNIT DETECTION ----------

const PSI_TO_MPA = 0.00689476;
const IN_TO_MM = 25.4;

/**
 * Detect whether a file's data is in SI (metric) or US (imperial) units.
 *
 * Checks (in order of priority):
 *  1. IsMetric column (MPAQ export has this)
 *  2. Mix name contains explicit "MPa" / "PSI" keywords
 *  3. Mix name contains "mm" / "in" / '"' size patterns
 *  4. Slump column magnitude (< 12 → likely inches; > 25 → likely mm)
 */
export function detectUnitSystem(
  headers: string[],
  data: Record<string, any>[]
): UnitSystem {
  const sampleSize = Math.min(data.length, 10);
  const sample = data.slice(0, sampleSize);

  // 1. IsMetric column
  const isMetricCol = findHeader(headers, ["IsMetric", "Is Metric", "Metric"]);
  if (isMetricCol) {
    const vals = sample.map((r) => String(r[isMetricCol] ?? "").trim().toLowerCase());
    if (vals.some((v) => v === "true" || v === "1" || v === "yes")) return "SI";
    if (vals.some((v) => v === "false" || v === "0" || v === "no")) return "US";
  }

  // 2 & 3. Mix name keywords
  const nameCol = findHeader(headers, ["Name", "MixName", "Mix Name", "Description"]);
  if (nameCol) {
    const names = sample.map((r) => String(r[nameCol] ?? "").toLowerCase());
    if (names.some((n) => /\bmpa\b/i.test(n))) return "SI";
    if (names.some((n) => /\bpsi\b/i.test(n))) return "US";
    if (names.some((n) => /\d+mm/i.test(n))) return "SI";
    if (names.some((n) => /\d+\s*["']|\d+\s*in\b/i.test(n))) return "US";
  }

  // 4. Slump magnitude
  const slumpCol = findHeader(headers, ["Slump", "SlumpTarget", "Slump Target"]);
  if (slumpCol) {
    const slumps = sample
      .map((r) => parseFloat(String(r[slumpCol] ?? "")))
      .filter((v) => !isNaN(v) && v > 0);
    if (slumps.length > 0) {
      const avg = slumps.reduce((a, b) => a + b, 0) / slumps.length;
      if (avg < 12) return "US";   // typical US slump: 2–6 inches
      if (avg > 25) return "SI";   // typical SI slump: 50–200 mm
    }
  }

  return "SI"; // safe default
}

// ---------- UNIT-AWARE EXTRACTION ----------

/**
 * Extract strength in MPA from a mix name.
 * SI: "20 MPa 10/14mm N" → 20
 * US: "4000 PSI 3/4in N" → 4000 * 0.00689476 ≈ 27.6 (rounded to 1 dp)
 * Fallback: leading number treated as MPa (SI) or PSI (US)
 */
function extractStrength(name: any, unitSystem: UnitSystem = "SI"): number | string {
  if (isEmptyValue(name)) return "";
  const s = String(name);

  if (unitSystem === "US") {
    // Explicit PSI label
    const psiMatch = s.match(/([\d,]+)\s*psi/i);
    if (psiMatch) {
      const psi = parseFloat(psiMatch[1].replace(/,/g, ""));
      return Math.round(psi * PSI_TO_MPA * 10) / 10;
    }
    // Leading number in a US file = PSI
    const leadMatch = s.match(/^([\d,]+)/);
    if (leadMatch) {
      const psi = parseFloat(leadMatch[1].replace(/,/g, ""));
      return Math.round(psi * PSI_TO_MPA * 10) / 10;
    }
  } else {
    // Explicit MPa label
    const mpaMatch = s.match(/([\d.]+)\s*mpa/i);
    if (mpaMatch) return parseFloat(mpaMatch[1]);
    // Leading number in a SI file = MPa
    const leadMatch = s.match(/^([\d.]+)/);
    if (leadMatch) return parseFloat(leadMatch[1]);
  }

  return "";
}

/**
 * Extract aggregate size (min/max) from mix name, always returning values in mm.
 *
 * SI  : "10/14mm" → { min: 10,   max: 14  }
 *        "20mm"   → { min: "",    max: 20  }
 * US  : '3/4"'    → { min: "",    max: 19  }  (3/4 * 25.4, rounded)
 *        '1"'     → { min: "",    max: 25  }
 *        "3/4 in" → same
 */
function extractSlumpRange(
  name: any,
  unitSystem: UnitSystem = "SI"
): { min: number | string; max: number | string } {
  if (isEmptyValue(name)) return { min: "", max: "" };
  const s = String(name);

  if (unitSystem === "US") {
    // Fractional inch: "3/4"" or "3/4 in"
    const fracMatch = s.match(/(\d+)\/(\d+)\s*(?:"|in\b)/i);
    if (fracMatch) {
      const mm = Math.round((parseInt(fracMatch[1]) / parseInt(fracMatch[2])) * IN_TO_MM);
      return { min: "", max: mm };
    }
    // Decimal or whole inch: '1.5"' or '1 in'
    const decMatch = s.match(/(\d+\.?\d*)\s*(?:"|in\b)/i);
    if (decMatch) {
      const mm = Math.round(parseFloat(decMatch[1]) * IN_TO_MM);
      return { min: "", max: mm };
    }
  } else {
    // SI range: "10/14mm"
    const rangeMatch = s.match(/(\d+)\/(\d+)\s*mm/i);
    if (rangeMatch) {
      return { min: parseInt(rangeMatch[1]), max: parseInt(rangeMatch[2]) };
    }
    // SI single: "20mm"
    const singleMatch = s.match(/(\d+)\s*mm/i);
    if (singleMatch) {
      return { min: "", max: parseInt(singleMatch[1]) };
    }
  }

  return { min: "", max: "" };
}

/**
 * Extract slump value from a raw slump field, returning mm.
 * US values (inches) are converted to mm when unitSystem = "US".
 */
function extractSlump(slumpValue: any, unitSystem: UnitSystem = "SI"): number | string {
  if (isEmptyValue(slumpValue)) return "";
  const s = String(slumpValue);

  // Explicit mm label
  const mmMatch = s.match(/(\d+\.?\d*)\s*mm/i);
  if (mmMatch) return parseFloat(mmMatch[1]);

  // Explicit inch labels
  const inMatch = s.match(/(\d+\.?\d*)\s*(?:"|in\b)/i);
  if (inMatch) return Math.round(parseFloat(inMatch[1]) * IN_TO_MM);

  // Bare number — interpret by unit system
  const num = parseFloat(s);
  if (!isNaN(num)) {
    return unitSystem === "US" ? Math.round(num * IN_TO_MM) : num;
  }

  return "";
}

// ---------- COLUMN AUTO-DETECTION ----------

function findHeader(headers: string[], aliases: string[]): string | undefined {
  for (const alias of aliases) {
    const found = headers.find(
      (h) => h.trim().toLowerCase() === alias.toLowerCase()
    );
    if (found) return found;
  }
  for (const alias of aliases) {
    const found = headers.find((h) =>
      h.trim().toLowerCase().includes(alias.toLowerCase())
    );
    if (found) return found;
  }
  return undefined;
}

interface MixColumnMap {
  mixId: string | undefined;
  name: string | undefined;
  externalId: string | undefined;
  airFactor: string | undefined;
  slump: string | undefined;
  waterTarget: string | undefined;
}

function buildMixColumnMap(headers: string[]): MixColumnMap {
  return {
    mixId: findHeader(headers, ["MixId", "Mix Id", "MixID", "Mix_Id", "Id", "ID", "Code", "MixCode"]),
    name: findHeader(headers, ["Name", "MixName", "Mix Name", "Description", "Desc"]),
    externalId: findHeader(headers, ["ExternalId", "External Id", "ExternalID", "ExtId", "Ext Id", "ExternalCode"]),
    airFactor: findHeader(headers, ["AirFactor", "Air Factor", "AirContent", "Air Content", "Air%", "AirPct"]),
    slump: findHeader(headers, ["Slump", "SlumpTarget", "Slump Target", "DesignSlump", "Design Slump"]),
    waterTarget: findHeader(headers, [
      "WaterTarget",
      "Water Target",
      "WaterContent",
      "Water Content",
      "Water",
      "WaterQty",
      "Water Qty",
      "WaterAmount",
    ]),
  };
}

function detectConstituentColumns(
  headers: string[],
  prefix: string,
  count: number,
  matType: string
): Array<{ idCol: string | undefined; nameCol: string | undefined; targetCol: string | undefined }> {
  const result = [];
  for (let i = 1; i <= count; i++) {
    const idCol = findHeader(headers, [
      `${prefix}${i}Id`,
      `${prefix}${i}_Id`,
      `${prefix}${i}ID`,
      `${matType}${i}Id`,
      `${matType}${i}_Id`,
      `${matType}${i}ID`,
    ]);
    const nameCol = findHeader(headers, [
      `${prefix}${i}Name`,
      `${prefix}${i}_Name`,
      `${matType}${i}Name`,
      `${matType}${i}_Name`,
    ]);
    const targetCol = findHeader(headers, [
      `${prefix}${i}Target`,
      `${prefix}${i}_Target`,
      `${prefix}${i}Qty`,
      `${prefix}${i}Amount`,
      `${matType}${i}Target`,
      `${matType}${i}_Target`,
      `${matType}${i}Qty`,
    ]);
    result.push({ idCol, nameCol, targetCol });
  }
  return result;
}

// ---------- MATERIALS LOOKUP ----------

export function buildMaterialsLookup(materialsData: any[][]): Map<string, string> {
  const lookup = new Map<string, string>();
  if (!materialsData || materialsData.length < 2) return lookup;

  const headers: string[] = (materialsData[0] as any[]).map((h) =>
    h === null || h === undefined ? "" : String(h).trim()
  );

  const matTypeIdx = headers.findIndex((h) =>
    h.toLowerCase().includes("material type") && h.toLowerCase().includes("required")
  );
  const prodCodeIdx = headers.findIndex((h) =>
    h.toLowerCase().includes("production item code")
  );
  const tradeNameIdx = headers.findIndex((h) =>
    h.toLowerCase().includes("trade name")
  );

  if (prodCodeIdx === -1) {
    console.warn("Materials lookup: could not find 'Production Item Code' column.");
    return lookup;
  }

  const nameIdx = tradeNameIdx !== -1 ? tradeNameIdx : matTypeIdx;
  if (nameIdx === -1) {
    console.warn("Materials lookup: could not find name column.");
    return lookup;
  }

  for (let i = 1; i < materialsData.length; i++) {
    const row = materialsData[i];
    const name = safeStr(row[nameIdx]);
    const code = safeStr(row[prodCodeIdx]);
    if (name && code && !lookup.has(name.toLowerCase())) {
      lookup.set(name.toLowerCase(), code);
    }
  }

  return lookup;
}

// ---------- AI-ASSISTED CONVERSION (PLAN-BASED) ----------

/**
 * Convert multiple mix files using an AI-generated conversion plan.
 * This is the AI-assisted path — the plan encodes all user-confirmed decisions.
 */
export function convertMixesWithPlan(
  files: { data: any[][]; fileName: string }[],
  plan: MixConversionPlan
): MixConversionResult {
  const allDataRows: any[][] = [];
  const allIssues: ValidationIssue[] = [];
  let totalSkipped = 0;
  let totalInput = 0;
  let detectedUnitSystem: UnitSystem = "SI";

  for (const file of files) {
    const { dataRows, issues, skippedMixes, totalInputMixes, unitSystem } = convertMixFileWithPlan(
      file.data,
      plan,
      file.fileName
    );
    allDataRows.push(...dataRows);
    allIssues.push(
      ...issues.map((issue) => ({
        ...issue,
        message: `[${file.fileName}] ${issue.message}`,
      }))
    );
    totalSkipped += skippedMixes;
    totalInput += totalInputMixes;
    detectedUnitSystem = unitSystem;
  }

  return {
    rows: [MIX_TEMPLATE_COLUMNS, ...allDataRows],
    issues: allIssues,
    skippedMixes: totalSkipped,
    totalInputMixes: totalInput,
    totalOutputRows: allDataRows.length,
    unitSystem: detectedUnitSystem,
  };
}

// ---------- LONG-FORMAT CONVERSION (one row = one constituent) ----------
//
// Some source systems export mixes as a junction table: one row per
// (mix, plant, constituent) with the mix ID/name repeated across many rows,
// rather than the wide Agg1..Agg6/Cem1..Cem4/Adm1..Adm8 slot-column layout.
// In that shape there's nothing to "collect" per mix — each row already IS
// one output row, modulo plant explosion and unit/column normalization.
function convertLongFormatMixRows(
  rawHeaders: string[],
  data: Record<string, any>[],
  plan: MixConversionPlan,
  mixIdCol: string | undefined,
  nameCol: string | undefined,
  plantCol: string | undefined,
  waterTargetCol: string | undefined,
  unitSystem: UnitSystem,
  totalInputMixes: number
): { dataRows: any[][]; issues: ValidationIssue[]; skippedMixes: number; totalInputMixes: number; unitSystem: UnitSystem } {
  const issues: ValidationIssue[] = [];
  let skippedMixes = 0;

  // constituentNameColumn is detected/asked-about for context but intentionally
  // unused here — Constituent Item Description always stays empty, matching
  // the wide-format convention (the production item master supplies it).
  const constituentIdCol = plan.constituentIdColumn || undefined;
  const quantityCol = plan.quantityColumn || undefined;
  const unitCol = plan.unitColumn || undefined;

  if (!mixIdCol || !constituentIdCol || !quantityCol) {
    const missing = [
      !mixIdCol && "Mix ID",
      !constituentIdCol && "Constituent Item Code",
      !quantityCol && "Quantity",
    ].filter(Boolean).join(", ");
    issues.push({
      type: "error",
      message: `Long-format mix file is missing required column(s): ${missing}. File headers: ${rawHeaders.slice(0, 12).join(", ")}`,
    });
    return { dataRows: [], issues, skippedMixes: totalInputMixes, totalInputMixes, unitSystem };
  }

  const outputRows: any[][] = [];

  for (let idx = 0; idx < data.length; idx++) {
    const row = data[idx];
    const dataRowNum = idx + 2;

    const mixId = safeStr(row[mixIdCol]);
    const constituentId = safeStr(row[constituentIdCol]);
    if (!mixId || !constituentId) {
      skippedMixes++;
      continue;
    }

    if (plan.skipZeroWaterMixes && waterTargetCol && isZeroOrEmpty(row[waterTargetCol])) {
      skippedMixes++;
      continue;
    }

    const nameVal = nameCol ? safeStr(row[nameCol]) : mixId;
    const mixDisplayName = nameVal || mixId;

    const strengthMpa = plan.extractStrengthFromName ? extractStrength(mixDisplayName, unitSystem) : "";
    const slumpRange = plan.extractSlumpRangeFromName
      ? extractSlumpRange(mixDisplayName, unitSystem)
      : { min: "", max: "" };

    const qtyRaw = row[quantityCol];
    const qty = (qtyRaw === null || qtyRaw === undefined || qtyRaw === "") ? null : Number(qtyRaw);
    if (qty === null || isNaN(qty)) {
      issues.push({
        type: "error",
        message: `Row ${dataRowNum} (Mix "${mixId}", material "${constituentId}"): Quantity is missing or not numeric.`,
        row: dataRowNum,
        field: "Quantity",
      });
    } else if (qty < 0) {
      issues.push({
        type: "error",
        message: `Row ${dataRowNum} (Mix "${mixId}", material "${constituentId}"): Quantity is negative (${qty}).`,
        row: dataRowNum,
        field: "Quantity",
      });
    } else if (qty === 0 && !plan.includeZeroQuantityConstituents) {
      skippedMixes++;
      continue;
    }

    const unitName = normalizeUnitCode(unitCol ? row[unitCol] : "");

    // Plant explode: a row may list multiple plant codes in one cell
    // (e.g. Blalock-style "Location IDs" = "01, 05, 12")
    let plantCodes = plantCol ? splitPlantList(row[plantCol]) : [];
    if (plan.padPlantToTwoDigits) {
      plantCodes = plantCodes.map((p) => (p.length === 1 ? "0" + p : p));
    }
    if (plantCodes.length === 0) {
      issues.push({
        type: "warning",
        message: `Row ${dataRowNum} (Mix "${mixId}"): No plant/location assigned — row skipped.`,
        row: dataRowNum,
        field: "Plant Code",
      });
      skippedMixes++;
      continue;
    }

    for (const plantCode of plantCodes) {
      outputRows.push([
        plantCode,                // Plant Code
        mixDisplayName,           // Mix Name
        mixDisplayName,           // Description
        "",                       // Short Description
        "",                       // Item Category
        "",                       // Strength Age (Default 28)
        strengthMpa,              // Strength (MPA)
        "",                       // Design Air Content (%)
        "",                       // Min Air Content (%)
        "",                       // Max Air Content (%)
        "",                       // Design Slump (mm)
        slumpRange.min,           // Min Slump (mm)
        slumpRange.max,           // Max Slump (mm)
        "",                       // Max Batch Size
        "",                       // Max Water Liters
        "",                       // Max W/C+P
        "",                       // Max W/C
        "",                       // Mix Class Names, separate with semicolon
        "",                       // Mix Usage
        "",                       // Dispatch Slump Range
        "",                       // Dispatch
        constituentId,            // Constituent Item Code
        "",                       // Constituent Item Description (always left empty)
        qty === null ? qtyRaw : qty, // Quantity
        unitName,                 // Unit Name
      ]);
    }
  }

  return { dataRows: outputRows, issues, skippedMixes, totalInputMixes, unitSystem };
}

function convertMixFileWithPlan(
  mixData: any[][],
  plan: MixConversionPlan,
  _fileNameHint?: string
): { dataRows: any[][]; issues: ValidationIssue[]; skippedMixes: number; totalInputMixes: number; unitSystem: UnitSystem } {
  const issues: ValidationIssue[] = [];
  let skippedMixes = 0;

  if (!mixData || mixData.length < 2) {
    issues.push({ type: "error", message: "Mix file is empty or contains only a header row." });
    return { dataRows: [], issues, skippedMixes, totalInputMixes: 0, unitSystem: "SI" };
  }

  const rawHeaders: string[] = (mixData[0] as any[]).map((h) =>
    h === null || h === undefined ? "" : String(h).replace(/^\uFEFF/, "").trim()
  );

  const dataRows2D = mixData.slice(1);
  const totalInputMixes = dataRows2D.length;

  const data: Record<string, any>[] = dataRows2D.map((row) => {
    const obj: Record<string, any> = {};
    rawHeaders.forEach((header, idx) => {
      obj[header] = row[idx] !== undefined ? row[idx] : "";
    });
    return obj;
  });

  // Detect unit system (plan.unitSystem overrides auto-detection)
  const unitSystem: UnitSystem = plan.unitSystem || detectUnitSystem(rawHeaders, data);
  const validRecipeUnits = unitSystem === "US" ? VALID_RECIPE_UNITS_US : VALID_RECIPE_UNITS_SI;

  // Resolve column names: use plan if provided, fall back to auto-detect
  const colMap = buildMixColumnMap(rawHeaders);
  const plantCol = plan.plantColumn || undefined;
  const mixIdCol = plan.mixIdColumn || colMap.mixId;
  const nameCol = plan.mixNameColumn || colMap.name;
  const slumpCol = plan.slumpColumn || colMap.slump;
  const waterTargetCol = plan.waterTargetColumn || colMap.waterTarget;

  // Long-format sources (one row PER CONSTITUENT, mix info repeated across
  // rows — common in relational/junction-table exports) take a completely
  // different extraction path from the wide Agg1..Agg6/Cem1..Cem4/Adm1..Adm8
  // slot-column format assumed below.
  if (plan.dataShape === "long") {
    return convertLongFormatMixRows(
      rawHeaders, data, plan, mixIdCol, nameCol, plantCol, waterTargetCol, unitSystem, totalInputMixes
    );
  }

  if (!mixIdCol) {
    issues.push({
      type: "error",
      message: `Could not detect a Mix ID column. File headers: ${rawHeaders.slice(0, 10).join(", ")}`,
    });
    return { dataRows: [], issues, skippedMixes: totalInputMixes, totalInputMixes, unitSystem };
  }

  // Warn once if plan's default units are not in the valid list for the detected unit system
  const unitsToCheck: [string, string][] = [
    [plan.aggUnit || "kg", "Aggregate"],
    [plan.cemUnit || "kg", "Cement"],
    [plan.admUnit || "ml/ckg CM", "Admixture"],
  ];
  for (const [unit, matType] of unitsToCheck) {
    if (!validRecipeUnits.has(unit.toLowerCase())) {
      issues.push({
        type: "warning",
        message: `${matType} unit "${unit}" is not in the recognized list for ${unitSystem} mixes. Verify the unit is correct.`,
        field: "Unit Name",
      });
    }
  }

  // Detect constituent columns
  const aggCols = detectConstituentColumns(rawHeaders, "Agg", AGG_COUNT, "Aggregate");
  const cemCols = detectConstituentColumns(rawHeaders, "Cem", CEM_COUNT, "Cement");
  const admCols = detectConstituentColumns(rawHeaders, "Adm", ADM_COUNT, "Admixture");

  const shouldIncludeRow = (matId: string, matTarget: any): boolean => {
    if (isEmptyValue(matId)) return false;
    if (!plan.includeZeroQuantityConstituents && isZeroOrEmpty(matTarget)) return false;
    return true;
  };

  const outputRows: any[][] = [];

  for (let idx = 0; idx < data.length; idx++) {
    const row = data[idx];
    const dataRowNum = idx + 2;

    // Filter: skip zero-water mixes if configured
    const waterTarget = waterTargetCol ? row[waterTargetCol] : "";
    if (plan.skipZeroWaterMixes && waterTargetCol && isZeroOrEmpty(waterTarget)) {
      skippedMixes++;
      continue;
    }

    const mixId = safeStr(row[mixIdCol]);
    if (!mixId) {
      issues.push({
        type: "warning",
        message: `Row ${dataRowNum}: Mix ID is empty — row skipped.`,
        row: dataRowNum,
      });
      skippedMixes++;
      continue;
    }

    const nameVal = nameCol ? safeStr(row[nameCol]) : mixId;
    const slumpVal = slumpCol ? row[slumpCol] : "";

    // Plant: from column or static. A cell may list multiple plant codes
    // (e.g. "01, 02, 05") when the same mix applies to several plants —
    // split those out so the row is exploded into one output row per plant.
    let plantCodes: string[] = plantCol ? splitPlantList(row[plantCol]) : [];
    if (plan.padPlantToTwoDigits) {
      plantCodes = plantCodes.map((p) => (p.length === 1 ? "0" + p : p));
    }
    if (plantCodes.length === 0) plantCodes = [""];

    // Derived values (pass unitSystem so strength/slump conversions are unit-aware)
    const strengthMpa = plan.extractStrengthFromName ? extractStrength(nameVal, unitSystem) : "";
    void slumpVal;
    const slumpRange = plan.extractSlumpRangeFromName
      ? extractSlumpRange(nameVal, unitSystem)
      : { min: "", max: "" };

    // Validate strength > 0 if extracted
    if (typeof strengthMpa === "number" && strengthMpa <= 0) {
      issues.push({
        type: "warning",
        message: `Row ${dataRowNum} (Mix "${mixId}"): Extracted Strength ${strengthMpa} MPa must be greater than 0.`,
        row: dataRowNum,
        field: "Strength (MPA)",
      });
    }

    // Validate slump range — output is always mm; max 1270 mm (= 50 in × 25.4)
    const MAX_SLUMP_MM = 1270;
    const minSlumpMm = typeof slumpRange.min === "number" ? slumpRange.min : null;
    const maxSlumpMm = typeof slumpRange.max === "number" ? slumpRange.max : null;
    if (minSlumpMm !== null && (minSlumpMm < 0 || minSlumpMm > MAX_SLUMP_MM)) {
      issues.push({
        type: "warning",
        message: `Row ${dataRowNum} (Mix "${mixId}"): Min Slump ${minSlumpMm} mm is not in range 0–${MAX_SLUMP_MM} mm.`,
        row: dataRowNum,
        field: "Min Slump (mm)",
      });
    }
    if (maxSlumpMm !== null && (maxSlumpMm < 0 || maxSlumpMm > MAX_SLUMP_MM)) {
      issues.push({
        type: "warning",
        message: `Row ${dataRowNum} (Mix "${mixId}"): Max Slump ${maxSlumpMm} mm is not in range 0–${MAX_SLUMP_MM} mm.`,
        row: dataRowNum,
        field: "Max Slump (mm)",
      });
    }
    if (minSlumpMm !== null && maxSlumpMm !== null && minSlumpMm > maxSlumpMm) {
      issues.push({
        type: "warning",
        message: `Row ${dataRowNum} (Mix "${mixId}"): Min Slump (${minSlumpMm} mm) is greater than Max Slump (${maxSlumpMm} mm).`,
        row: dataRowNum,
        field: "Min Slump (mm)",
      });
    }

    // Collect constituents
    const constituents: [string, string, string, any, string][] = []; // [type, id, name, target, unit]

    for (const { idCol, nameCol: nCol, targetCol } of aggCols) {
      if (!idCol || !targetCol) continue;
      const matId = safeStr(row[idCol]);
      const matName = nCol ? safeStr(row[nCol]) : matId;
      const matTarget = row[targetCol];
      if (shouldIncludeRow(matId, matTarget)) {
        constituents.push(["Aggregate", matId, matName, matTarget, plan.aggUnit || "kg"]);
      }
    }

    for (const { idCol, nameCol: nCol, targetCol } of cemCols) {
      if (!idCol || !targetCol) continue;
      const matId = safeStr(row[idCol]);
      const matName = nCol ? safeStr(row[nCol]) : matId;
      const matTarget = row[targetCol];
      if (shouldIncludeRow(matId, matTarget)) {
        constituents.push(["Cement", matId, matName, matTarget, plan.cemUnit || "kg"]);
      }
    }

    for (const { idCol, nameCol: nCol, targetCol } of admCols) {
      if (!idCol || !targetCol) continue;
      const matId = safeStr(row[idCol]);
      const matName = nCol ? safeStr(row[nCol]) : matId;
      const matTarget = row[targetCol];
      if (shouldIncludeRow(matId, matTarget)) {
        constituents.push(["Admixture", matId, matName, matTarget, plan.admUnit || "ml/ckg CM"]);
      }
    }

    // Cross-constituent validation
    const hasCementitious = constituents.some(([type]) => type === "Cement");
    const hasAdmixture    = constituents.some(([type]) => type === "Admixture");
    if (hasAdmixture && !hasCementitious) {
      issues.push({
        type: "warning",
        message: `Row ${dataRowNum} (Mix "${mixId}"): Mix has Admixtures but no Cements or Minerals.`,
        row: dataRowNum,
      });
    }

    const seenMaterialIds = new Set<string>();
    for (const [, matId, , matTarget, unitName] of constituents) {
      const idKey = matId.toUpperCase();
      if (seenMaterialIds.has(idKey)) {
        issues.push({
          type: "error",
          message: `Row ${dataRowNum} (Mix "${mixId}"): Material "${matId}" appears more than once in the recipe.`,
          row: dataRowNum,
          field: "Constituent Item Code",
        });
      } else {
        seenMaterialIds.add(idKey);
      }

      const qty = (matTarget === null || matTarget === undefined || matTarget === "") ? null : Number(matTarget);
      if (qty === null || isNaN(qty)) {
        issues.push({
          type: "error",
          message: `Row ${dataRowNum} (Mix "${mixId}", material "${matId}"): Quantity is missing.`,
          row: dataRowNum,
          field: "Quantity",
        });
      } else if (qty < 0) {
        issues.push({
          type: "error",
          message: `Row ${dataRowNum} (Mix "${mixId}", material "${matId}"): Quantity is negative (${qty}).`,
          row: dataRowNum,
          field: "Quantity",
        });
      }

      if (!validRecipeUnits.has(unitName.toLowerCase())) {
        issues.push({
          type: "warning",
          message: `Row ${dataRowNum} (Mix "${mixId}"): Unit "${unitName}" is not in the recognized list for ${unitSystem} mixes.`,
          row: dataRowNum,
          field: "Unit Name",
        });
      }
    }

    if (constituents.length === 0) {
      issues.push({
        type: "warning",
        message: `Row ${dataRowNum} (Mix "${mixId}"): No constituent materials found.`,
        row: dataRowNum,
      });
    }

    // Mix Name = descriptive name (from Name/mixNameColumn), not the short ID code
    const mixDisplayName = nameVal || mixId;

    for (const plantCode of plantCodes) {
      for (const [, matId, , matTarget, unitName] of constituents) {
        outputRows.push([
          plantCode,          // Plant Code
          mixDisplayName,     // Mix Name
          mixDisplayName,     // Description
          "",                 // Short Description
          "",                 // Item Category
          "",                 // Strength Age (Default 28)
          strengthMpa,        // Strength (MPA)
          "",                 // Design Air Content (%)
          "",                 // Min Air Content (%)
          "",                 // Max Air Content (%)
          "",                 // Design Slump (mm)
          slumpRange.min,     // Min Slump (mm)
          slumpRange.max,     // Max Slump (mm)
          "",                 // Max Batch Size
          "",                 // Max Water Liters
          "",                 // Max W/C+P
          "",                 // Max W/C
          "",                 // Mix Class Names, separate with semicolon
          "",                 // Mix Usage
          "",                 // Dispatch Slump Range
          "",                 // Dispatch
          matId,              // Constituent Item Code
          "",                 // Constituent Item Description
          matTarget,          // Quantity
          unitName,           // Unit Name
        ]);
      }
    }
  }

  return { dataRows: outputRows, issues, skippedMixes, totalInputMixes, unitSystem };
}

// ---------- LEGACY CONVERSION (non-AI path, kept for materials tab compatibility) ----------

export function convertMixFile(
  mixData: any[][],
  materialsLookup: Map<string, string>,
  _fileNameHint?: string
): { dataRows: any[][]; issues: ValidationIssue[]; skippedMixes: number; totalInputMixes: number } {
  const issues: ValidationIssue[] = [];
  let skippedMixes = 0;

  if (!mixData || mixData.length < 2) {
    issues.push({ type: "error", message: "Mix file is empty or contains only a header row." });
    return { dataRows: [], issues, skippedMixes, totalInputMixes: 0 };
  }

  const rawHeaders: string[] = (mixData[0] as any[]).map((h) =>
    h === null || h === undefined ? "" : String(h).replace(/^\uFEFF/, "").trim()
  );

  const dataRows2D = mixData.slice(1);
  const totalInputMixes = dataRows2D.length;

  const data: Record<string, any>[] = dataRows2D.map((row) => {
    const obj: Record<string, any> = {};
    rawHeaders.forEach((header, idx) => {
      obj[header] = row[idx] !== undefined ? row[idx] : "";
    });
    return obj;
  });

  const colMap = buildMixColumnMap(rawHeaders);

  if (!colMap.mixId) {
    issues.push({
      type: "error",
      message: `Could not detect a Mix ID column. File headers: ${rawHeaders.slice(0, 10).join(", ")}`,
    });
    return { dataRows: [], issues, skippedMixes: totalInputMixes, totalInputMixes };
  }

  if (!colMap.waterTarget) {
    issues.push({
      type: "warning",
      message: `Could not detect a Water Target column. All mixes will be included.`,
    });
  }

  const aggCols = detectConstituentColumns(rawHeaders, "Agg", AGG_COUNT, "Aggregate");
  const cemCols = detectConstituentColumns(rawHeaders, "Cem", CEM_COUNT, "Cement");
  const admCols = detectConstituentColumns(rawHeaders, "Adm", ADM_COUNT, "Admixture");

  const validMixes = data.filter((row) => {
    if (!colMap.waterTarget) return true;
    const waterTarget = row[colMap.waterTarget!];
    if (isZeroOrEmpty(waterTarget)) {
      skippedMixes++;
      return false;
    }
    return true;
  });

  if (validMixes.length === 0) {
    issues.push({ type: "error", message: "No valid mixes found with WaterTarget > 0." });
    return { dataRows: [], issues, skippedMixes, totalInputMixes };
  }

  const outputRows: any[][] = [];

  for (let idx = 0; idx < validMixes.length; idx++) {
    const row = validMixes[idx];
    const dataRowNum = idx + 2;

    const mixId = safeStr(row[colMap.mixId!]);
    const nameVal = colMap.name ? safeStr(row[colMap.name]) : mixId;
    const externalId = colMap.externalId ? safeStr(row[colMap.externalId]) : "";
    const airFactor = colMap.airFactor ? row[colMap.airFactor] : "";
    const slumpVal = colMap.slump ? row[colMap.slump] : "";
    const waterTarget = colMap.waterTarget ? row[colMap.waterTarget!] : "";

    if (!mixId) {
      issues.push({ type: "warning", message: `Row ${dataRowNum}: Mix ID is empty — row skipped.`, row: dataRowNum });
      skippedMixes++;
      continue;
    }

    const strengthMpa = extractStrength(nameVal);
    const slumpMm = extractSlump(slumpVal);
    const slumpRange = extractSlumpRange(nameVal);

    const constituents: [string, string, string, any][] = [];

    for (const { idCol, nameCol, targetCol } of aggCols) {
      if (!idCol || !targetCol) continue;
      const matId = safeStr(row[idCol]);
      const matName = nameCol ? safeStr(row[nameCol]) : matId;
      const matTarget = row[targetCol];
      if (!isEmptyValue(matId)) {
        constituents.push(["Aggregate", matId, matName, matTarget]);
      }
    }
    for (const { idCol, nameCol, targetCol } of cemCols) {
      if (!idCol || !targetCol) continue;
      const matId = safeStr(row[idCol]);
      const matName = nameCol ? safeStr(row[nameCol]) : matId;
      const matTarget = row[targetCol];
      if (!isEmptyValue(matId)) {
        constituents.push(["Cement", matId, matName, matTarget]);
      }
    }
    for (const { idCol, nameCol, targetCol } of admCols) {
      if (!idCol || !targetCol) continue;
      const matId = safeStr(row[idCol]);
      const matName = nameCol ? safeStr(row[nameCol]) : matId;
      const matTarget = row[targetCol];
      if (!isEmptyValue(matId)) {
        constituents.push(["Admixture", matId, matName, matTarget]);
      }
    }

    // Use plant from Plant column if present, else PLANTS list
    const plantColName = findHeader(rawHeaders, ["Plant", "PlantId", "Plant Id", "PlantCode", "Plant Code"]);
    const plantsToUse = plantColName && !isEmptyValue(row[plantColName])
      ? [safeStr(row[plantColName])]
      : PLANTS;

    for (const plant of plantsToUse) {
      for (const [matType, matId, matName, matTarget] of constituents) {
        const unitName = matType === "Admixture" ? "ml/ckg CM" : "kg";

        let productionCode = matId;
        if (matType !== "Water" && materialsLookup.has(matName.toLowerCase())) {
          productionCode = materialsLookup.get(matName.toLowerCase())!;
        }

        outputRows.push([
          plant,
          mixId,
          nameVal,
          mixId,
          externalId,
          28,
          strengthMpa,
          isEmptyValue(airFactor) ? "" : airFactor,
          "",
          "",
          slumpMm,
          slumpRange.min,
          slumpRange.max,
          "",
          isEmptyValue(waterTarget) ? "" : waterTarget,
          "",
          "",
          "",
          "",
          "",
          "",
          productionCode,
          matName,
          matTarget,
          unitName,
        ]);
      }
    }
  }

  return { dataRows: outputRows, issues, skippedMixes, totalInputMixes };
}

export function convertAndMergeMixes(
  files: { data: any[][]; fileName: string }[],
  materialsLookup: Map<string, string>
): MixConversionResult {
  const allDataRows: any[][] = [];
  const allIssues: ValidationIssue[] = [];
  let totalSkipped = 0;
  let totalInput = 0;

  for (const file of files) {
    const { dataRows, issues, skippedMixes, totalInputMixes } = convertMixFile(
      file.data,
      materialsLookup,
      file.fileName
    );
    allDataRows.push(...dataRows);
    allIssues.push(
      ...issues.map((issue) => ({
        ...issue,
        message: `[${file.fileName}] ${issue.message}`,
      }))
    );
    totalSkipped += skippedMixes;
    totalInput += totalInputMixes;
  }

  return {
    rows: [MIX_TEMPLATE_COLUMNS, ...allDataRows],
    issues: allIssues,
    skippedMixes: totalSkipped,
    totalInputMixes: totalInput,
    totalOutputRows: allDataRows.length,
    unitSystem: "SI",
  };
}
