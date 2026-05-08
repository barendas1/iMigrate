import * as XLSX from "xlsx";

// =============================================================================
// MATERIAL CONVERTER — universal.ts
//
// PURPOSE:
//   Accepts raw Excel exports from any source system (any column names, any
//   column order, any number of extra columns).  Detects which input column
//   maps to each required Quadrel field using a broad alias dictionary, then
//   cleans / corrects / validates the data and writes a single standardised
//   Quadrel Material Import output file.
//
// OUTPUT FORMAT (always fixed — 20 columns in this exact order):
//   0  Plant Code (Required)
//   1  Trade Name (Required)
//   2  Material Date (mm/dd/yyyy)
//   3  Family Material Type (Required)
//   4  Material Type (Required)
//   5  Specific Gravity (Required)
//   6  Is Liquid Admixture (Yes/No)
//   7  Water Contribution (%)
//   8  Cost
//   9  Cost Units
//   10 Manufacturer
//   11 Manufacturer Source
//   12 Batching Order Number
//   13 Production Item Code
//   14 Production Item Description
//   15 Production Item Short Description
//   16 Production Item Category
//   17 Production Item Category Description
//   18 Production Item Category Short Description
//   19 Batch Panel Code
// =============================================================================

// ---------- VALIDATION & TRANSFORMATION RULES ----------
//
// ============================================================
// MATERIAL VALIDATION CHECKS (applied during conversion)
// ============================================================
//
// ROW-LEVEL CHECKS (applied per input row, per file):
//
//   1. EMPTY ROW SKIP
//      - If both Trade Name and Production Item Code resolve to empty,
//        the row is silently skipped (treated as a blank row).
//
//   2. TRADE NAME REQUIRED
//      - Trade Name must be present and non-empty after trimming.
//      - If missing, the row is skipped and an ERROR is reported.
//
//   3. SPECIFIC GRAVITY REQUIRED & NON-ZERO
//      - After applying the default-to-1 rule (Transformation T3 below),
//        Specific Gravity must be numeric and not equal to 0.
//      - If still missing or zero, the row is skipped and an ERROR is reported.
//
// TRANSFORMATION RULES (applied before validation):
//
//   T1. DATE FORMAT
//       - JS Date objects and Excel serial numbers are formatted as
//         "MM/DD/YYYY" strings.  Existing strings are passed through as-is.
//
//   T2. FAMILY TYPE AUTO-CORRECTION (driven by Material Type value)
//       - "Fly Ash" or "Silica Fume"  → Family Type = "Mineral"
//       - "Color"                      → Family Type = "Admixture & Fiber"
//                                        Production Item Category = "Admixture & Fiber"
//       A warning is emitted whenever a correction is made.
//
//   T3. SPECIFIC GRAVITY DEFAULT
//       - If SG is missing/null AND Family Type (after T2) is
//         "Admixture & Fiber", SG defaults to 1.
//
//   T4. COST UNITS DEFAULT
//       - If Cost Units is missing/null/empty, defaults to "$/lb".
//
//   T5. PRODUCTION ITEM CODE CLEANUP
//       - All whitespace is stripped so the code is one continuous string
//         (e.g. "NNQ 20" → "NNQ20").
//
// CROSS-FILE / POST-MERGE CHECKS (applied after all files are merged):
//
//   4. DUPLICATE TRADE NAME PER PLANT
//      - No two rows may share the same Trade Name within the same Plant Code.
//      - Duplicates (after the first) are removed; an ERROR is reported.
//
//   5. DUPLICATE PRODUCTION ITEM CODE PER PLANT
//      - No two rows may share the same Production Item Code within the same
//        Plant Code (only enforced when the item code is non-empty).
//      - Duplicates (after the first) are removed; an ERROR is reported.
//
// REPORTING:
//   - All issues surface in the UI ValidationPanel after conversion.
//   - Issues are tagged "error" (row skipped/removed) or "warning"
//     (row kept but something was auto-corrected).
//   - Each message is prefixed with the source filename when multiple files
//     are uploaded.
// ============================================================

export interface ValidationIssue {
  type: "error" | "warning";
  message: string;
  row?: number;   // 1-based data row index (relative to header)
  field?: string; // output column name where the issue was found
}

export interface MaterialConversionResult {
  rows: any[][];
  issues: ValidationIssue[];
  totalInputRows: number;
  totalOutputRows: number;
  skippedRows: number;
}

// ---------------------------------------------------------------------------
// Fixed output headers (always written in this order)
// ---------------------------------------------------------------------------
const OUTPUT_HEADERS = [
  "Plant Code (Required)",
  "Trade Name (Required)",
  "Material Date (mm/dd/yyyy)",
  "Family Material Type (Required)",
  "Material Type (Required)",
  "Specific Gravity (Required)",
  "Is Liquid Admixture (Yes/No)",
  "Water Contribution (%)",
  "Cost",
  "Cost Units",
  "Manufacturer",
  "Manufacturer Source",
  "Batching Order Number",
  "Production Item Code",
  "Production Item Description",
  "Production Item Short Description",
  "Production Item Category",
  "Production Item Category Description",
  "Production Item Category Short Description",
  "Batch Panel Code",
];

// Enum-style indices into OUTPUT_HEADERS
const COL = {
  PLANT:            0,
  TRADE_NAME:       1,
  DATE:             2,
  FAMILY_TYPE:      3,
  MATERIAL_TYPE:    4,
  SPECIFIC_GRAVITY: 5,
  IS_LIQUID:        6,
  WATER_CONTRIB:    7,
  COST:             8,
  COST_UNITS:       9,
  MANUFACTURER:     10,
  MFR_SOURCE:       11,
  BATCH_ORDER:      12,
  ITEM_CODE:        13,
  ITEM_DESC:        14,
  ITEM_SHORT_DESC:  15,
  ITEM_CATEGORY:    16,
  ITEM_CAT_DESC:    17,
  ITEM_CAT_SHORT:   18,
  BATCH_PANEL:      19,
} as const;

// ---------------------------------------------------------------------------
// ALIAS DICTIONARY
// Maps each output field key to a list of possible input header strings
// (all lowercased, trimmed — matching is case-insensitive).
// Add new aliases here as new source formats are encountered.
// ---------------------------------------------------------------------------
const ALIASES: Record<keyof typeof COL, string[]> = {
  PLANT: [
    "plant code (required)", "plant code", "plant", "plant no", "plant number",
    "plant id", "plant #", "location", "site", "site code", "site id",
    "batch plant", "batch plant code", "facility", "facility code",
    "plantcode", "plantid", "plantno",
  ],
  TRADE_NAME: [
    "trade name (required)", "trade name", "tradename", "material name",
    "material", "mat name", "product name", "product", "description",
    "material description", "name", "item name", "item description",
    "mat description", "material trade name",
    // Additional informal names
    "mat. name", "matname", "prod name", "prod. name", "mix name",
    "component name", "component", "chem name", "chemical name",
  ],
  DATE: [
    "material date (mm/dd/yyyy)", "material date", "date", "effective date",
    "start date", "mat date", "date added", "created date", "entry date",
  ],
  FAMILY_TYPE: [
    "family material type (required)", "family material type", "family type",
    "material family", "family", "mat family", "material group",
    "material category group", "group",
  ],
  MATERIAL_TYPE: [
    "material type (required)", "material type", "mat type", "type",
    "material class", "class", "category", "mat category",
    "material sub type", "subtype", "sub type",
  ],
  SPECIFIC_GRAVITY: [
    "specific gravity (required)", "specific gravity", "sg", "sp gr",
    "sp. gr.", "sp. gravity", "specific gr", "relative density",
    "density", "bulk density", "specific weight",
    // Short / informal names often found in customer sheets
    "gravity", "spec grav", "spec. grav", "spec. grav.", "sp grav",
    "sp. grav", "sp. grav.", "s.g.", "s.g", "spg",
    // Raw dispatch export names
    "specificgravity", "spgravity", "sp_gravity", "spec_gravity",
    "relativedensity", "rd",
  ],
  IS_LIQUID: [
    "is liquid admixture (yes/no)", "is liquid admixture", "is liquid",
    "liquid admixture", "liquid", "admixture type", "liquid flag",
    "isliquid", "isliquidadmixture", "liquid_flag",
  ],
  WATER_CONTRIB: [
    "water contribution (%)", "water contribution", "water contrib",
    "water %", "water percent", "water content", "free water",
    "water contribution percent",
    // Raw dispatch export names
    "moisture", "moisture content", "moisture%", "freemoisture",
    "absorption", "freewater",
  ],
  COST: [
    "cost", "unit cost", "price", "unit price", "material cost",
    "mat cost", "rate", "cost per unit",
  ],
  COST_UNITS: [
    "cost units", "cost unit", "unit", "units", "price unit",
    "price units", "uom", "unit of measure", "pricing unit",
  ],
  MANUFACTURER: [
    "manufacturer", "mfr", "vendor", "supplier", "brand",
    "make", "producer", "manufacturer name",
  ],
  MFR_SOURCE: [
    "manufacturer source", "mfr source", "source", "supplier source",
    "vendor source", "supply source", "source name", "origin",
    "manufacturer location", "mfr location",
  ],
  BATCH_ORDER: [
    "batching order number", "batching order", "batch order", "batch order number",
    "batch sequence", "batching sequence", "order", "order number",
    "batch number", "batching number",
  ],
  ITEM_CODE: [
    "production item code", "item code", "prod item code", "prod code",
    "product code", "material code", "mat code", "code", "sku",
    "item number", "item no", "item #", "material number", "mat number",
    "material id", "mat id", "part number", "part no",
    // Raw dispatch export IDs
    "cementid", "aggregateid", "admixtureid", "extraid", "externalid",
    "materialid", "mat_id", "prodid", "productid",
  ],
  ITEM_DESC: [
    "production item description", "item description", "prod item description",
    "item desc", "prod description", "product description", "material description",
    "mat desc", "full description", "long description",
  ],
  ITEM_SHORT_DESC: [
    "production item short description", "item short description",
    "short description", "short desc", "item short desc",
    "prod short description", "abbreviated description", "abbrev desc",
  ],
  ITEM_CATEGORY: [
    "production item category", "item category", "prod item category",
    "category", "material category", "mat category", "product category",
    "prod category",
  ],
  ITEM_CAT_DESC: [
    "production item category description", "item category description",
    "category description", "cat description", "cat desc",
    "item cat description", "prod category description",
  ],
  ITEM_CAT_SHORT: [
    "production item category short description",
    "item category short description", "category short description",
    "cat short description", "cat short desc", "item cat short",
    "prod category short",
  ],
  BATCH_PANEL: [
    "batch panel code", "batch panel", "panel code", "panel",
    "batcher code", "batcher", "batch code",
  ],
};

