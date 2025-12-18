/**
 * MPAQ Mixes Converter
 * 
 * Converts MPAQ mix export data to Command Series import format
 * Requires two files:
 * 1. Mix list file (mix-list.csv or Excel)
 * 2. Materials lookup file (completed materials file)
 * 
 * Rules:
 * - Plant duplication: 01, 02, 03, 05, 06
 * - Filter: Only mixes with WaterTarget > 0
 * - Each mix expanded into multiple rows (one per constituent material)
 * - Water added as separate constituent row
 * - Strength extracted from mix Name field
 * - Slump extracted from Slump field when available
 * - Material IDs kept as raw values from input
 * - Units: kg/m^3 for aggregates/cement, mL/100kg CM for admixtures, L for water
 */

// ---------- CONFIG ----------
const PLANTS = ["01", "02", "03", "05", "06"];

// Material blocks
const AGG_COUNT = 6;   // Agg1..Agg6
const CEM_COUNT = 4;   // Cem1..Cem4
const ADM_COUNT = 8;   // Adm1..Adm8

// Final output column order
const FINAL_COLUMNS = [
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
    "Design Slump (in)",
    "Min Slump (in)",
    "Max Slump (in)",
    "Max Batch Size",
    "Max Water Gallons",
    "Max W/C+P",
    "Max W/C",
    "Mix Class Names, separate with semicolon",
    "Mix Usage",
    "Dispatch Slump Range",
    "Dispatch",
    "Constituent Item Code",
    "Constituent Item Description",
    "Quantity",
    "Unit Name"
];

// ---------- Helper functions ----------

/**
 * Extract strength in MPA from mix name (Column B)
 * Looks for first decimal number at beginning of string
 */
function extractStrength(name: any): number | string {
    if (name === null || name === undefined) {
        return "";
    }
    const s = String(name);
    // Match number at the beginning: "0.4 Mpa..." or "25 MPA..."
    const match = s.match(/^(\d+\.?\d*)/);
    if (match) {
        return parseFloat(match[1]);
    }
    return "";
}

/**
 * Extract slump in mm from slump field (Column K)
 * Patterns:
 * - ('xx'mm) where xx is the value
 * - (Slump 'xx'mm) where xx is the value
 * - Direct number
 */
function extractSlump(slumpValue: any): number | string {
    if (slumpValue === null || slumpValue === undefined) {
        return "";
    }
    
    const slumpStr = String(slumpValue);
    
    // Pattern 1: ('xx'mm) or (Slump 'xx'mm)
    const match1 = slumpStr.match(/'(\d+)'mm/);
    if (match1) {
        return parseFloat(match1[1]);
    }
    
    // Pattern 2: (Slump xxmm)
    const match2 = slumpStr.match(/Slump\s+(\d+)mm/i);
    if (match2) {
        return parseFloat(match2[1]);
    }
    
    // Pattern 3: Direct number
    const num = parseFloat(slumpStr);
    if (!isNaN(num)) {
        return num;
    }
    
    return "";
}

/**
 * Determine unit based on material type
 * - Aggregates & Cement: kg/m^3
 * - Admixtures: mL/100kg CM
 * - Water: L
 */
function getUnitForMaterialType(matType: string): string {
    if (matType === "Aggregate" || matType === "Cement") {
        return "kg/m^3";
    }
    if (matType === "Admixture") {
        return "mL/100kg CM";
    }
    if (matType === "Water") {
        return "L";
    }
    return "";
}

function safeGet(row: any, col: string): any {
    return row.hasOwnProperty(col) ? row[col] : "";
}

function isEmptyValue(val: any): boolean {
    return val === null || val === undefined || val === "" || 
           (typeof val === 'number' && isNaN(val));
}

function isZeroOrEmpty(val: any): boolean {
    return isEmptyValue(val) || val === 0 || val === "0";
}

// ---------- Main conversion function ----------

/**
 * Convert Sarjeants mix data with materials lookup
 * @param mixData - 2D array from mix-list.csv
 * @param materialsData - 2D array from materials lookup file (optional, not used for ID transformation)
 * @returns 2D array in Command Series import format
 */
