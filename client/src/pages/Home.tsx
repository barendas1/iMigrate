import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { cn } from "@/lib/utils";
import {
  AlertCircle,
  AlertTriangle,
  CheckCircle2,
  Download,
  Eye,
  FileSpreadsheet,
  Loader2,
  RefreshCw,
  Upload,
  UploadCloud,
  X,
} from "lucide-react";
import { PreviewSection } from "@/components/PreviewSection";
import { AIModificationPanel } from "@/components/AIModificationPanel";
import { AIMixConversionPanel } from "@/components/AIMixConversionPanel";
import { useCallback, useState } from "react";
import { useDropzone } from "react-dropzone";
import * as XLSX from "xlsx";
import { saveAs } from "file-saver";
import {
  convertAndMergeMaterials,
  revalidateMaterialWorkbook,
  preAnalyzeMaterialFile,
  MATERIAL_FIELD_LABELS,
  CRITICAL_MATERIAL_FIELDS,
  IMPORTANT_MATERIAL_FIELDS,
} from "../converters/materials/universal";
import { convertAndMergeMixes, buildMaterialsLookup } from "../converters/mixes/universal";
import type {
  ValidationIssue,
  ColumnMappingInfo,
  MaterialFieldKey,
} from "../converters/materials/universal";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Label } from "@/components/ui/label";

interface ApprovedFile {
  workbook: XLSX.WorkBook;
  customerName: string;
  approvedAt: string;
  rowCount: number;
}