// ---------------------------------------------------------------------------
// Family Type correction map: MaterialType (lowercase) → correct FamilyType
// ---------------------------------------------------------------------------
const MATERIAL_TYPE_TO_FAMILY: Record<string, string> = {
  "fly ash":    "Mineral",
  "silica fume": "Mineral",
  "color":      "Admixture & Fiber",
  "slag":       "Mineral",
  "water":      "Water",
};

// ---------------------------------------------------------------------------
// Valid Family Material Types (maps to MaterialTypeID 1–5 in the database)
// ---------------------------------------------------------------------------
const VALID_FAMILY_TYPES = new Set([
  "cement", "mineral", "aggregate", "admixture & fiber", "water",
]);

// ---------------------------------------------------------------------------
// Valid Cost Units accepted by the database
// ---------------------------------------------------------------------------
const VALID_COST_UNITS = new Set([
  "$/lb", "$/liter", "$/gal", "$/ton", "$/kg", "$/metric ton", "$/mton",
  "$/tn", "$/cy", "$//yd^3", "$/gl", "$/oz",
  "pounds", "fluid oz", "gallons", "ounces", "m3", "cy", "ga", "gl", "oz",
  "lb", "ton", "tons", "ml-liter", "ml", "liter", "liters", "litres",
  "lt", "l", "ll", "kg", "tm", "mt",
]);

// ---------------------------------------------------------------------------
// File-type inference: detect what kind of raw export a file is by inspecting
// its header columns, so we can supply smart defaults when Family Type,
// Material Type, or Is Liquid columns are absent.
// Returns one of: "cement" | "aggregate" | "admixture" | "extra" | "unknown"
// ---------------------------------------------------------------------------
type FileType = "cement" | "aggregate" | "admixture" | "extra" | "unknown";

function inferFileType(headerRow: any[]): FileType {
  const joined = headerRow.map((v) => String(v ?? "").trim().toLowerCase()).join("|");
  if (joined.includes("cementid"))    return "cement";
  if (joined.includes("aggregateid")) return "aggregate";
  if (joined.includes("admixtureid")) return "admixture";
  if (joined.includes("extraid"))     return "extra";
  return "unknown";
}

// ---------------------------------------------------------------------------
// Maps any raw family-type string (however abbreviated) to a valid DB value.
// Returns null if no confident match can be made.
// ---------------------------------------------------------------------------
function normalizeFamilyType(raw: string): string | null {
  const v = raw.trim().toLowerCase();
  if (!v) return null;
  if (v === "cement")                                        return "Cement";
  if (v === "mineral")                                       return "Mineral";
  if (v === "aggregate")                                     return "Aggregate";
  if (v === "admixture & fiber" || v === "admixture and fiber") return "Admixture & Fiber";
  if (v === "water")                                         return "Water";
  // Aggregate signals
  if (v.includes("agg")       || v.includes("gravel")   || v.includes("stone")  ||
      v.includes("sand")      || v.includes("rock")      || v.includes("granite") ||
      v.includes("limestone") || v.includes("limerock")  || v.includes("coarse") ||
      v.includes("pea")       || v.includes("pebble")    || v.includes("screenings") ||
      v.includes("chip"))
    return "Aggregate";
  // Mineral / SCM signals (fly ash, slag, silica fume, GGBF, pozzolan)
  if (v.includes("fly ash") || v.includes("flyash") || v.includes("slag") ||
      v.includes("ggbf")    || v.includes("silica")  || v.includes("pozzolan") ||
      v.includes("mineral") || v.includes("scm"))
    return "Mineral";
  // Cement signals
  if (v.includes("cement") || v === "cem" || v.startsWith("cem "))
    return "Cement";
  // Admixture & Fiber signals
  if (v.includes("admix")       || v.includes("additive")     || v.includes("chemical") ||
      v.includes("fiber")       || v.includes("fibre")        || v.includes("retard")   ||
      v.includes("accelerat")   || v.includes("plasticizer")  || v.includes("superplast") ||
      v.includes("shrink")      || v.includes("pigment")      || v.includes("color")    ||
      v.includes("colour")      || v.includes("air entraining") || v.includes("water reduc") ||
      v.includes("set time")    || v.includes("viscosity"))
    return "Admixture & Fiber";
  // Water signals
  if (v.includes("water") || v === "h2o")
    return "Water";
  return null;
}