export function convertMPAQMixes(mixData: any[][], materialsData?: any[][]): any[][] {
    console.log("Starting MPAQ Mixes conversion...");
    console.log("Mix data rows:", mixData.length);
    if (materialsData) {
        console.log("Materials data rows:", materialsData.length);
    }
    
    if (mixData.length === 0) {
        throw new Error("Mix data is empty");
    }
    
    // First row is headers
    const headers = mixData[0];
    console.log("Mix headers:", headers);
    
    // Convert array of arrays to array of objects
    const data = mixData.slice(1).map(row => {
        const obj: any = {};
        headers.forEach((header: any, index: number) => {
            obj[header] = row[index];
        });
        return obj;
    });
    
    console.log("Converted to objects:", data.length, "rows");
    
    // Filter mixes with WaterTarget > 0
    const validMixes = data.filter(row => {
        const waterTarget = safeGet(row, "WaterTarget");
        return !isZeroOrEmpty(waterTarget) && parseFloat(waterTarget) > 0;
    });
    
    console.log(`Filtered to ${validMixes.length} valid mixes (WaterTarget > 0)`);
    
    if (validMixes.length === 0) {
        throw new Error("No valid mixes found with WaterTarget > 0");
    }
    
    // Prepare material column names
    const aggCols: [string, string, string][] = [];
    for (let i = 1; i <= AGG_COUNT; i++) {
        aggCols.push([`Agg${i}Id`, `Agg${i}Name`, `Agg${i}Target`]);
    }
    
    const cemCols: [string, string, string][] = [];
    for (let i = 1; i <= CEM_COUNT; i++) {
        cemCols.push([`Cem${i}Id`, `Cem${i}Name`, `Cem${i}Target`]);
    }
    
    const admCols: [string, string, string][] = [];
    for (let i = 1; i <= ADM_COUNT; i++) {
        admCols.push([`Adm${i}Id`, `Adm${i}Name`, `Adm${i}Target`]);
    }
    
    // Verify required columns
    if (!validMixes[0] || !validMixes[0].hasOwnProperty("MixId") || !validMixes[0].hasOwnProperty("Name")) {
        throw new Error("Input file must contain 'MixId' and 'Name' columns.");
    }
    
    const outRows: any[][] = [];
    
    // Add header row
    outRows.push(FINAL_COLUMNS);
    
    // Process each valid mix row
    for (let idx = 0; idx < validMixes.length; idx++) {
        const row = validMixes[idx];
        
        const mixId = safeGet(row, "MixId");
        const nameVal = safeGet(row, "Name");
        const externalId = safeGet(row, "ExternalId");
        const airFactor = safeGet(row, "AirFactor");
        const slumpVal = safeGet(row, "Slump");
        const waterTarget = safeGet(row, "WaterTarget");
        
        // Extract strength and slump
        const strengthMpa = extractStrength(nameVal);
        const slumpMm = extractSlump(slumpVal);
        
        // Build base data for this mix (same for all constituents)
        const baseData = {
            mixName: mixId,
            description: nameVal || "",
            shortDescription: mixId,
            itemCategory: externalId || "",
            strengthAge: 28,
            strengthMpa: strengthMpa,
            airContent: airFactor || "",
            slump: slumpMm,
            maxWater: waterTarget || ""
        };
        
        // Collect all constituents for this mix
        const constituents: [string, any, any, any][] = [];
        
        // Aggregates
        for (const [aid, aname, atarget] of aggCols) {
            const matId = safeGet(row, aid);
            const matName = safeGet(row, aname);
            const matTarget = safeGet(row, atarget);
            if (!isEmptyValue(matId) && !isZeroOrEmpty(matTarget)) {
                constituents.push(["Aggregate", matId, matName, matTarget]);
            }
        }
        
        // Cements
        for (const [cid, cname, ctarget] of cemCols) {
            const matId = safeGet(row, cid);
            const matName = safeGet(row, cname);
            const matTarget = safeGet(row, ctarget);
            if (!isEmptyValue(matId) && !isZeroOrEmpty(matTarget)) {
                constituents.push(["Cement", matId, matName, matTarget]);
            }
        }
        
        // Admixtures
        for (const [aid, aname, atarget] of admCols) {
            const matId = safeGet(row, aid);
            const matName = safeGet(row, aname);
            const matTarget = safeGet(row, atarget);
            if (!isEmptyValue(matId) && !isZeroOrEmpty(matTarget)) {
                constituents.push(["Admixture", matId, matName, matTarget]);
            }
        }
        
        // Add Water as a constituent
        if (!isZeroOrEmpty(waterTarget)) {
            constituents.push(["Water", "WATER", "Water", waterTarget]);
        }
        
        // Create rows for each plant and each constituent
        for (const plant of PLANTS) {
            for (const [matType, matId, matName, matTarget] of constituents) {
                const unitName = getUnitForMaterialType(matType);
                
                const outRow = [
                    plant,                          // Plant Code
                    baseData.mixName,               // Mix Name
                    baseData.description,           // Description
                    baseData.shortDescription,      // Short Description
                    baseData.itemCategory,          // Item Category
                    baseData.strengthAge,           // Strength Age (Default 28)
                    baseData.strengthMpa,           // Strength (MPA)
                    baseData.airContent,            // Design Air Content (%)
                    "",                             // Min Air Content (%)
                    "",                             // Max Air Content (%)
                    baseData.slump,                 // Design Slump (in) - actually mm
                    "",                             // Min Slump (in)
                    "",                             // Max Slump (in)
                    "",                             // Max Batch Size
                    baseData.maxWater,              // Max Water Gallons - actually L
                    "",                             // Max W/C+P
                    "",                             // Max W/C
                    "",                             // Mix Class Names
                    "",                             // Mix Usage
                    "",                             // Dispatch Slump Range
                    "",                             // Dispatch
                    matId,                          // Constituent Item Code (raw ID)
                    matName || "",                  // Constituent Item Description
                    matTarget || "",                // Quantity
                    unitName                        // Unit Name
                ];
                outRows.push(outRow);
            }
        }
        
        if ((idx + 1) % 50 === 0) {
            console.log(`Processed ${idx + 1}/${validMixes.length} valid mixes...`);
        }
    }
    
    console.log("Conversion complete. Output rows:", outRows.length - 1); // -1 for header
    return outRows;
}