export default function Home() {
  const [activeTab, setActiveTab] = useState("materials");
  const [customerName, setCustomerName] = useState<string>("");
  const [files, setFiles] = useState<File[]>([]);
  const [isProcessing, setIsProcessing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const [convertedData, setConvertedData] = useState<any>(null);
  const [originalConvertedData, setOriginalConvertedData] = useState<any>(null);
  const [showInlinePreview, setShowInlinePreview] = useState(false);
  const [validationIssues, setValidationIssues] = useState<ValidationIssue[]>([]);
  const [conversionStats, setConversionStats] = useState<{
    totalInput: number;
    totalOutput: number;
    skipped: number;
  } | null>(null);

  // Approved files queued for upload (persist across tab switches)
  const [approvedMaterials, setApprovedMaterials] = useState<ApprovedFile | null>(null);
  const [approvedMixes, setApprovedMixes] = useState<ApprovedFile | null>(null);

  // Column-mapping prompt state (materials tab only)
  const [mappingInfo, setMappingInfo] = useState<ColumnMappingInfo | null>(null);
  const [userMappings, setUserMappings] = useState<Partial<Record<MaterialFieldKey, string>>>({});
  const [pendingFileData, setPendingFileData] = useState<{ data: any[][]; fileName: string }[]>([]);

  // ── File drop ──────────────────────────────────────────────────────────────
  const onDrop = useCallback(
    (acceptedFiles: File[]) => {
      setError(null);
      setSuccess(false);
      setConvertedData(null);
      setShowInlinePreview(false);
      setValidationIssues([]);
      setConversionStats(null);

      const validFiles = acceptedFiles.filter(
        (f) =>
          f.name.endsWith(".xlsx") ||
          f.name.endsWith(".xls") ||
          f.name.endsWith(".csv")
      );

      if (validFiles.length === 0) {
        setError("Please upload valid Excel or CSV files (.xlsx, .xls, .csv)");
        return;
      }

      setFiles(validFiles);
    },
    [activeTab]
  );

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: {
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet": [".xlsx"],
      "application/vnd.ms-excel": [".xls"],
      "text/csv": [".csv"],
    },
    multiple: true,
  });

  const resetState = () => {
    setFiles([]);
    setSuccess(false);
    setConvertedData(null);
    setShowInlinePreview(false);
    setValidationIssues([]);
    setConversionStats(null);
    setError(null);
    setMappingInfo(null);
    setUserMappings({});
    setPendingFileData([]);
  };

  const removeFile = (index: number) => {
    setFiles((prev) => prev.filter((_, i) => i !== index));
    setSuccess(false);
    setConvertedData(null);
    setShowInlinePreview(false);
    setValidationIssues([]);
    setConversionStats(null);
  };

  // ── File reader helpers ────────────────────────────────────────────────────
  const readFileAsArrayBuffer = (file: File): Promise<ArrayBuffer> =>
    new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = (e) => resolve(e.target?.result as ArrayBuffer);
      reader.onerror = reject;
      reader.readAsArrayBuffer(file);
    });

  const fileToArray = async (file: File): Promise<any[][]> => {
    const arrayBuffer = await readFileAsArrayBuffer(file);

    if (file.name.toLowerCase().endsWith(".csv")) {
      const text = new TextDecoder().decode(arrayBuffer);
      const csvData = XLSX.read(text, { type: "string" });
      const sheet = csvData.Sheets[csvData.SheetNames[0]];
      return XLSX.utils.sheet_to_json(sheet, { header: 1 }) as any[][];
    } else {
      const workbook = XLSX.read(arrayBuffer, { type: "array" });
      let sheetName = workbook.SheetNames.find((name) =>
        /mix|material|data/i.test(name)
      );
      if (!sheetName) {
        sheetName = workbook.SheetNames[0];
      }
      const worksheet = workbook.Sheets[sheetName];
      return XLSX.utils.sheet_to_json(worksheet, { header: 1 }) as any[][];
    }
  };

  // ── Conversion ─────────────────────────────────────────────────────────────
  const handleConvert = async () => {
    if (files.length === 0) return;

    setIsProcessing(true);
    setError(null);
    setValidationIssues([]);
    setConversionStats(null);

    try {
      let processedRows: any[][] = [];
      let issues: ValidationIssue[] = [];
      let stats = { totalInput: 0, totalOutput: 0, skipped: 0 };

      if (activeTab === "materials") {
        const filePayloads = await Promise.all(
          files.map(async (f) => ({ data: await fileToArray(f), fileName: f.name }))
        );
        // Pre-analyze to detect unmapped columns before converting
        const analysis = preAnalyzeMaterialFile(filePayloads[0].data);
        if (analysis.unmappedCritical.length > 0 || analysis.unmappedImportant.length > 0) {
          setPendingFileData(filePayloads);
          setMappingInfo(analysis);
          setUserMappings({});
          setIsProcessing(false);
          return;
        }
        const result = convertAndMergeMaterials(filePayloads);
        processedRows = result.rows;
        issues = result.issues;
        stats = {
          totalInput: result.totalInputRows,
          totalOutput: result.totalOutputRows,
          skipped: result.skippedRows,
        };
      } else if (activeTab === "mixes") {
        let mixFiles = files;
        let materialsLookup = new Map<string, string>();

        const lastFile = files[files.length - 1];
        const lastIsMaterialsLookup =
          files.length > 1 &&
          /material|mat_lookup|materials/i.test(lastFile.name);

        if (lastIsMaterialsLookup) {
          const lookupData = await fileToArray(lastFile);
          materialsLookup = buildMaterialsLookup(lookupData);
          mixFiles = files.slice(0, -1);
        }

        const filePayloads = await Promise.all(
          mixFiles.map(async (f) => ({ data: await fileToArray(f), fileName: f.name }))
        );
        const result = convertAndMergeMixes(filePayloads, materialsLookup);
        processedRows = result.rows;
        issues = result.issues;
        stats = {
          totalInput: result.totalInputMixes,
          totalOutput: result.totalOutputRows,
          skipped: result.skippedMixes,
        };
      }

      const newWb = XLSX.utils.book_new();
      const newWs = XLSX.utils.aoa_to_sheet(processedRows);
      const sheetName = activeTab === "mixes" ? "Mix Import" : "Material Import";
      XLSX.utils.book_append_sheet(newWb, newWs, sheetName);

      setConvertedData(newWb);
      setOriginalConvertedData(newWb);
      setValidationIssues(issues);
      setConversionStats(stats);
      setSuccess(true);
    } catch (err: any) {
      console.error("Conversion error:", err);
      setError(err.message || "Error processing file(s). Please check the file format.");
    } finally {
      setIsProcessing(false);
    }
  };

  // ── Revalidate against current in-memory (possibly AI-modified) workbook ──
  const handleRevalidate = () => {
    if (!convertedData) return;

    setIsProcessing(true);
    setError(null);

    try {
      // Extract rows from the current workbook (first sheet)
      const sheetName = convertedData.SheetNames[0];
      const ws = convertedData.Sheets[sheetName];
      const rows: any[][] = XLSX.utils.sheet_to_json(ws, { header: 1 }) as any[][];

      if (activeTab === "materials") {
        const result = revalidateMaterialWorkbook(rows);
        setValidationIssues(result.issues);
        // Update stats to reflect the current workbook state
        setConversionStats((prev) => ({
          totalInput: prev?.totalInput ?? result.totalRows,
          totalOutput: result.totalRows,
          skipped: prev?.skipped ?? 0,
        }));
      }
      // Mixes revalidation: for now just clear issues (mixes don't have the same
      // strict SG / duplicate checks — extend here when needed)
    } catch (err: any) {
      console.error("Revalidation error:", err);
      setError(err.message || "Error during revalidation.");
    } finally {
      setIsProcessing(false);
    }
  };

  const handleDownload = () => {
    if (!convertedData) return;
    const wbout = XLSX.write(convertedData, { bookType: "xlsx", type: "array" });
    const blob = new Blob([wbout], { type: "application/octet-stream" });
    const base = activeTab === "mixes" ? "MixImport" : "MaterialImport";
    const prefix = customerName.trim() ? `${customerName.trim()}-` : "";
    saveAs(blob, `${prefix}${base}-Converted.xlsx`);
  };

  const handleDownloadApproved = (approved: ApprovedFile, type: "Material" | "Mix") => {
    const wbout = XLSX.write(approved.workbook, { bookType: "xlsx", type: "array" });
    const blob = new Blob([wbout], { type: "application/octet-stream" });
    const prefix = approved.customerName ? `${approved.customerName}-` : "";
    saveAs(blob, `${prefix}${type}Import-Approved.xlsx`);
  };

  const handleApprove = () => {
    if (!convertedData) return;
    const sheetName = convertedData.SheetNames[0];
    const ws = convertedData.Sheets[sheetName];
    const rows: any[][] = XLSX.utils.sheet_to_json(ws, { header: 1 }) as any[][];
    const rowCount = Math.max(0, rows.length - 1); // exclude header

    const approved: ApprovedFile = {
      workbook: convertedData,
      customerName: customerName.trim() || "Unknown",
      approvedAt: new Date().toLocaleString(),
      rowCount,
    };

    if (activeTab === "materials") {
      setApprovedMaterials(approved);
    } else if (activeTab === "mixes") {
      setApprovedMixes(approved);
    }
    setActiveTab("mix-material");
  };

  // ── Column-mapping confirmation (materials tab, two-phase flow) ───────────
  const handleConfirmMappingAndConvert = async () => {
    if (pendingFileData.length === 0) return;
    setIsProcessing(true);
    setError(null);
    setValidationIssues([]);
    setConversionStats(null);

    try {
      // Strip the skip sentinel before passing overrides
      const overrides: Partial<Record<MaterialFieldKey, string>> = {};
      for (const [k, v] of Object.entries(userMappings)) {
        if (v && v !== "__skip__") overrides[k as MaterialFieldKey] = v;
      }

      const result = convertAndMergeMaterials(pendingFileData, overrides);
      const newWb = XLSX.utils.book_new();
      const newWs = XLSX.utils.aoa_to_sheet(result.rows);
      XLSX.utils.book_append_sheet(newWb, newWs, "Material Import");

      setConvertedData(newWb);
      setOriginalConvertedData(newWb);
      setValidationIssues(result.issues);
      setConversionStats({
        totalInput: result.totalInputRows,
        totalOutput: result.totalOutputRows,
        skipped: result.skippedRows,
      });
      setSuccess(true);
      setMappingInfo(null);
      setPendingFileData([]);
    } catch (err: any) {
      console.error("Conversion error:", err);
      setError(err.message || "Error processing file(s). Please check the file format.");
    } finally {
      setIsProcessing(false);
    }
  };

  // ── Derived counts ─────────────────────────────────────────────────────────
  const errorCount = validationIssues.filter((i) => i.type === "error").length;
  const warnCount = validationIssues.filter((i) => i.type === "warning").length;

  // ── Reusable JSX blocks (not nested components — avoids remount issue) ─────

  // File list shown inside the dropzone (display only, no action buttons)
  const fileListJSX = (
    <>
      <div className="w-14 h-14 rounded-full bg-success/10 flex items-center justify-center text-success">
        <FileSpreadsheet className="h-7 w-7" />
      </div>
      <div className="w-full space-y-2">
        <p className="text-lg font-semibold text-dark">
          {files.length} file{files.length !== 1 ? "s" : ""} selected
        </p>
        {files.map((file, index) => (
          <div
            key={index}
            className="flex items-center justify-between bg-white rounded-lg p-2.5 border border-border"
          >
            <div className="flex items-center gap-3 min-w-0 flex-1">
              <FileSpreadsheet className="h-4 w-4 text-muted-foreground shrink-0" />
              <div className="text-left min-w-0">
                <p className="text-sm font-medium text-dark truncate">{file.name}</p>
                <p className="text-xs text-muted-foreground">
                  {(file.size / 1024).toFixed(2)} KB
                </p>
              </div>
            </div>
            <button
              type="button"
              className="h-8 w-8 flex items-center justify-center rounded text-destructive hover:bg-destructive/10 shrink-0"
              onClick={(e) => {
                e.stopPropagation();
                removeFile(index);
              }}
            >
              <X className="h-4 w-4" />
            </button>
          </div>
        ))}
        {files.length > 1 && (
          <button
            type="button"
            className="text-sm text-destructive hover:underline mt-1"
            onClick={(e) => {
              e.stopPropagation();
              resetState();
            }}
          >
            Remove All Files
          </button>
        )}
      </div>
    </>
  );

  const emptyDropzoneJSX = (
    <>
      <div className="w-14 h-14 rounded-full bg-secondary/10 flex items-center justify-center text-secondary">
        <UploadCloud className="h-7 w-7" />
      </div>
      <div>
        <p className="text-lg font-medium text-dark">Drag & drop your files here</p>
        <p className="text-sm text-muted-foreground mt-1">
          or click to browse from your computer
        </p>
      </div>
      <p className="text-xs text-muted-foreground/70">
        Supported formats: .xlsx, .xls, .csv
      </p>
    </>
  );

  // Error / success banners (rendered outside the dropzone)
  const statusBannerJSX = (
    <>
      {error && (
        <div className="bg-destructive/10 border border-destructive/20 rounded-lg p-3 flex items-start gap-3 text-destructive mt-3">
          <AlertCircle className="h-5 w-5 mt-0.5 shrink-0" />
          <div>
            <p className="font-medium">Error</p>
            <p className="text-sm opacity-90">{error}</p>
          </div>
        </div>
      )}
      {success && (
        <div className="bg-success/10 border border-success/20 rounded-lg p-3 flex items-start gap-3 text-success mt-3">
          <CheckCircle2 className="h-5 w-5 mt-0.5 shrink-0" />
          <div>
            <p className="font-medium">Conversion Successful!</p>
            {conversionStats && (
              <div className="flex flex-wrap gap-4 text-sm mt-1 opacity-90">
                <span><strong>{conversionStats.totalInput}</strong> input rows</span>
                <span><strong>{conversionStats.totalOutput}</strong> output rows</span>
                {conversionStats.skipped > 0 && (
                  <span><strong>{conversionStats.skipped}</strong> skipped</span>
                )}
              </div>
            )}
          </div>
        </div>
      )}
    </>
  );

  // Validation panel (rendered outside the dropzone)
  const validationPanelJSX = validationIssues.length > 0 ? (
    <div className="mt-3 rounded-lg border border-border overflow-hidden">
      <div className="bg-secondary/10 px-4 py-2 flex items-center gap-3 border-b border-border">
        {errorCount > 0 && (
          <span className="flex items-center gap-1.5 text-destructive text-sm font-medium">
            <AlertCircle className="h-4 w-4" />
            {errorCount} error{errorCount !== 1 ? "s" : ""}
          </span>
        )}
        {warnCount > 0 && (
          <span className="flex items-center gap-1.5 text-yellow-600 text-sm font-medium">
            <AlertTriangle className="h-4 w-4" />
            {warnCount} warning{warnCount !== 1 ? "s" : ""}
          </span>
        )}
        <span className="ml-auto text-xs text-muted-foreground">Validation Results</span>
      </div>
      <ul className="max-h-48 overflow-y-auto divide-y divide-border">
        {validationIssues.map((issue, idx) => (
          <li
            key={idx}
            className={cn(
              "px-4 py-2 text-xs flex items-start gap-2",
              issue.type === "error"
                ? "text-destructive bg-destructive/5"
                : "text-yellow-700 bg-yellow-50"
            )}
          >
            {issue.type === "error" ? (
              <AlertCircle className="h-3.5 w-3.5 mt-0.5 shrink-0" />
            ) : (
              <AlertTriangle className="h-3.5 w-3.5 mt-0.5 shrink-0" />
            )}
            <span>{issue.message}</span>
          </li>
        ))}
      </ul>
    </div>
  ) : null;

  // Column-mapping prompt shown when auto-detect misses required fields
  const columnMappingJSX = mappingInfo ? (
    <div className="mt-3 rounded-lg border border-amber-200 bg-amber-50 p-4 space-y-4">
      <div className="flex items-start gap-3">
        <AlertTriangle className="h-5 w-5 text-amber-600 mt-0.5 shrink-0" />
        <div>
          <p className="font-medium text-amber-800">Column Mapping Required</p>
          <p className="text-sm text-amber-700 mt-1">
            Some columns couldn't be automatically detected. Select which column
            in your file corresponds to each field below, then click{" "}
            <strong>Confirm & Convert</strong>.
          </p>
        </div>
      </div>

      {mappingInfo.unmappedCritical.length > 0 && (
        <div className="space-y-3">
          <p className="text-sm font-semibold text-destructive">
            Required Fields — must be mapped to continue
          </p>
          {mappingInfo.unmappedCritical.map((field) => (
            <div key={field} className="grid grid-cols-[1fr_1.5fr] gap-3 items-center">
              <Label className="text-sm font-medium text-dark">
                {MATERIAL_FIELD_LABELS[field]}
                <span className="text-destructive ml-1">*</span>
              </Label>
              <Select
                value={userMappings[field] ?? ""}
                onValueChange={(val) =>
                  setUserMappings((prev) => ({ ...prev, [field]: val }))
                }
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select a column…" />
                </SelectTrigger>
                <SelectContent>
                  {mappingInfo.fileHeaders.filter(Boolean).map((header) => (
                    <SelectItem key={header} value={header}>
                      {header}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          ))}
        </div>
      )}

      {mappingInfo.unmappedImportant.length > 0 && (
        <div className="space-y-3">
          <p className="text-sm font-semibold text-yellow-700">
            Optional Fields — map or skip
          </p>
          {mappingInfo.unmappedImportant.map((field) => (
            <div key={field} className="grid grid-cols-[1fr_1.5fr] gap-3 items-center">
              <Label className="text-sm font-medium text-dark">
                {MATERIAL_FIELD_LABELS[field]}
              </Label>
              <Select
                value={userMappings[field] ?? ""}
                onValueChange={(val) =>
                  setUserMappings((prev) => ({
                    ...prev,
                    [field]: val === "__skip__" ? "" : val,
                  }))
                }
              >
                <SelectTrigger>
                  <SelectValue placeholder="Skip (leave blank)" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="__skip__">— Skip this field —</SelectItem>
                  {mappingInfo.fileHeaders.filter(Boolean).map((header) => (
                    <SelectItem key={header} value={header}>
                      {header}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          ))}
        </div>
      )}

      {Object.keys(mappingInfo.detectedMappings).length > 0 && (
        <div className="text-xs text-muted-foreground border-t border-amber-200 pt-3">
          <p className="font-medium mb-1.5">Auto-detected columns:</p>
          <div className="flex flex-wrap gap-1.5">
            {(Object.entries(mappingInfo.detectedMappings) as [MaterialFieldKey, string][]).map(
              ([field, col]) => (
                <span
                  key={field}
                  className="bg-white border border-border rounded px-2 py-0.5"
                >
                  {MATERIAL_FIELD_LABELS[field]} → <em>{col}</em>
                </span>
              )
            )}
          </div>
        </div>
      )}

      <div className="flex items-center justify-end gap-3 pt-2 border-t border-amber-200">
        <Button variant="outline" onClick={resetState}>
          Cancel
        </Button>
        <Button
          className="bg-primary hover:bg-primary-hover text-white"
          disabled={
            isProcessing ||
            mappingInfo.unmappedCritical.some((f) => !userMappings[f])
          }
          onClick={handleConfirmMappingAndConvert}
        >
          {isProcessing ? (
            <>
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              Converting…
            </>
          ) : (
            "Confirm & Convert"
          )}
        </Button>
      </div>
    </div>
  ) : null;

  // Action buttons (always rendered outside the dropzone)
  const actionButtonsJSX = (
    <div className="flex items-center justify-end gap-3 mt-4">
      {success ? (
        <>
          <Button
            size="lg"
            variant="outline"
            className="border-primary text-primary hover:bg-primary/5 shadow-md hover:shadow-lg transition-all"
            onClick={() => setShowInlinePreview(!showInlinePreview)}
          >
            <Eye className="mr-2 h-5 w-5" />
            {showInlinePreview ? "Hide Preview" : "Preview"}
          </Button>
          <Button
            size="lg"
            variant="outline"
            className="border-yellow-500 text-yellow-600 hover:bg-yellow-50 shadow-md hover:shadow-lg transition-all"
            disabled={isProcessing || !convertedData}
            onClick={handleRevalidate}
          >
            {isProcessing ? (
              <Loader2 className="mr-2 h-5 w-5 animate-spin" />
            ) : (
              <RefreshCw className="mr-2 h-5 w-5" />
            )}
            Revalidate
          </Button>
          <Button
            size="lg"
            variant="outline"
            className="border-success text-success hover:bg-success/5 shadow-md hover:shadow-lg transition-all"
            onClick={handleDownload}
          >
            <Download className="mr-2 h-5 w-5" />
            Download
          </Button>
          <Button
            size="lg"
            className="bg-success hover:bg-success2 text-white shadow-md hover:shadow-lg transition-all"
            onClick={handleApprove}
          >
            <CheckCircle2 className="mr-2 h-5 w-5" />
            Approve & Queue for Upload
          </Button>
        </>
      ) : (
        <Button
          size="lg"
          className={cn(
            "bg-primary hover:bg-primary-hover text-white shadow-md hover:shadow-lg transition-all",
            files.length === 0 && "opacity-50 cursor-not-allowed"
          )}
          disabled={files.length === 0 || isProcessing}
          onClick={handleConvert}
        >
          {isProcessing ? (
            <>
              <Loader2 className="mr-2 h-5 w-5 animate-spin" />
              Processing...
            </>
          ) : (
            "Convert Data"
          )}
        </Button>
      )}
    </div>
  );

  // ── Render ─────────────────────────────────────────────────────────────────
  return (
    <div className="min-h-screen bg-background pb-20">
      {/* Header */}
      <header className="bg-white border-b border-border sticky top-0 z-10">
        <div className="container py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-primary rounded-lg flex items-center justify-center text-white font-bold text-xl shadow-sm">
              iM
            </div>
            <h1 className="text-2xl font-bold text-dark tracking-tight">iMigrate</h1>
          </div>
          <div className="text-sm text-muted-foreground font-medium">
            Data Migration Tool
          </div>
        </div>
      </header>

      <main className="mt-8 px-[5%]">
        <div className="w-full">
          <div className="mb-8 text-center">
            <h2 className="text-3xl font-bold text-dark mb-2">
              Import, Convert, & Upload Data
            </h2>
            <p className="text-muted-foreground">
              Upload exported customer mixes and materials to convert into Quadrel standard import format.
            </p>
          </div>

          <Tabs
            defaultValue="materials"
            value={activeTab}
            onValueChange={(val) => {
              setActiveTab(val);
              resetState();
            }}
            className="w-full"
          >
            <TabsList className="grid w-full grid-cols-3 bg-secondary/20 p-1 rounded-xl mb-6 h-auto">
              <TabsTrigger
                value="materials"
                className="rounded-lg text-base font-medium data-[state=active]:bg-white data-[state=active]:text-primary data-[state=active]:shadow-sm h-8 transition-all"
              >
                Material Conversion
              </TabsTrigger>
              <TabsTrigger
                value="mixes"
                className="rounded-lg text-base font-medium data-[state=active]:bg-white data-[state=active]:text-primary data-[state=active]:shadow-sm h-8 transition-all"
              >
                Mix Conversion
              </TabsTrigger>
              <TabsTrigger
                value="mix-material"
                className="rounded-lg text-base font-medium data-[state=active]:bg-white data-[state=active]:text-primary data-[state=active]:shadow-sm h-8 transition-all"
              >
                Mix & Material Upload
              </TabsTrigger>
            </TabsList>

            {/* ── MATERIALS TAB ─────────────────────────────────────────── */}
            <TabsContent
              value="materials"
              className="space-y-4 animate-in fade-in slide-in-from-bottom-4 duration-500"
            >
              <Card className="border-border shadow-sm overflow-hidden">
                <CardHeader className="bg-secondary/1 border-b border-border pb-4">
                  <div className="flex flex-col lg:flex-row lg:items-start lg:justify-between gap-4">
                    <div className="flex-1">
                      <CardTitle className="text-xl text-secondary mb-1">
                        Material Conversion
                      </CardTitle>
                      <CardDescription>
                        Upload one or more material files. All files will be merged into a single output.
                      </CardDescription>
                    </div>
                    <div className="flex gap-2">
                      <input
                        type="file"
                        id="file-upload-materials"
                        className="hidden"
                        accept=".xlsx,.xls,.csv"
                        multiple
                        onChange={(e) => {
                          if (e.target.files && e.target.files.length > 0) {
                            onDrop(Array.from(e.target.files));
                          }
                        }}
                      />
                      <Button
                        variant="outline"
                        className="border-primary text-primary hover:bg-primary/5 hover:text-primary-hover"
                        onClick={() =>
                          document.getElementById("file-upload-materials")?.click()
                        }
                      >
                        <Upload className="mr-2 h-4 w-4" />
                        Select Files
                      </Button>
                    </div>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-3 mt-4 pt-4 border-t border-border">
                    <div className="space-y-1.5">
                      <label className="text-sm font-medium text-dark">Customer Name</label>
                      <Input
                        type="text"
                        placeholder="Enter customer name (optional)"
                        value={customerName}
                        onChange={(e) => setCustomerName(e.target.value.slice(0, 16))}
                        maxLength={16}
                        className="w-full h-10 text-base"
                      />
                      <p className="text-xs text-muted-foreground">
                        Max 16 characters. Will be added to output filename.
                      </p>
                    </div>
                  </div>
                </CardHeader>

                <CardContent className="pt-4 space-y-2">
                  {/* Dropzone — display only, no action buttons inside */}
                  <div
                    {...getRootProps()}
                    className={cn(
                      "border-2 border-dashed rounded-xl p-8 text-center cursor-pointer transition-all duration-200 flex flex-col items-center justify-center gap-3 min-h-[180px]",
                      isDragActive
                        ? "border-primary bg-primary/5 scale-[0.99]"
                        : "border-border hover:border-primary/50 hover:bg-secondary/5",
                      files.length > 0 ? "bg-secondary/5 border-secondary/30" : ""
                    )}
                  >
                    <input {...getInputProps()} />
                    {files.length > 0 ? fileListJSX : emptyDropzoneJSX}
                  </div>

                  {/* Status banners, validation panel, and action buttons are OUTSIDE the dropzone */}
                  {statusBannerJSX}
                  {validationPanelJSX}
                  {mappingInfo && !success ? columnMappingJSX : actionButtonsJSX}
                </CardContent>
              </Card>

              {success && showInlinePreview && (
                <PreviewSection
                  workbook={convertedData}
                  title="Material Import Preview"
                  onClose={() => setShowInlinePreview(false)}
                  onDataChange={(wb) => setConvertedData(wb)}
                >
                  <AIModificationPanel
                    workbook={convertedData}
                    originalWorkbook={originalConvertedData}
                    onModify={(wb) => setConvertedData(wb)}
                    onRevert={() => setConvertedData(originalConvertedData)}
                  />
                </PreviewSection>
              )}
            </TabsContent>

            {/* ── MIXES TAB ─────────────────────────────────────────────── */}
            <TabsContent
              value="mixes"
              className="space-y-4 animate-in fade-in slide-in-from-bottom-4 duration-500"
            >
              <Card className="border-border shadow-sm overflow-hidden">
                <CardHeader className="bg-secondary/1 border-b border-border pb-4">
                  <div className="flex flex-col lg:flex-row lg:items-start lg:justify-between gap-4">
                    <div className="flex-1">
                      <CardTitle className="text-xl text-secondary mb-1">
                        Mix Conversion
                      </CardTitle>
                      <CardDescription>
                        Upload one or more mix files. Optionally include a materials lookup file
                        (name it with "material" in the filename) as the last file to resolve
                        constituent item codes.
                      </CardDescription>
                    </div>
                    <div className="flex gap-2">
                      <input
                        type="file"
                        id="file-upload-mixes"
                        className="hidden"
                        accept=".xlsx,.xls,.csv"
                        multiple
                        onChange={(e) => {
                          if (e.target.files && e.target.files.length > 0) {
                            onDrop(Array.from(e.target.files));
                          }
                        }}
                      />
                      <Button
                        variant="outline"
                        className="border-primary text-primary hover:bg-primary/5 hover:text-primary-hover"
                        onClick={() =>
                          document.getElementById("file-upload-mixes")?.click()
                        }
                      >
                        <Upload className="mr-2 h-4 w-4" />
                        Select Files
                      </Button>
                    </div>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-3 mt-4 pt-4 border-t border-border">
                    <div className="space-y-1.5">
                      <label className="text-sm font-medium text-dark">Customer Name</label>
                      <Input
                        type="text"
                        placeholder="Enter customer name (optional)"
                        value={customerName}
                        onChange={(e) => setCustomerName(e.target.value.slice(0, 16))}
                        maxLength={16}
                        className="w-full h-10 text-base"
                      />
                      <p className="text-xs text-muted-foreground">
                        Max 16 characters. Will be added to output filename.
                      </p>
                    </div>
                  </div>
                </CardHeader>

                <CardContent className="pt-4 space-y-2">
                  <div
                    {...getRootProps()}
                    className={cn(
                      "border-2 border-dashed rounded-xl p-8 text-center cursor-pointer transition-all duration-200 flex flex-col items-center justify-center gap-3 min-h-[180px]",
                      isDragActive
                        ? "border-primary bg-primary/5 scale-[0.99]"
                        : "border-border hover:border-primary/50 hover:bg-secondary/5",
                      files.length > 0 ? "bg-secondary/5 border-secondary/30" : ""
                    )}
                  >
                    <input {...getInputProps()} />
                    {files.length > 0 ? fileListJSX : emptyDropzoneJSX}
                  </div>

                  {statusBannerJSX}
                  {validationPanelJSX}

                  {/* AI-assisted conversion flow for mixes */}
                  {success ? (
                    <div className="flex items-center justify-end gap-3 mt-4">
                      <Button
                        size="lg"
                        variant="outline"
                        className="border-primary text-primary hover:bg-primary/5 shadow-md hover:shadow-lg transition-all"
                        onClick={() => setShowInlinePreview(!showInlinePreview)}
                      >
                        <Eye className="mr-2 h-5 w-5" />
                        {showInlinePreview ? "Hide Preview" : "Preview"}
                      </Button>
                      <Button
                        size="lg"
                        variant="outline"
                        className="border-success text-success hover:bg-success/5 shadow-md hover:shadow-lg transition-all"
                        onClick={handleDownload}
                      >
                        <Download className="mr-2 h-5 w-5" />
                        Download
                      </Button>
                      <Button
                        size="lg"
                        className="bg-success hover:bg-success2 text-white shadow-md hover:shadow-lg transition-all"
                        onClick={handleApprove}
                      >
                        <CheckCircle2 className="mr-2 h-5 w-5" />
                        Approve & Queue for Upload
                      </Button>
                    </div>
                  ) : (
                    <AIMixConversionPanel
                      files={files}
                      fileToArray={fileToArray}
                      onConversionComplete={(wb, issues, stats) => {
                        setConvertedData(wb);
                        setOriginalConvertedData(wb);
                        setValidationIssues(issues);
                        setConversionStats(stats);
                        setSuccess(true);
                      }}
                      onError={setError}
                    />
                  )}
                </CardContent>
              </Card>

              {success && showInlinePreview && (
                <PreviewSection
                  workbook={convertedData}
                  title="Mix Import Preview"
                  onClose={() => setShowInlinePreview(false)}
                  onDataChange={(wb) => setConvertedData(wb)}
                >
                  <AIModificationPanel
                    workbook={convertedData}
                    originalWorkbook={originalConvertedData}
                    onModify={(wb) => setConvertedData(wb)}
                    onRevert={() => setConvertedData(originalConvertedData)}
                  />
                </PreviewSection>
              )}
            </TabsContent>

            {/* ── MIX & MATERIAL UPLOAD TAB ─────────────────────────────── */}
            <TabsContent
              value="mix-material"
              className="space-y-4 animate-in fade-in slide-in-from-bottom-4 duration-500"
            >
              {/* Materials queue */}
              <Card className="border-border shadow-sm overflow-hidden">
                <CardHeader className="bg-secondary/1 border-b border-border pb-4">
                  <div className="flex items-center justify-between">
                    <div>
                      <CardTitle className="text-xl text-secondary mb-1">Approved Materials</CardTitle>
                      <CardDescription>
                        Material file approved and ready for database upload.
                      </CardDescription>
                    </div>
                    {approvedMaterials && (
                      <Button
                        variant="outline"
                        size="sm"
                        className="text-destructive border-destructive/30 hover:bg-destructive/5"
                        onClick={() => setApprovedMaterials(null)}
                      >
                        <X className="h-4 w-4 mr-1" /> Clear
                      </Button>
                    )}
                  </div>
                </CardHeader>
                <CardContent className="pt-4">
                  {approvedMaterials ? (
                    <div className="flex items-center justify-between bg-success/5 border border-success/20 rounded-lg p-4">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-full bg-success/10 flex items-center justify-center text-success">
                          <CheckCircle2 className="h-5 w-5" />
                        </div>
                        <div>
                          <p className="font-semibold text-dark">{approvedMaterials.customerName}</p>
                          <p className="text-sm text-muted-foreground">
                            {approvedMaterials.rowCount} material{approvedMaterials.rowCount !== 1 ? "s" : ""} · Approved {approvedMaterials.approvedAt}
                          </p>
                        </div>
                      </div>
                      <Button
                        variant="outline"
                        className="border-primary text-primary hover:bg-primary/5"
                        onClick={() => handleDownloadApproved(approvedMaterials, "Material")}
                      >
                        <Download className="mr-2 h-4 w-4" />
                        Download for Upload
                      </Button>
                    </div>
                  ) : (
                    <div className="text-center py-8 text-muted-foreground">
                      <FileSpreadsheet className="h-8 w-8 mx-auto mb-2 opacity-40" />
                      <p className="text-sm">No approved materials yet. Convert and approve a material file first.</p>
                    </div>
                  )}
                </CardContent>
              </Card>

              {/* Mixes queue */}
              <Card className="border-border shadow-sm overflow-hidden">
                <CardHeader className="bg-secondary/1 border-b border-border pb-4">
                  <div className="flex items-center justify-between">
                    <div>
                      <CardTitle className="text-xl text-secondary mb-1">Approved Mixes</CardTitle>
                      <CardDescription>
                        Mix file approved and ready for database upload.
                      </CardDescription>
                    </div>
                    {approvedMixes && (
                      <Button
                        variant="outline"
                        size="sm"
                        className="text-destructive border-destructive/30 hover:bg-destructive/5"
                        onClick={() => setApprovedMixes(null)}
                      >
                        <X className="h-4 w-4 mr-1" /> Clear
                      </Button>
                    )}
                  </div>
                </CardHeader>
                <CardContent className="pt-4">
                  {approvedMixes ? (
                    <div className="flex items-center justify-between bg-success/5 border border-success/20 rounded-lg p-4">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-full bg-success/10 flex items-center justify-center text-success">
                          <CheckCircle2 className="h-5 w-5" />
                        </div>
                        <div>
                          <p className="font-semibold text-dark">{approvedMixes.customerName}</p>
                          <p className="text-sm text-muted-foreground">
                            {approvedMixes.rowCount} row{approvedMixes.rowCount !== 1 ? "s" : ""} · Approved {approvedMixes.approvedAt}
                          </p>
                        </div>
                      </div>
                      <Button
                        variant="outline"
                        className="border-primary text-primary hover:bg-primary/5"
                        onClick={() => handleDownloadApproved(approvedMixes, "Mix")}
                      >
                        <Download className="mr-2 h-4 w-4" />
                        Download for Upload
                      </Button>
                    </div>
                  ) : (
                    <div className="text-center py-8 text-muted-foreground">
                      <FileSpreadsheet className="h-8 w-8 mx-auto mb-2 opacity-40" />
                      <p className="text-sm">No approved mixes yet. Convert and approve a mix file first.</p>
                    </div>
                  )}
                </CardContent>
              </Card>

              {(approvedMaterials || approvedMixes) && (
                <div className="bg-primary/5 border border-primary/20 rounded-lg p-4 text-sm text-dark">
                  <p className="font-medium mb-1">Ready for Upload</p>
                  <p className="text-muted-foreground">
                    Download the approved files above and import them into the Quadrel database using the standard import process. Direct database upload is coming soon.
                  </p>
                </div>
              )}
            </TabsContent>
          </Tabs>
        </div>
      </main>
    </div>
  );
}