// ---------------------------------------------------------------------------
// Complete list of valid material type strings (exact database names).
// Grouped by family type for documentation; order doesn't affect matching.
// ---------------------------------------------------------------------------
const VALID_MATERIAL_TYPES: readonly string[] = [
  // ── Cement ────────────────────────────────────────────────────────────────
  "Cement","Type I","Type II","Type III","Type I-II","Type II-V","Type IV","Type V",
  "Type GU","Type IL","Type IP","Type IP (MS)","Type IS","Type P","Type I(PM)","Type I(SM)",
  "Expansive Type K","Expansive Type M","Expansive Type S","SSPWC Expansive Cement",
  "Rapid Set","CSA Type GU","CSA Type GUb-F/SF","CSA Type GUb-S","CSA Type Gub-SF",
  "CSA Type GUL","CSA Type GULb","CSA Type HE","CSA Type HS","CSA Type LH",
  "CSA Type MH","CSA Type MS","CSA Special Cement","NZS GB","NZS GP","NZS HE",
  "Cement Blends","Fixed Cement Blends","Variable Cement Blends",
  "BS EN 197-1 (Cem I)","32.5 N","32.5 R","42.5 N","42.5 R","52.5 N","52.5 R",
  // ── Mineral ───────────────────────────────────────────────────────────────
  "CSA ANHYDRITE","CSA Type BMb","Integral Concrete Hardener",
  "Fly Ash (General)","Fly Ash","Fly Ash C","Fly Ash F","Natural Pozz N",
  "CSA Fly Ash","CSA Type CH","CSA Type CI","CSA Type F","CSA Type N","Superfine Fly Ash",
  "Slag (General)","BS 6699 GGBS","CSA Type S","Slag","Superfine Slag",
  "Metakaolin (General)","CSA Type N - Meta-Kaolin","Metakaolin",
  "Hydrated Lime","Type N","Type NA","Type S","Type SA",
  "Silica Fume (General)","CSA Silica Fume","CSA Type SF","CSA Type SFI",
  "Silica Fume","Silica Fume Dry","Silica Fume Slurry",
  // ── Aggregate (Coarse) ────────────────────────────────────────────────────
  "Coarse Aggregate (General)","Coarse Aggregate",
  "0.185\"","ACI No. 4 to No. 8","Cemex 3/16\" to No. 8","1/4\"",
  "BS EN 2/6.3 mm","BS Single-Sized 5 mm","CSA.GII 5-2.5","OPS 6.7 mm Structural",
  "3/8 \"","# 8","# 89","#89NH","Aurora 3/8\" Granular Bedding",
  "BS EN 4/10 mm","BS Single-Sized 10 mm","CSA.GI 10-2.5 Granite",
  "CSA.GI 10-2.5 Gravel","CSA.GI 10-2.5 Limestone","CSA.GII 10-5",
  "ISSA Type II Slurry Seal","NZS CA 10","NZS Company CA 10",
  "ODOT 3/8\" to No. 4","OPS 9.5 mm Structural","SSPWC No. 4",
  "1/2 \"","# 7","# 78","1/2\" to No. 4","CDOT Class 6","SCDOT # 789",
  "17/32\"","BS EN 2/14 mm","BS EN 6.3/14 mm","BS Graded 14 mm to 5 mm",
  "BS Single-Sized 14 mm","CSA.GI 14-5 Granite","CSA.GI 14-5 Gravel",
  "CSA.GI 14-5 Limestone","CSA.GII 14-10","NZS CA 13","NZS Company CA 13",
  "OPS 13.2 mm Pavement","OPS 13.2 mm Structural","5/8\"","NZS CA 16",
  "OPS 16 mm Structural","3/4 \"","# 6","# 67",
  "BS EN 4/20 mm","BS EN 10/20 mm","BS Graded 20 mm to 5 mm","BS Single-Sized 20 mm",
  "CDOT Class 7","CSA.GI 20-5 Granite","CSA.GI 20-5 Gravel","CSA.GI 20-5 Limestone",
  "CSA.GII 20-10 Granite","CSA.GII 20-10 Limestone","NZS CA 19","NZS Company CA 19",
  "ODOT 3/4\" Base","ODOT 3/4\" to 3/8\"","OPS 19 mm Pavement","OPS 19 mm Structural",
  "1 \"","# 5","# 56","# 57","Aurora Type IIA Base","CDOT Class 5",
  "CDOT Class B Filter","CSA.GI 28-5","CSA.GII 28-14","NZS CA 26","SSPWC No. 3",
  "1 1/2 \"","# 4","# 467","BS EN 4/40 mm","BS EN 20/40 mm",
  "BS Graded 40 mm to 5 mm","BS Single-Sized 40 mm","CSA.GI 40-5",
  "CSA.GII 40-20 Granite","CSA.GII 40-20 Limestone","NZS CA 38",
  "OPS 37.5 mm Pavement","OPS 37.5 - 19 mm Pavement","SSPWC No. 2",
  "2 \"","# 3","# 357","CDOT Class 1","CDOT Class 1 Structural Fill",
  "CDOT Class 4","CDOT Str. Backfill Class 1","CSA.GII 56-28",
  "2 1/2 \"","# 2","CSA.GII 80-40","NZS CA 75",
  "3 1/2 \"","# 1","CDOT Class 2","CDOT Class A Filter","CDOT Type II Bedding","CDOT Class 3",
  "Rip Rap","4\" Rip Rap","Rap 4","6\" Rip Rap","Rap 6","VL Rip Rap",
  "8\" Rip Rap","Rap 8","9\" Rip Rap","L Rip Rap","10\" Rip Rap","Rap 10",
  "12\" Rip Rap","M Rip Rap","Rap 12","18\" Rip Rap","H Rip Rap","24\" Rip Rap","VH Rip Rap",
  "Coarse Lightweight","3/8 in to No 8 Lwt","1/2\" Lightweight",
  "1/2 in to No 4 Lwt","3/4 in to No 4 Lwt","1 in to No 4 Lwt",
  "SSPWC No. 2 Lightweight","Ballast","CR 3-4","MBTA4","MBTA4A",
  "Coarse High Density","Structural Fill","Stone Blends","Intermediate Aggregate",
  // ── Aggregate (Fine) ──────────────────────────────────────────────────────
  "Fine Aggregate (General)","BS EN Fine Aggregate",
  "BS EN 0/4 (CP) mm","BS EN 0/4 (MP) mm","BS EN 0/2 (MP) mm",
  "BS EN 0/2 (FP) mm","BS EN 0/1 (FP) mm","BS Fine Aggregate",
  "BS Sand C","BS Sand M","BS Sand F","CSA Fine Aggregate","CSA FA1","CSA FA2",
  "CSA Fillers","Fine Aggregate","Blended Sand","Commercial Sand",
  "Manufactured Sand","Natural Sand","20-30 (Ottawa LeSeuer) Sand",
  "Graded (Ottawa) Sand","PCC Sand","Fines","304.1 Sand","Dust",
  "Screenings","Silt","Fine Lightweight","No 4 to 0 Lwt",
  "Masonry Sand","Manufactured Masonry Sand","Natural Masonry Sand",
  "NZS Fine Aggregate","NZS Company PAP6","# 9","AASHTO M6","CDOT Sand",
  "Fine High Density","Grit","OPS Manufactured Sand","OPS Natural Sand",
  "SSPWC Sand","WSDOT Sand","Sand Blends",
  // ── Aggregate (Combined / Gravel / Special) ───────────────────────────────
  "Combined Fine Coarse (General)","Combined Fine Crse Lwt",
  "3/8 in to 0 Lwt","1/2 in to 0 Lwt","Dense Graded",
  "1 1/2\" Dense MHD","3/4\" Dense MHD","Gravel",
  "304.2","304.3","304.33","304.4","304.5","304.6","P-154","P-209",
  "Processed Gravel MHD","Septic Gravel MHD","Type A MHD","Type B MHD","Type C MHD",
  "Recycled Aggs","Crushed Bank","Crushed Concrete",
  "Reclaimed Base NHDOT","Reclaimed Borrow (MHD)","T-Base",
  "Special Blends","Lightweight Aggregate","Combined Aggregate Blends",
  // ── Water ─────────────────────────────────────────────────────────────────
  "City","Cold Water","Drinking","Flaked Ice","Hot Water",
  "Potable","Questionable","Recycled","Well Water",
  // ── Admixture & Fiber ─────────────────────────────────────────────────────
  "Air Detrainer","Air Entrainer","Anti-Washout","ASR Mitigation","CarbonCure",
  "Color","Corrosion Inhibitor","Foaming Agent","Grout Fluidifier",
  "Hydration Stabilizer","Latex Emulsion","Mid Range Water Reducer",
  "Multi-Range Water Reducer","Pump Aid - Integral","Shrinkage Reducer",
  "Shrinkage Reducer And Compensator","Stabilizer","Strength Enhancing Admixture",
  "Type A & D Water Reducer","Type A Water Reducer","Type B Retarder",
  "Type C Accelerator","Calcium Chloride Accelerator","Non-Chloride Accelerator",
  "Type D Water Reducer & Retarder","Type E Water Reducer & Accelerator",
  "Type F High Range Water Reducer","Type G High Range Water Reducer & Retarder",
  "Type S Specific Performance","Viscosity Modifier","Viscosity Modifier/HRWR",
  "Water Proofer","Water Proofer - Crystalizing","Water Proofer - Integral",
  "Water Repellent","Fibers","Blended Fibers","Glass Fibers",
  "Natural Fibers","Steel Fibers","Structural Fibers","Synthetic Fibers",
] as const;

// O(1) case-insensitive exact lookup: lowercase → canonical name
const MATERIAL_TYPE_EXACT = new Map<string, string>(
  (VALID_MATERIAL_TYPES as readonly string[]).map((t) => [t.toLowerCase(), t])
);

// ---------------------------------------------------------------------------
// Maps any raw material-type string to a valid DB name.
// Uses familyType context to resolve ambiguous matches.
// Returns null when no confident match exists.
// ---------------------------------------------------------------------------
function normalizeMaterialType(raw: string, familyType?: string): string | null {
  const v = raw.trim();
  if (!v) return null;

  // Step 1: exact match (case-insensitive)
  const exact = MATERIAL_TYPE_EXACT.get(v.toLowerCase());
  if (exact) return exact;

  const vl = v.toLowerCase();

  // Step 2: common shorthand/abbreviation lookup
  const abbrevMap: Record<string, string> = {
    // Aggregate shorthands
    "coarseagg": "Coarse Aggregate", "coarse agg": "Coarse Aggregate",
    "fineagg":   "Fine Aggregate",   "fine agg":   "Fine Aggregate",
    "sand":      "Natural Sand",     "stone":      "Coarse Aggregate",
    "gravel":    "Gravel",
    // Cement shorthands
    "cem":    "Cement",
    "type1":  "Type I",   "type 1": "Type I",
    "type2":  "Type II",  "type 2": "Type II",
    "type3":  "Type III", "type 3": "Type III",
    // Mineral shorthands
    "flyash":      "Fly Ash",    "fly ash":     "Fly Ash",
    "flyashc":     "Fly Ash C",  "flyashf":     "Fly Ash F",
    "slag":        "Slag",       "ggbf":        "Slag (General)",
    "ggbs":        "BS 6699 GGBS",
    "silica fume": "Silica Fume","microsilica":  "Silica Fume",
    "metakaolin":  "Metakaolin", "lime":         "Hydrated Lime",
    // Water shorthands
    "citywater":  "City",      "city water": "City",
    "coldwater":  "Cold Water","hotwater":   "Hot Water",
    "hot water":  "Hot Water", "well water": "Well Water",
    "water":      "City",
    // Admixture shorthands
    "aea":      "Air Entrainer",  "air entraining": "Air Entrainer",
    "hrwr":     "Type F High Range Water Reducer",
    "hrwra":    "Type F High Range Water Reducer",
    "wrda":     "Type A Water Reducer",
    "retarder": "Type B Retarder",
    "accelerator": "Type C Accelerator",
    "calcium chloride": "Calcium Chloride Accelerator",
    "cacl": "Calcium Chloride Accelerator", "cacl2": "Calcium Chloride Accelerator",
    "fiber": "Synthetic Fibers", "fibre": "Synthetic Fibers",
    "color": "Color", "colour": "Color", "pigment": "Color",
    "shrinkage": "Shrinkage Reducer", "viscosity": "Viscosity Modifier",
    "corrosion": "Corrosion Inhibitor",
    // Aggregate trade-name patterns
    "masonsand": "Masonry Sand", "mason sand": "Masonry Sand",
    "masonrysand": "Masonry Sand", "masonry sand": "Masonry Sand",
    "pea gravel": "Gravel", "peasand": "Natural Sand", "pea sand": "Natural Sand",
    // Admixture abbreviations common in trade names
    "nca":  "Non-Chloride Accelerator",
    "cc":   "Calcium Chloride Accelerator",
    "ncc":  "Non-Chloride Accelerator",
    "wra":  "Type A Water Reducer",
    "mwr":  "Mid Range Water Reducer",
    "pci":  "Pump Aid - Integral",
    "chloride": "Calcium Chloride Accelerator",
    "non-chloride": "Non-Chloride Accelerator",
    "asr":  "ASR Mitigation",
    // Water trade-name patterns
    "citywat": "City", "coldwat": "Cold Water", "hotwat": "Hot Water",
  };
  if (abbrevMap[vl]) return abbrevMap[vl];

  // Step 3: keyword fuzzy matching scoped to family type
  if (familyType === "Aggregate") {
    if (vl.includes("coarse") || vl.includes("stone") || vl.includes("rock") ||
        vl.includes("granite") || vl.includes("limestone") || vl.includes("gravel"))
      return "Coarse Aggregate";
    if (vl.includes("fine") || vl.includes("sand"))  return "Fine Aggregate";
    if (vl.includes("light"))   return "Coarse Lightweight";
    if (vl.includes("recycle")) return "Recycled Aggs";
    if (vl.includes("crush"))   return "Crushed Concrete";
    if (vl.includes("rip rap")) return "Rip Rap";
    return "Coarse Aggregate"; // safe fallback within Aggregate
  }

  if (familyType === "Cement") {
    if (vl.includes("type i-ii") || vl.includes("type1-2")) return "Type I-II";
    if (vl.includes("type iii") || vl.includes("type3"))    return "Type III";
    if (vl.includes("type ii")  || vl.includes("type2"))    return "Type II";
    if (vl.includes("type i")   || vl.includes("type1"))    return "Type I";
    if (vl.includes("type v"))  return "Type V";
    if (vl.includes("blend"))   return "Cement Blends";
    if (vl.includes("rapid"))   return "Rapid Set";
    if (vl.includes("expan"))   return "Expansive Type K";
    return "Cement"; // safe fallback within Cement
  }

  if (familyType === "Mineral") {
    if (vl.includes("fly ash") || vl.includes("flyash"))  return "Fly Ash";
    if (vl.includes("slag") || vl.includes("ggbf") || vl.includes("ggbs")) return "Slag";
    if (vl.includes("silica fume") || vl.includes("microsilica")) return "Silica Fume";
    if (vl.includes("metakaolin")) return "Metakaolin";
    if (vl.includes("lime"))       return "Hydrated Lime";
    if (vl.includes("pozzolan"))   return "Natural Pozz N";
    return null; // too many mineral subtypes to guess safely
  }

  if (familyType === "Water") {
    if (vl.includes("cold"))             return "Cold Water";
    if (vl.includes("hot"))              return "Hot Water";
    if (vl.includes("recycle"))          return "Recycled";
    if (vl.includes("well"))             return "Well Water";
    if (vl.includes("potable") || vl.includes("drink")) return "Potable";
    if (vl.includes("ice"))              return "Flaked Ice";
    return "City"; // safe fallback within Water
  }

  if (familyType === "Admixture & Fiber") {
    if (vl.includes("air entrain"))    return "Air Entrainer";
    if (vl.includes("air detrain"))    return "Air Detrainer";
    if (vl.includes("high range") || vl.includes("hrwr")) return "Type F High Range Water Reducer";
    if (vl.includes("mid range") || vl.includes("mrwr"))  return "Mid Range Water Reducer";
    if (vl.includes("retard"))         return "Type B Retarder";
    if (vl.includes("calcium chloride") || vl.includes("cacl")) return "Calcium Chloride Accelerator";
    if (vl.includes("accelerat"))      return "Type C Accelerator";
    if (vl.includes("water reduc"))    return "Type A Water Reducer";
    if (vl.includes("shrinkage"))      return "Shrinkage Reducer";
    if (vl.includes("viscosity"))      return "Viscosity Modifier";
    if (vl.includes("steel fiber") || vl.includes("steel fibre")) return "Steel Fibers";
    if (vl.includes("synthetic fiber") || vl.includes("synthetic fibre")) return "Synthetic Fibers";
    if (vl.includes("glass fiber") || vl.includes("glass fibre")) return "Glass Fibers";
    if (vl.includes("fiber") || vl.includes("fibre")) return "Synthetic Fibers";
    if (vl.includes("color") || vl.includes("colour") || vl.includes("pigment")) return "Color";
    if (vl.includes("corrosion"))      return "Corrosion Inhibitor";
    if (vl.includes("waterproof") || vl.includes("water proof")) return "Water Proofer";
    if (vl.includes("water repel"))    return "Water Repellent";
    if (vl.includes("stabiliz"))       return "Stabilizer";
    if (vl.includes("latex"))          return "Latex Emulsion";
    if (vl.includes("asr"))            return "ASR Mitigation";
    if (vl.includes("pump"))           return "Pump Aid - Integral";
    if (vl.includes("foaming"))        return "Foaming Agent";
    if (vl.includes("strength"))       return "Strength Enhancing Admixture";
    return null; // too many admixture types to guess without more info
  }

  return null;
}

// Default Family Type per file type
const FILE_TYPE_FAMILY: Partial<Record<FileType, string>> = {
  cement:    "Cement",
  aggregate: "Aggregate",
  admixture: "Admixture & Fiber",
};

// Default Material Type per file type (used when Material Type column is absent)
const FILE_TYPE_MATERIAL_TYPE: Partial<Record<FileType, string>> = {
  cement:    "Cement",
  aggregate: "Aggregate",
  admixture: "Admixture & Fiber",
};

// Default Is Liquid per file type
const FILE_TYPE_IS_LIQUID: Partial<Record<FileType, string>> = {
  cement:    "No",
  aggregate: "No",
  admixture: "Yes",
};

// ---------------------------------------------------------------------------
// Helper: format a date value to MM/DD/YYYY string
// ---------------------------------------------------------------------------
function formatDate(value: any): string | null {
  if (value == null || value === "") return null;
  if (typeof value === "string") return value.trim();
  if (value instanceof Date) {
    const mm   = String(value.getMonth() + 1).padStart(2, "0");
    const dd   = String(value.getDate()).padStart(2, "0");
    const yyyy = value.getFullYear();
    return `${mm}/${dd}/${yyyy}`;
  }
  if (typeof value === "number") {
    try {
      const d = XLSX.SSF.parse_date_code(value);
      if (d) {
        const mm   = String(d.m).padStart(2, "0");
        const dd   = String(d.d).padStart(2, "0");
        return `${mm}/${dd}/${d.y}`;
      }
    } catch (_) { /* fall through */ }
  }
  return String(value);
}

// ---------------------------------------------------------------------------
// Helper: find the header row index (scans first 6 rows)
// ---------------------------------------------------------------------------
function findHeaderRowIndex(rows: any[][]): number {
  for (let i = 0; i < Math.min(6, rows.length); i++) {
    const row = rows[i];
    if (!row) continue;
    // Require at least 2 non-empty cells — real header rows are never single-cell
    const nonEmpty = row.filter((v) => String(v ?? "").trim().length > 0);
    if (nonEmpty.length < 2) continue;
    const joined = row.map((v) => String(v ?? "").toLowerCase()).join("|");
    if (
      joined.includes("plant") ||
      joined.includes("trade name") ||
      joined.includes("tradename") ||
      joined.includes("material type") ||
      joined.includes("material name") ||
      joined.includes("specific gravity") ||
      joined.includes("specificgravity") ||
      joined.includes("gravity") ||          // short form
      joined.includes("sp gr") ||            // short form
      joined.includes("trade name") ||
      joined.includes("item code") ||
      joined.includes("item name") ||
      joined.includes("product name") ||
      joined.includes("cementid") ||
      joined.includes("aggregateid") ||
      joined.includes("admixtureid") ||
      joined.includes("extraid") ||
      joined.includes("required for import")  // Wingra / similar export format
    ) {
      return i;
    }
  }
  return 0;
}

// ---------------------------------------------------------------------------
// Human-readable labels for each output field (used in mapping UI)
// ---------------------------------------------------------------------------
export const MATERIAL_FIELD_LABELS: Record<keyof typeof COL, string> = {
  PLANT:            "Plant Code",
  TRADE_NAME:       "Trade Name",
  DATE:             "Material Date",
  FAMILY_TYPE:      "Family Material Type",
  MATERIAL_TYPE:    "Material Type",
  SPECIFIC_GRAVITY: "Specific Gravity",
  IS_LIQUID:        "Is Liquid Admixture",
  WATER_CONTRIB:    "Water Contribution (%)",
  COST:             "Cost",
  COST_UNITS:       "Cost Units",
  MANUFACTURER:     "Manufacturer",
  MFR_SOURCE:       "Manufacturer Source",
  BATCH_ORDER:      "Batching Order Number",
  ITEM_CODE:        "Production Item Code",
  ITEM_DESC:        "Production Item Description",
  ITEM_SHORT_DESC:  "Production Item Short Description",
  ITEM_CATEGORY:    "Production Item Category",
  ITEM_CAT_DESC:    "Production Item Category Description",
  ITEM_CAT_SHORT:   "Production Item Category Short Description",
  BATCH_PANEL:      "Batch Panel Code",
};

export type MaterialFieldKey = keyof typeof COL;

// Fields the user MUST map before conversion can succeed
export const CRITICAL_MATERIAL_FIELDS: MaterialFieldKey[] = ["TRADE_NAME", "SPECIFIC_GRAVITY"];
// Fields that produce warnings if blank but don't block conversion
export const IMPORTANT_MATERIAL_FIELDS: MaterialFieldKey[] = ["PLANT", "FAMILY_TYPE", "MATERIAL_TYPE"];

// Result of pre-analysing a file's column structure before conversion
export interface ColumnMappingInfo {
  fileHeaders: string[];                             // all non-empty headers found
  detectedMappings: Partial<Record<MaterialFieldKey, string>>; // field → auto-detected header
  unmappedCritical: MaterialFieldKey[];              // must be user-resolved
  unmappedImportant: MaterialFieldKey[];             // warn user, but optional to resolve
}

// ---------------------------------------------------------------------------
// Helper: build a resolved column index map for a given header row.
// userOverrides maps field keys to the exact column header name chosen by user.
// ---------------------------------------------------------------------------
function resolveColumns(
  headerRow: any[],
  userOverrides?: Partial<Record<MaterialFieldKey, string>>
): Map<keyof typeof COL, number> {
  // Build a normalised lookup of input headers: normalised -> col index.
  // Also add a "stripped" key for headers that carry verbose suffixes like
  // "(Required for import)" or "(Required)" so they match plain aliases.
  const inputMap = new Map<string, number>();
  headerRow.forEach((cell, idx) => {
    const norm = String(cell ?? "").trim().toLowerCase();
    if (!norm) return;
    if (!inputMap.has(norm)) inputMap.set(norm, idx);
    // Strip common annotation suffixes so "Name (Required for import)" → "name"
    const stripped = norm
      .replace(/\s*\(required(?:\s+for\s+import)?\)\s*$/i, "")
      .replace(/\s*\(required\)\s*$/i, "")
      .trim();
    if (stripped && stripped !== norm && !inputMap.has(stripped)) {
      inputMap.set(stripped, idx);
    }
  });

  const resolved = new Map<keyof typeof COL, number>();

  // Apply user overrides first — they take precedence over alias matching
  if (userOverrides) {
    for (const [fieldKey, headerName] of Object.entries(userOverrides) as [MaterialFieldKey, string][]) {
      if (headerName) {
        const norm = headerName.trim().toLowerCase();
        if (inputMap.has(norm)) {
          resolved.set(fieldKey, inputMap.get(norm)!);
        }
      }
    }
  }

  for (const fieldKey of Object.keys(ALIASES) as Array<keyof typeof COL>) {
    if (resolved.has(fieldKey)) continue; // already resolved by user override

    // Phase 1: exact alias match
    for (const alias of ALIASES[fieldKey]) {
      if (inputMap.has(alias)) {
        resolved.set(fieldKey, inputMap.get(alias)!);
        break;
      }
    }

    // Phase 2: partial / contains matching — try every alias, not just the first
    if (!resolved.has(fieldKey)) {
      outer:
      for (const [norm, idx] of Array.from(inputMap.entries())) {
        for (const alias of ALIASES[fieldKey]) {
          // norm.includes(alias): header contains alias as substring
          // alias.includes(norm): alias contains abbreviated header —
          //   require norm.length >= 4 so "id" never matches "plant id" etc.
          if (alias.length >= 3 && (
            norm.includes(alias) ||
            (norm.length >= 4 && alias.length >= norm.length && alias.includes(norm))
          )) {
            resolved.set(fieldKey, idx);
            break outer;
          }
        }
      }
    }
  }

  return resolved;
}

// ---------------------------------------------------------------------------
// Pre-analysis: inspect a file's headers and report what can/can't be mapped.
// Call this before conversion to decide whether to prompt the user.
// ---------------------------------------------------------------------------
export function preAnalyzeMaterialFile(data: any[][]): ColumnMappingInfo {
  const headerIdx = findHeaderRowIndex(data);
  const headerRow = data[headerIdx] ?? [];

  const fileHeaders = headerRow
    .map((v) => String(v ?? "").trim())
    .filter((h) => h.length > 0);

  const resolved = resolveColumns(headerRow);

  const detectedMappings: Partial<Record<MaterialFieldKey, string>> = {};
  resolved.forEach((colIdx, fieldKey) => {
    const header = String(headerRow[colIdx] ?? "").trim();
    if (header) (detectedMappings as Record<string, string>)[fieldKey] = header;
  });

  const unmappedCritical  = CRITICAL_MATERIAL_FIELDS.filter((f) => !resolved.has(f));
  const unmappedImportant = IMPORTANT_MATERIAL_FIELDS.filter((f) => !resolved.has(f));

  return { fileHeaders, detectedMappings, unmappedCritical, unmappedImportant };
}

// ---------------------------------------------------------------------------
// Helper: safely read a value from a raw row via the resolved column map
// ---------------------------------------------------------------------------
function pick(row: any[], map: Map<keyof typeof COL, number>, key: keyof typeof COL): any {
  const idx = map.get(key);
  if (idx === undefined) return null;
  const v = row[idx];
  return v === undefined ? null : v;
}

// ---------------------------------------------------------------------------
// REVALIDATION — runs validation checks against already-converted workbook
// data (e.g. after AI modification).  Takes the rows from the current
// workbook sheet (including the header row) and returns a fresh set of
// ValidationIssue items without modifying the data.
// ---------------------------------------------------------------------------
export interface RevalidationResult {
  issues: ValidationIssue[];
  totalRows: number;     // data rows checked (excluding header)
  errorRows: number;     // rows with at least one error
}

export function revalidateMaterialWorkbook(rows: any[][]): RevalidationResult {
  const issues: ValidationIssue[] = [];
  let errorRows = 0;

  // rows[0] is the header row — data starts at rows[1]
  const dataRows = rows.slice(1);

  // Per-row checks
  dataRows.forEach((row, idx) => {
    const dataRowNum = idx + 1; // 1-based
    const tradeName  = String(row[COL.TRADE_NAME]  ?? "").trim();
    const itemCode   = String(row[COL.ITEM_CODE]   ?? "").trim();

    // Skip fully blank rows silently
    if (!tradeName && !itemCode) return;

    let rowHasError = false;

    // CHECK: Trade Name required
    if (!tradeName) {
      issues.push({
        type: "error",
        message: `Row ${dataRowNum}: Missing Trade Name.`,
        row: dataRowNum,
        field: "Trade Name (Required)",
      });
      rowHasError = true;
    }

    // CHECK: Plant Code blank
    const plantCode = String(row[COL.PLANT] ?? "").trim();
    if (!plantCode) {
      issues.push({
        type: "warning",
        message: `Row ${dataRowNum}${tradeName ? ` ('${tradeName}')` : ""}: Plant Code is blank.`,
        row: dataRowNum,
        field: "Plant Code (Required)",
      });
    }

    // CHECK: Family Material Type blank or invalid
    const familyType = String(row[COL.FAMILY_TYPE] ?? "").trim();
    if (!familyType) {
      issues.push({
        type: "warning",
        message: `Row ${dataRowNum}${tradeName ? ` ('${tradeName}')` : ""}: Family Material Type is blank.`,
        row: dataRowNum,
        field: "Family Material Type (Required)",
      });
    } else if (!VALID_FAMILY_TYPES.has(familyType.toLowerCase())) {
      issues.push({
        type: "warning",
        message: `Row ${dataRowNum}${tradeName ? ` ('${tradeName}')` : ""}: Family Material Type '${familyType}' is not recognized. Valid values: Cement, Mineral, Aggregate, Admixture & Fiber, Water.`,
        row: dataRowNum,
        field: "Family Material Type (Required)",
      });
    }

    // CHECK: Material Type blank
    const materialType = String(row[COL.MATERIAL_TYPE] ?? "").trim();
    if (!materialType) {
      issues.push({
        type: "warning",
        message: `Row ${dataRowNum}${tradeName ? ` ('${tradeName}')` : ""}: Material Type is blank.`,
        row: dataRowNum,
        field: "Material Type (Required)",
      });
    }

    // CHECK: Specific Gravity in range 0.4–10.0
    const sgVal = row[COL.SPECIFIC_GRAVITY];
    const sgNum = (sgVal === null || sgVal === undefined || sgVal === "") ? null : Number(sgVal);
    if (sgNum === null || isNaN(sgNum) || sgNum < 0.4 || sgNum >= 10.0) {
      issues.push({
        type: "error",
        message: `Row ${dataRowNum}${tradeName ? ` ('${tradeName}')` : ""}: Specific Gravity must be 0.4 or greater and less than 10.0 (got ${sgNum ?? "missing"}).`,
        row: dataRowNum,
        field: "Specific Gravity (Required)",
      });
      rowHasError = true;
    }

    // CHECK: Trade Name length <= 70
    if (tradeName.length > 70) {
      issues.push({
        type: "warning",
        message: `Row ${dataRowNum} ('${tradeName}'): Trade Name exceeds 70 characters (${tradeName.length}).`,
        row: dataRowNum,
        field: "Trade Name (Required)",
      });
    }

    // CHECK: Cost >= 0
    const costVal = row[COL.COST];
    const costNum = (costVal === null || costVal === undefined || costVal === "") ? null : Number(costVal);
    if (costNum !== null && !isNaN(costNum) && costNum < 0) {
      issues.push({
        type: "error",
        message: `Row ${dataRowNum}${tradeName ? ` ('${tradeName}')` : ""}: Cost must be 0.0 or greater.`,
        row: dataRowNum,
        field: "Cost",
      });
      rowHasError = true;
    }

    // CHECK: Cost Units valid when cost is provided
    const costUnits = String(row[COL.COST_UNITS] ?? "").trim();
    if (costNum !== null && !isNaN(costNum) && costNum >= 0 &&
        costUnits && !VALID_COST_UNITS.has(costUnits.toLowerCase())) {
      issues.push({
        type: "warning",
        message: `Row ${dataRowNum}${tradeName ? ` ('${tradeName}')` : ""}: Cost Unit '${costUnits}' is not in the recognized list.`,
        row: dataRowNum,
        field: "Cost Units",
      });
    }

    // CHECK: Batching Order Number must be numeric
    const batchOrderVal = String(row[COL.BATCH_ORDER] ?? "").trim();
    if (batchOrderVal && isNaN(Number(batchOrderVal))) {
      issues.push({
        type: "error",
        message: `Row ${dataRowNum}${tradeName ? ` ('${tradeName}')` : ""}: Batching Order Number '${batchOrderVal}' must be numeric.`,
        row: dataRowNum,
        field: "Batching Order Number",
      });
      rowHasError = true;
    }

    // CHECK: Manufacturer Source <= 50 chars
    const mfrSource = String(row[COL.MFR_SOURCE] ?? "").trim();
    if (mfrSource.length > 50) {
      issues.push({
        type: "warning",
        message: `Row ${dataRowNum}${tradeName ? ` ('${tradeName}')` : ""}: Manufacturer Source Name exceeds 50 characters (${mfrSource.length}).`,
        row: dataRowNum,
        field: "Manufacturer Source",
      });
    }

    if (rowHasError) errorRows++;
  });

  // CHECK 4: Duplicate Trade Name per Plant
  const tradeNameSeen = new Map<string, number>();
  dataRows.forEach((row, idx) => {
    const tradeName = String(row[COL.TRADE_NAME] ?? "").trim();
    const itemCode  = String(row[COL.ITEM_CODE]  ?? "").trim();
    if (!tradeName && !itemCode) return;
    const key = `${String(row[COL.PLANT] ?? "").trim().toUpperCase()}||${tradeName.toUpperCase()}`;
    if (tradeNameSeen.has(key)) {
      const plant = String(row[COL.PLANT] ?? "").trim();
      issues.push({
        type: "error",
        message: `Row ${idx + 1}: Duplicate Trade Name in Plant ${plant || "(unknown)"} — '${tradeName}' already exists.`,
        row: idx + 1,
        field: "Trade Name",
      });
    } else {
      tradeNameSeen.set(key, idx);
    }
  });

  // CHECK 5: Duplicate Production Item Code per Plant
  const itemCodeSeen = new Map<string, number>();
  dataRows.forEach((row, idx) => {
    const code = String(row[COL.ITEM_CODE] ?? "").trim();
    if (!code) return;
    const key = `${String(row[COL.PLANT] ?? "").trim().toUpperCase()}||${code.toUpperCase()}`;
    if (itemCodeSeen.has(key)) {
      const plant = String(row[COL.PLANT] ?? "").trim();
      issues.push({
        type: "error",
        message: `Row ${idx + 1}: Duplicate Item Code '${code}' in Plant ${plant || "(unknown)"}.`,
        row: idx + 1,
        field: "Production Item Code",
      });
    } else {
      itemCodeSeen.set(key, idx);
    }
  });

  return {
    issues,
    totalRows: dataRows.filter((r) => {
      const t = String(r[COL.TRADE_NAME] ?? "").trim();
      const c = String(r[COL.ITEM_CODE]  ?? "").trim();
      return t || c;
    }).length,
    errorRows,
  };
}

export function convertAndMergeMaterials(
  files: { data: any[][]; fileName: string }[],
  columnOverrides?: Partial<Record<MaterialFieldKey, string>>
): MaterialConversionResult {
  const allIssues: ValidationIssue[] = [];
  const allDataRows: any[][] = [];
  let totalInputRows = 0;
  let totalSkipped   = 0;

  const multiFile = files.length > 1;

  for (const { data, fileName } of files) {
    const prefix = multiFile ? `[${fileName}] ` : "";

    if (!data || data.length === 0) {
      allIssues.push({ type: "error", message: `${prefix}File is empty or could not be read.` });
      continue;
    }

    const headerIdx = findHeaderRowIndex(data);
    const headerRow = data[headerIdx];
    const colMap    = resolveColumns(headerRow, columnOverrides);

    // Detect file type from column structure
    const fileType = inferFileType(headerRow);

    // Skip extra-list files entirely — they contain charges/fees, not materials
    if (fileType === "extra") {
      allIssues.push({
        type: "warning",
        message: `${prefix}File appears to be an extras/charges list (contains 'ExtraId' column) — skipped. Only material files are processed.`,
      });
      continue;
    }

    // Warn about any output fields that could not be mapped (only critical ones)
    const unmapped: string[] = [];
    if (!colMap.has("TRADE_NAME")) unmapped.push(OUTPUT_HEADERS[COL.TRADE_NAME]);
    if (!colMap.has("SPECIFIC_GRAVITY")) unmapped.push(OUTPUT_HEADERS[COL.SPECIFIC_GRAVITY]);
    if (unmapped.length > 0) {
      allIssues.push({
        type: "warning",
        message: `${prefix}Could not find columns for: ${unmapped.join(", ")}. Those fields will be empty in the output.`,
      });
    }

    // Process data rows
    for (let ri = headerIdx + 1; ri < data.length; ri++) {
      const raw = data[ri];
      if (!raw) continue;

      const dataRowNum = ri - headerIdx; // 1-based relative to header

      const tradeName  = String(pick(raw, colMap, "TRADE_NAME")  ?? "").trim();
      const itemCode   = String(pick(raw, colMap, "ITEM_CODE")    ?? "").trim();

      // CHECK 1: Skip fully blank rows silently
      if (!tradeName && !itemCode) continue;

      totalInputRows++;

      // CHECK 2: Trade Name required
      if (!tradeName) {
        allIssues.push({
          type: "error",
          message: `${prefix}Row ${dataRowNum}: Missing Trade Name — row skipped.`,
          row: dataRowNum,
          field: "Trade Name",
        });
        totalSkipped++;
        continue;
      }

      // Read remaining fields
      let familyType   = String(pick(raw, colMap, "FAMILY_TYPE")  ?? "").trim();
      let materialType = String(pick(raw, colMap, "MATERIAL_TYPE") ?? "").trim();
      let sg           = pick(raw, colMap, "SPECIFIC_GRAVITY");
      let isLiquid     = String(pick(raw, colMap, "IS_LIQUID")     ?? "").trim();

      // Apply file-type-based defaults when columns are absent
      if (!familyType   && fileType !== "unknown") familyType   = FILE_TYPE_FAMILY[fileType]   ?? "";
      if (!materialType && fileType !== "unknown") materialType = FILE_TYPE_MATERIAL_TYPE[fileType] ?? "";

      const waterContrib = pick(raw, colMap, "WATER_CONTRIB");
      const cost         = pick(raw, colMap, "COST");
      let   costUnits    = String(pick(raw, colMap, "COST_UNITS")        ?? "").trim();
      const plantCode    = String(pick(raw, colMap, "PLANT")             ?? "").trim();
      const dateRaw      = pick(raw, colMap, "DATE");
      const manufacturer = String(pick(raw, colMap, "MANUFACTURER")      ?? "").trim();
      const mfrSource    = String(pick(raw, colMap, "MFR_SOURCE")        ?? "").trim();
      const batchOrder   = pick(raw, colMap, "BATCH_ORDER");
      const itemDesc     = String(pick(raw, colMap, "ITEM_DESC")         ?? "").trim();
      const itemShort    = String(pick(raw, colMap, "ITEM_SHORT_DESC")   ?? "").trim();
      let   itemCat      = String(pick(raw, colMap, "ITEM_CATEGORY")     ?? "").trim();
      const itemCatDesc  = String(pick(raw, colMap, "ITEM_CAT_DESC")     ?? "").trim();
      const itemCatShort = String(pick(raw, colMap, "ITEM_CAT_SHORT")    ?? "").trim();
      const batchPanel   = String(pick(raw, colMap, "BATCH_PANEL")       ?? "").trim();

      // ── Family Type normalization ───────────────────────────────────────
      // Step 1: if family type is missing, try to derive from material type name
      if (!familyType && materialType) {
        const derived = normalizeFamilyType(materialType);
        if (derived) familyType = derived;
      }
      // Step 2: if family type exists but isn't a valid value, try to map it
      if (familyType && !VALID_FAMILY_TYPES.has(familyType.toLowerCase())) {
        const normalized = normalizeFamilyType(familyType);
        if (normalized) {
          allIssues.push({
            type: "warning",
            message: `${prefix}Row ${dataRowNum} ('${tradeName}'): Family Material Type '${familyType}' corrected to '${normalized}'.`,
            row: dataRowNum,
            field: "Family Material Type",
          });
          familyType = normalized;
        }
      }

      // ── T2: Specific material-type-based family overrides ──────────────
      const matLower = materialType.toLowerCase();
      const correctedFamily = MATERIAL_TYPE_TO_FAMILY[matLower];
      if (correctedFamily && familyType !== correctedFamily) {
        allIssues.push({
          type: "warning",
          message: `${prefix}Row ${dataRowNum} ('${tradeName}'): Family Type corrected from '${familyType || "(empty)"}' to '${correctedFamily}' based on Material Type '${materialType}'.`,
          row: dataRowNum,
          field: "Family Material Type",
        });
        familyType = correctedFamily;
        if (itemCat && itemCat !== correctedFamily) {
          itemCat = correctedFamily;
        }
      }

      // ── Material Type normalization ────────────────────────────────────
      // Try raw material type first; if that can't be resolved, fall back to
      // the trade name as a hint (trade names often reveal the specific type
      // when the material type column only has a generic abbreviation like ADMIX).
      {
        const fromRaw   = normalizeMaterialType(materialType, familyType);
        const fromName  = fromRaw ?? normalizeMaterialType(tradeName, familyType);
        const finalMT   = fromName;

        if (finalMT && finalMT !== materialType) {
          // Only emit a warning when the original wasn't already a valid cased match
          if (materialType && !MATERIAL_TYPE_EXACT.has(materialType.toLowerCase())) {
            const hint = !fromRaw ? " (derived from Trade Name)" : "";
            allIssues.push({
              type: "warning",
              message: `${prefix}Row ${dataRowNum} ('${tradeName}'): Material Type '${materialType}' mapped to '${finalMT}'${hint}.`,
              row: dataRowNum,
              field: "Material Type (Required)",
            });
          }
          materialType = finalMT;
        } else if (!finalMT && materialType && !MATERIAL_TYPE_EXACT.has(materialType.toLowerCase())) {
          allIssues.push({
            type: "warning",
            message: `${prefix}Row ${dataRowNum} ('${tradeName}'): Material Type '${materialType}' is not recognized and could not be determined from the Trade Name — leaving blank.`,
            row: dataRowNum,
            field: "Material Type (Required)",
          });
          materialType = "";
        } else if (finalMT && finalMT !== materialType) {
          // Silent case-correction (value was valid but wrong case)
          materialType = finalMT;
        }
      }

      // ── Validation: Plant, Family Type, Material Type ───────────────────
      // Plant: leave blank — never copy item code into plant
      if (!plantCode) {
        allIssues.push({
          type: "warning",
          message: `${prefix}Row ${dataRowNum} ('${tradeName}'): Plant Code is blank — material may fail database import.`,
          row: dataRowNum,
          field: "Plant Code (Required)",
        });
      }
      if (!familyType) {
        allIssues.push({
          type: "warning",
          message: `${prefix}Row ${dataRowNum} ('${tradeName}'): Family Material Type is blank.`,
          row: dataRowNum,
          field: "Family Material Type (Required)",
        });
      } else if (!VALID_FAMILY_TYPES.has(familyType.toLowerCase())) {
        allIssues.push({
          type: "warning",
          message: `${prefix}Row ${dataRowNum} ('${tradeName}'): Family Material Type '${familyType}' is not recognized. Valid values: Cement, Mineral, Aggregate, Admixture & Fiber, Water.`,
          row: dataRowNum,
          field: "Family Material Type (Required)",
        });
      }
      if (!materialType) {
        allIssues.push({
          type: "warning",
          message: `${prefix}Row ${dataRowNum} ('${tradeName}'): Material Type is blank.`,
          row: dataRowNum,
          field: "Material Type (Required)",
        });
      }
      if (tradeName.length > 70) {
        allIssues.push({
          type: "warning",
          message: `${prefix}Row ${dataRowNum} ('${tradeName}'): Trade Name exceeds 70 characters (${tradeName.length}).`,
          row: dataRowNum,
          field: "Trade Name (Required)",
        });
      }

      // ── T3: Specific Gravity — default to 1 when not provided ───────────
      const sgRaw = sg === null || sg === "" || sg === undefined ? null : Number(sg);
      let finalSG: number | null = (sgRaw !== null && !isNaN(sgRaw)) ? sgRaw : null;

      if (finalSG === null) {
        finalSG = 1; // use 1 as a safe neutral SG when not provided
      }

      // CHECK 3: Specific Gravity required and in range 0.4–10.0
      if (finalSG === null || isNaN(finalSG) || finalSG < 0.4 || finalSG >= 10.0) {
        allIssues.push({
          type: "error",
          message: `${prefix}Row ${dataRowNum} ('${tradeName}'): Specific Gravity must be 0.4 or greater and less than 10.0 (got ${finalSG ?? "missing"}) — row skipped.`,
          row: dataRowNum,
          field: "Specific Gravity (Required)",
        });
        totalSkipped++;
        continue;
      }

      // ── T4: Cost Units default ──────────────────────────────────────────
      if (!costUnits) costUnits = "$/lb";

      // ── Validation: Cost, Cost Units, Batch Order, Mfr Source ──────────
      const costNum = (cost === null || cost === undefined || cost === "") ? null : Number(cost);
      if (costNum !== null && !isNaN(costNum) && costNum < 0) {
        allIssues.push({
          type: "error",
          message: `${prefix}Row ${dataRowNum} ('${tradeName}'): Cost must be 0.0 or greater (got ${costNum}).`,
          row: dataRowNum,
          field: "Cost",
        });
      }
      if (costNum !== null && !isNaN(costNum) && costNum >= 0 &&
          !VALID_COST_UNITS.has(costUnits.toLowerCase())) {
        allIssues.push({
          type: "warning",
          message: `${prefix}Row ${dataRowNum} ('${tradeName}'): Cost Unit '${costUnits}' is not in the recognized list. Common valid units: $/lb, $/gal, $/ton, $/kg, $/liter.`,
          row: dataRowNum,
          field: "Cost Units",
        });
      }
      const batchOrderStr = String(batchOrder ?? "").trim();
      if (batchOrderStr && isNaN(Number(batchOrderStr))) {
        allIssues.push({
          type: "error",
          message: `${prefix}Row ${dataRowNum} ('${tradeName}'): Batching Order Number '${batchOrderStr}' must be numeric.`,
          row: dataRowNum,
          field: "Batching Order Number",
        });
      }
      if (mfrSource.length > 50) {
        allIssues.push({
          type: "warning",
          message: `${prefix}Row ${dataRowNum} ('${tradeName}'): Manufacturer Source Name exceeds 50 characters (${mfrSource.length}).`,
          row: dataRowNum,
          field: "Manufacturer Source",
        });
      }

      // ── T5: Production Item Code cleanup ───────────────────────────────
      const cleanItemCode = itemCode.replace(/\s+/g, "");

      // ── T1: Date format — default to today when not provided ────────────
      const formattedDate = formatDate(dateRaw) || (() => {
        const d  = new Date();
        const mm = String(d.getMonth() + 1).padStart(2, "0");
        const dd = String(d.getDate()).padStart(2, "0");
        return `${mm}/${dd}/${d.getFullYear()}`;
      })();

      // ── Is Liquid: always derived from Family Type ───────────────────────
      const derivedIsLiquid = familyType === "Admixture & Fiber" ? "Yes" : "No";

      // Build output row in fixed OUTPUT_HEADERS order
      const out: any[] = new Array(OUTPUT_HEADERS.length).fill(null);
      out[COL.PLANT]            = plantCode    || null;
      out[COL.TRADE_NAME]       = tradeName;
      out[COL.DATE]             = formattedDate;
      out[COL.FAMILY_TYPE]      = familyType   || null;
      out[COL.MATERIAL_TYPE]    = materialType || null;
      out[COL.SPECIFIC_GRAVITY] = finalSG;
      out[COL.IS_LIQUID]        = derivedIsLiquid;
      out[COL.WATER_CONTRIB]    = (waterContrib === "" || waterContrib === undefined) ? null : waterContrib;
      out[COL.COST]             = (cost         === "" || cost         === undefined) ? null : cost;
      out[COL.COST_UNITS]       = costUnits     || null;
      out[COL.MANUFACTURER]     = manufacturer  || null;
      out[COL.MFR_SOURCE]       = mfrSource     || null;
      out[COL.BATCH_ORDER]      = (batchOrder   === "" || batchOrder   === undefined) ? null : batchOrder;
      out[COL.ITEM_CODE]        = cleanItemCode || null;
      out[COL.ITEM_DESC]        = itemDesc      || null;
      out[COL.ITEM_SHORT_DESC]  = itemShort     || null;
      out[COL.ITEM_CATEGORY]    = itemCat       || null;
      out[COL.ITEM_CAT_DESC]    = itemCatDesc   || null;
      out[COL.ITEM_CAT_SHORT]   = itemCatShort  || null;
      out[COL.BATCH_PANEL]      = batchPanel    || null;

      allDataRows.push(out);
    }
  }

  // ── POST-MERGE: CHECK 4 — Duplicate Trade Name per Plant ────────────────
  const tradeNameSeen    = new Map<string, number>();
  const dupTradeNameRows = new Set<number>();

  allDataRows.forEach((row, i) => {
    const key = `${String(row[COL.PLANT] ?? "").trim().toUpperCase()}||${String(row[COL.TRADE_NAME] ?? "").trim().toUpperCase()}`;
    if (tradeNameSeen.has(key)) {
      dupTradeNameRows.add(i);
    } else {
      tradeNameSeen.set(key, i);
    }
  });

  // ── POST-MERGE: CHECK 5 — Duplicate Item Code per Plant ─────────────────
  const itemCodeSeen    = new Map<string, number>();
  const dupItemCodeRows = new Set<number>();

  allDataRows.forEach((row, i) => {
    const code = String(row[COL.ITEM_CODE] ?? "").trim().toUpperCase();
    if (!code) return;
    const key = `${String(row[COL.PLANT] ?? "").trim().toUpperCase()}||${code}`;
    if (itemCodeSeen.has(key)) {
      dupItemCodeRows.add(i);
    } else {
      itemCodeSeen.set(key, i);
    }
  });

  // Collect human-readable labels for reporting
  const dupTradeNameLabels = new Set<string>();
  Array.from(dupTradeNameRows).forEach((i) => {
    dupTradeNameLabels.add(
      `Plant ${String(allDataRows[i][COL.PLANT] ?? "").trim()}: "${String(allDataRows[i][COL.TRADE_NAME] ?? "").trim()}"`
    );
  });

  const dupItemCodeLabels = new Set<string>();
  Array.from(dupItemCodeRows).forEach((i) => {
    dupItemCodeLabels.add(
      `Plant ${String(allDataRows[i][COL.PLANT] ?? "").trim()}: item code "${String(allDataRows[i][COL.ITEM_CODE] ?? "").trim()}"`
    );
  });

  // Remove duplicates (keep first occurrence)
  const rowsToRemove = new Set([
    ...Array.from(dupTradeNameRows),
    ...Array.from(dupItemCodeRows),
  ]);
  const cleanedRows = allDataRows.filter((_, i) => !rowsToRemove.has(i));

  Array.from(dupTradeNameLabels).forEach((label) => {
    allIssues.push({
      type: "error",
      message: `Duplicate Trade Name removed — ${label} appeared more than once in the same plant. Kept first occurrence.`,
      field: "Trade Name",
    });
  });
  Array.from(dupItemCodeLabels).forEach((label) => {
    allIssues.push({
      type: "error",
      message: `Duplicate Production Item Code removed — ${label} appeared more than once in the same plant. Kept first occurrence.`,
      field: "Production Item Code",
    });
  });

  totalSkipped += rowsToRemove.size;

  return {
    rows: [OUTPUT_HEADERS, ...cleanedRows],
    issues: allIssues,
    totalInputRows,
    totalOutputRows: cleanedRows.length,
    skippedRows: totalSkipped,
  };
}