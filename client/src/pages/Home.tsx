import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { cn } from "@/lib/utils";
import { AlertCircle, CheckCircle2, Download, Eye, FileSpreadsheet, Loader2, Upload, UploadCloud, X } from "lucide-react";
import { PreviewSection } from "@/components/PreviewSection";
import { AIModificationPanel } from "@/components/AIModificationPanel";
import { useCallback, useState } from "react";
import { useDropzone } from "react-dropzone";
import * as XLSX from "xlsx";
import { saveAs } from "file-saver";
import { convertMPAQMaterials, convertMPAQMaterialsMultiSheet } from "../converters/materials/MPAQ";
import { convertMPAQMixes } from "../converters/mixes/MPAQ";

// Dispatch system options
const DISPATCH_OPTIONS = [
  "BCMI", 
  "Command Cloud", 
  "Command Series", 
  "Integra", 
  "Jonel", 
  "MPAQ",
  "Simma", 
  "SysDyne", 
  "WMC"
];

export default function Home() {
  const [activeTab, setActiveTab] = useState("materials");
  const [selectedDispatch, setSelectedDispatch] = useState<string>("");
  const [customerName, setCustomerName] = useState<string>("");
  const [files, setFiles] = useState<File[]>([]); // Changed from single file to array
  const [isProcessing, setIsProcessing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const [convertedData, setConvertedData] = useState<any>(null);
  const [originalConvertedData, setOriginalConvertedData] = useState<any>(null);
  const [showInlinePreview, setShowInlinePreview] = useState(false);

  // File drop handler - supports multiple files
  const onDrop = useCallback((acceptedFiles: File[]) => {
    setError(null);
    setSuccess(false);
    setConvertedData(null);
    setShowInlinePreview(false);
    
    // Filter valid files
    const validFiles = acceptedFiles.filter(file => 
      file.name.endsWith('.xlsx') || 
      file.name.endsWith('.xls') || 
      file.name.endsWith('.csv')
    );
    
    if (validFiles.length === 0) {
      setError("Please upload valid Excel or CSV files (.xlsx, .xls, .csv)");
      return;
    }
    
    // For mixes tab, allow 1-2 files (2 for MPAQ: mix file + materials lookup)
    if (activeTab === "mixes" && validFiles.length > 2) {
      setError("Mix imports support up to 2 files (mix file + materials lookup for MPAQ)");
      setFiles(validFiles.slice(0, 2));
      return;
    }
    
    // For materials tab, allow up to 5 files
    if (activeTab === "materials" && validFiles.length > 5) {
      setError("Maximum 5 files allowed");
      setFiles(validFiles.slice(0, 5));
      return;
    }
    
    setFiles(validFiles);
  }, [activeTab]);

  const { getRootProps, getInputProps, isDragActive } = useDropzone({ 
    onDrop,
    accept: {
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': ['.xlsx'],
      'application/vnd.ms-excel': ['.xls'],
      'text/csv': ['.csv']
    },
    maxFiles: activeTab === "mixes" ? 2 : 5,
    multiple: true
  });

  // Remove a specific file
  const removeFile = (index: number) => {
    setFiles(prev => prev.filter((_, i) => i !== index));
    setSuccess(false);
    setConvertedData(null);
    setShowInlinePreview(false);
  };

  // Helper function to read a file as array buffer
  const readFileAsArrayBuffer = (file: File): Promise<ArrayBuffer> => {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = (e) => resolve(e.target?.result as ArrayBuffer);
      reader.onerror = reject;
      reader.readAsArrayBuffer(file);
    });
  };

  // Helper function to convert file to 2D array
  const fileToArray = async (file: File): Promise<any[][]> => {
    const arrayBuffer = await readFileAsArrayBuffer(file);
    
    if (file.name.toLowerCase().endsWith(".csv")) {
      const text = new TextDecoder().decode(arrayBuffer);
      const csvData = XLSX.read(text, { type: "string" });
      const sheet = csvData.Sheets[csvData.SheetNames[0]];
      return XLSX.utils.sheet_to_json(sheet, { header: 1 }) as any[][];
    } else {
      const workbook = XLSX.read(arrayBuffer, { type: 'array' });
      // Try to find the data sheet
      let sheetName = workbook.SheetNames.find(name => 
        name.toLowerCase().includes('mix') || 
        name.toLowerCase().includes('material') ||
        name.toLowerCase().includes('data')
      );
      if (!sheetName) {
        sheetName = workbook.SheetNames.length > 1 ? workbook.SheetNames[1] : workbook.SheetNames[0];
      }
      const worksheet = workbook.Sheets[sheetName];
      return XLSX.utils.sheet_to_json(worksheet, { header: 1 }) as any[][];
    }
  };

  // Conversion logic
  const handleConvert = async () => {
    if (files.length === 0 || !selectedDispatch) return;
    
    setIsProcessing(true);
    setError(null);

    try {
      let processedData: any[][] = [];

      if (activeTab === "mixes") {
        // Mixes: MPAQ requires 2 files (mix + materials lookup)
        if (selectedDispatch === "MPAQ") {
          if (files.length < 2) {
            throw new Error("MPAQ mix conversion requires 2 files: mix file and materials lookup file");
          }
          // Load both files
          const mixData = await fileToArray(files[0]);
          const materialsData = await fileToArray(files[1]);
          console.log("Mix data loaded:", mixData.length, "rows");
          console.log("Materials data loaded:", materialsData.length, "rows");
          processedData = convertMPAQMixes(mixData, materialsData);
        } else {
          // Other dispatch systems: single file (fallback)
          const jsonData = await fileToArray(files[0]);
          console.log("Mix data loaded:", jsonData.length, "rows");
          // For non-MPAQ systems, use old converter logic or throw error
          throw new Error(`Mix conversion for ${selectedDispatch} is not yet implemented. Please use MPAQ.`);
        }
        
      } else if (activeTab === "materials") {
        // Materials: can handle 1-5 files
        if (files.length === 1) {
          // Single file - could be combined or single material type
          const jsonData = await fileToArray(files[0]);
          console.log("Material data loaded:", jsonData.length, "rows");
          processedData = convertMPAQMaterials(jsonData);
          
        } else {
          // Multiple files - treat as separate material types
          console.log(`Processing ${files.length} material files...`);
          
          // Read all files
          const fileDataPromises = files.map(file => fileToArray(file));
          const allFileData = await Promise.all(fileDataPromises);
          
          // Try to identify which file is which based on filename
          let admixData: any[][] | null = null;
          let aggregateData: any[][] | null = null;
          let cementData: any[][] | null = null;
          
          files.forEach((file, index) => {
            const fileName = file.name.toLowerCase();
            const data = allFileData[index];
            
            if (fileName.includes('admix') || fileName.includes('fiber')) {
              admixData = data;
              console.log("Identified admix file:", file.name);
            } else if (fileName.includes('aggregate') || fileName.includes('agg')) {
              aggregateData = data;
              console.log("Identified aggregate file:", file.name);
            } else if (fileName.includes('cement') || fileName.includes('cem')) {
              cementData = data;
              console.log("Identified cement file:", file.name);
            } else {
              // If we can't identify by name, assign in order
              if (!admixData) {
                admixData = data;
                console.log("Assigned to admix (by order):", file.name);
              } else if (!aggregateData) {
                aggregateData = data;
                console.log("Assigned to aggregate (by order):", file.name);
              } else if (!cementData) {
                cementData = data;
                console.log("Assigned to cement (by order):", file.name);
              }
            }
          });
          
          processedData = convertMPAQMaterialsMultiSheet(admixData, aggregateData, cementData);
        }
      }

      // Create workbook for export
      const newWb = XLSX.utils.book_new();
      const newWs = XLSX.utils.aoa_to_sheet(processedData);
      const outputSheetName = activeTab === "mixes" ? "Mix Import" : "Material Import";
      XLSX.utils.book_append_sheet(newWb, newWs, outputSheetName);
      
      setConvertedData(newWb);
      setOriginalConvertedData(newWb); // Save original for revert
      setSuccess(true);
      
    } catch (err: any) {
      console.error("Conversion error:", err);
      setError(err.message || "Error processing file(s). Please check the file format.");
    } finally {
      setIsProcessing(false);
    }
  };

  const handleDownload = () => {
    if (!convertedData) return;
    
    const wbout = XLSX.write(convertedData, { bookType: 'xlsx', type: 'array' });
    const blob = new Blob([wbout], { type: 'application/octet-stream' });
    
    // Build filename with customer name if provided
    const baseFilename = activeTab === "mixes" ? 'MixImport' : 'MaterialImport';
    const customerPrefix = customerName.trim() ? `${customerName.trim()}-` : '';
    const filename = `${customerPrefix}${baseFilename}-Converted.xlsx`;
    
    saveAs(blob, filename);
  };

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

      <main className="container mt-8">
        <div className="max-w-7xl mx-auto">
          <div className="mb-8 text-center">
            <h2 className="text-3xl font-bold text-dark mb-2">Import, Convert, & Upload Data</h2>
            <p className="text-muted-foreground">
              Upload exported customer mixes and materials to convert into Quadrel standard import format.
            </p>
          </div>

          <Tabs defaultValue="materials" value={activeTab} onValueChange={(val) => {
            setActiveTab(val);
            setFiles([]); // Clear files when switching tabs
            setError(null);
            setSuccess(false);
            setConvertedData(null);
            setShowInlinePreview(false);
          }} className="w-full">
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

            <TabsContent value="mixes" className="space-y-4 animate-in fade-in slide-in-from-bottom-4 duration-500">
              <Card className="border-border shadow-sm overflow-hidden">
                <CardHeader className="bg-secondary/1 border-b border-border pb-4">
                  <div className="flex flex-col lg:flex-row lg:items-start lg:justify-between gap-4">
                    <div className="flex-1">
                      <CardTitle className="text-xl text-secondary mb-1">Mix Conversion</CardTitle>
                      <CardDescription>Upload 2 files for MPAQ: mix file and materials lookup file.</CardDescription>
                    </div>
                    
                    <div className="flex gap-2">
                      <input
                        type="file"
                        id="file-upload"
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
                        onClick={() => document.getElementById('file-upload')?.click()}
                      >
                        <Upload className="mr-2 h-4 w-4" />
                        Select Files
                      </Button>
                    </div>
                  </div>
                  
                  {/* Configuration Fields */}
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
                      <p className="text-xs text-muted-foreground">Max 16 characters. Will be added to output filename.</p>
                    </div>
                    <div className="space-y-1.5">
                      <label className="text-sm font-medium text-dark">Dispatch System</label>
                      <Select value={selectedDispatch} onValueChange={setSelectedDispatch}>
                        <SelectTrigger className="w-full h-10 text-base bg-white border-border focus:ring-primary/20">
                          <SelectValue placeholder="Select Dispatch System" />
                        </SelectTrigger>
                        <SelectContent>
                          {DISPATCH_OPTIONS.map((option) => (
                            <SelectItem 
                              key={option} 
                              value={option}
                              disabled={option !== "MPAQ"}
                              className="cursor-pointer py-3"
                            >
                              <span className={cn(option !== "MPAQ" && "opacity-50")}>
                                {option} {option !== "MPAQ" && "(Coming Soon)"}
                              </span>
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    </div>
                  </div>
                </CardHeader>
                
                <CardContent className="pt-4 space-y-4">
                  <div 
                    {...getRootProps()} 
                    className={cn(
                      "border-2 border-dashed rounded-xl p-8 text-center cursor-pointer transition-all duration-200 flex flex-col items-center justify-center gap-3 min-h-[180px]",
                      isDragActive ? "border-primary bg-primary/5 scale-[0.99]" : "border-border hover:border-primary/50 hover:bg-secondary/5",
                      files.length > 0 ? "bg-secondary/5 border-secondary/30" : ""
                    )}
                  >
                    <input {...getInputProps()} />
                    
                    {files.length > 0 ? (
                      <>
                        <div className="w-14 h-14 rounded-full bg-success/10 flex items-center justify-center text-success">
                          <FileSpreadsheet className="h-7 w-7" />
                        </div>
                        <div className="w-full space-y-2">
                          <p className="text-lg font-medium text-dark">{files.length} file{files.length > 1 ? 's' : ''} selected</p>
                          <div className="space-y-2">
                            {files.map((file, index) => (
                              <div key={index} className="flex items-center justify-between bg-white rounded-lg p-2 border border-border">
                                <div className="flex items-center gap-2 flex-1 min-w-0">
                                  <FileSpreadsheet className="h-4 w-4 text-secondary shrink-0" />
                                  <div className="min-w-0 flex-1">
                                    <p className="text-sm font-medium text-dark truncate">{file.name}</p>
                                    <p className="text-xs text-muted-foreground">{(file.size / 1024).toFixed(2)} KB</p>
                                  </div>
                                </div>
                                <Button 
                                  variant="ghost" 
                                  size="sm" 
                                  className="text-destructive hover:text-destructive hover:bg-destructive/10 h-8 w-8 p-0 shrink-0"
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    removeFile(index);
                                  }}
                                >
                                  <X className="h-4 w-4" />
                                </Button>
                              </div>
                            ))}
                          </div>
                        </div>
                        <Button 
                          variant="ghost" 
                          size="sm" 
                          className="text-destructive hover:text-destructive hover:bg-destructive/10"
                          onClick={(e) => {
                            e.stopPropagation();
                            setFiles([]);
                            setSuccess(false);
                            setConvertedData(null);
                          }}
                        >
                          Remove All Files
                        </Button>
                      </>
                    ) : (
                      <>
                        <div className="w-14 h-14 rounded-full bg-secondary/10 flex items-center justify-center text-secondary">
                          <UploadCloud className="h-7 w-7" />
                        </div>
                        <div>
                          <p className="text-lg font-medium text-dark">Drag & drop your files here</p>
                          <p className="text-sm text-muted-foreground mt-1">or click to browse (select up to 2 files for MPAQ)</p>
                        </div>
                        <p className="text-xs text-muted-foreground/70">Supported formats: .xlsx, .xls, .csv</p>
                      </>
                    )}
                    
                    {error && (
                      <div className="bg-destructive/10 border border-destructive/20 rounded-lg p-3 flex items-start gap-3 text-destructive animate-in fade-in slide-in-from-top-2 mt-2 w-full">
                        <AlertCircle className="h-5 w-5 mt-0.5 shrink-0" />
                        <div>
                          <p className="font-medium">Error</p>
                          <p className="text-sm opacity-90">{error}</p>
                        </div>
                      </div>
                    )}

                    {success && (
                      <div className="bg-success/10 border border-success/20 rounded-lg p-3 flex items-start gap-3 text-success animate-in fade-in slide-in-from-top-2 mt-2 w-full">
                        <CheckCircle2 className="h-5 w-5 mt-0.5 shrink-0" />
                        <div>
                          <p className="font-medium">Conversion Successful!</p>
                          <p className="text-sm opacity-90">Your file has been processed and is ready for download.</p>
                        </div>
                      </div>
                    )}

                    <div className="flex items-center justify-end gap-3 pt-3 mt-2 w-full">
                    {success ? (
                      <>
                        <Button 
                          size="lg" 
                          variant="outline"
                          className="border-primary text-primary hover:bg-primary/5 shadow-md hover:shadow-lg transition-all"
                          onClick={(e) => {
                            e.stopPropagation();
                            setShowInlinePreview(!showInlinePreview);
                          }}
                        >
                          <Eye className="mr-2 h-5 w-5" />
                          {showInlinePreview ? 'Hide Preview' : 'Preview'}
                        </Button>
                        <Button 
                          size="lg" 
                          className="bg-success hover:bg-success2 text-white shadow-md hover:shadow-lg transition-all w-full sm:w-auto"
                          onClick={(e) => {
                            e.stopPropagation();
                            handleDownload();
                          }}
                        >
                          <Download className="mr-2 h-5 w-5" />
                          Download Converted File
                        </Button>
                      </>
                    ) : (
                      <Button 
                        size="lg" 
                        className={cn(
                          "bg-primary hover:bg-primary-hover text-white shadow-md hover:shadow-lg transition-all w-full sm:w-auto",
                          (files.length === 0 || !selectedDispatch) && "opacity-50 cursor-not-allowed"
                        )}
                        disabled={files.length === 0 || !selectedDispatch || isProcessing}
                        onClick={(e) => {
                          e.stopPropagation();
                          handleConvert();
                        }}
                      >
                        {isProcessing ? (
                          <>
                            <Loader2 className="mr-2 h-5 w-5 animate-spin" />
                            Processing...
                          </>
                        ) : (
                          <>
                            Convert Data
                          </>
                        )}
                      </Button>
                    )}
                    </div>
                  </div>
                </CardContent>
              </Card>
              
              {/* Inline Preview Section */}
              {success && showInlinePreview && (
                <PreviewSection
                  workbook={convertedData}
                  title="Mix Import Preview"
                  onClose={() => setShowInlinePreview(false)}
                  onDataChange={(modifiedWorkbook) => setConvertedData(modifiedWorkbook)}
                >
                  <AIModificationPanel
                    workbook={convertedData}
                    originalWorkbook={originalConvertedData}
                    onModify={(modifiedWorkbook) => setConvertedData(modifiedWorkbook)}
                    onRevert={() => setConvertedData(originalConvertedData)}
                  />
                </PreviewSection>
              )}
            </TabsContent>
            
            <TabsContent value="materials" className="space-y-4 animate-in fade-in slide-in-from-bottom-4 duration-500">
              <Card className="border-border shadow-sm overflow-hidden">
                <CardHeader className="bg-secondary/1 border-b border-border pb-4">
                  <div className="flex flex-col lg:flex-row lg:items-start lg:justify-between gap-4">
                    <div className="flex-1">
                      <CardTitle className="text-xl text-secondary mb-1">Material Conversion</CardTitle>
                      <CardDescription>Upload material files (up to 5).</CardDescription>
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
                        onClick={() => document.getElementById('file-upload-materials')?.click()}
                      >
                        <Upload className="mr-2 h-4 w-4" />
                        Select Files
                      </Button>
                    </div>
                  </div>
                  
                  {/* Configuration Fields */}
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
                      <p className="text-xs text-muted-foreground">Max 16 characters. Will be added to output filename.</p>
                    </div>
                    <div className="space-y-1.5">
                      <label className="text-sm font-medium text-dark">Dispatch System</label>
                      <Select value={selectedDispatch} onValueChange={setSelectedDispatch}>
                        <SelectTrigger className="w-full h-10 text-base bg-white border-border focus:ring-primary/20">
                          <SelectValue placeholder="Select Dispatch System" />
                        </SelectTrigger>
                        <SelectContent>
                          {DISPATCH_OPTIONS.map((option) => (
                            <SelectItem 
                              key={option} 
                              value={option}
                              disabled={option !== "MPAQ"}
                              className="cursor-pointer py-3"
                            >
                              <span className={cn(option !== "MPAQ" && "opacity-50")}>
                                {option} {option !== "MPAQ" && "(Coming Soon)"}
                              </span>
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    </div>
                  </div>
                </CardHeader>
                
                <CardContent className="pt-4 space-y-4">
                  <div 
                    {...getRootProps()} 
                    className={cn(
                      "border-2 border-dashed rounded-xl p-8 text-center cursor-pointer transition-all duration-200 flex flex-col items-center justify-center gap-3 min-h-[180px]",
                      isDragActive ? "border-primary bg-primary/5 scale-[0.99]" : "border-border hover:border-primary/50 hover:bg-secondary/5",
                      files.length > 0 ? "bg-secondary/5 border-secondary/30" : ""
                    )}
                  >
                    <input {...getInputProps()} />
                    
                    {files.length > 0 ? (
                      <>
                        <div className="w-14 h-14 rounded-full bg-success/10 flex items-center justify-center text-success">
                          <FileSpreadsheet className="h-7 w-7" />
                        </div>
                        <div className="w-full space-y-2">
                          <p className="text-lg font-semibold text-dark">{files.length} file(s) selected</p>
                          {files.map((file, index) => (
                            <div key={index} className="flex items-center justify-between bg-white rounded-lg p-2.5 border border-border">
                              <div className="flex items-center gap-3">
                                <FileSpreadsheet className="h-4 w-4 text-muted-foreground" />
                                <div className="text-left">
                                  <p className="text-sm font-medium text-dark">{file.name}</p>
                                  <p className="text-xs text-muted-foreground">{(file.size / 1024).toFixed(2)} KB</p>
                                </div>
                              </div>
                              <Button
                                variant="ghost"
                                size="sm"
                                className="h-8 w-8 p-0 text-destructive hover:text-destructive hover:bg-destructive/10"
                                onClick={(e) => {
                                  e.stopPropagation();
                                  removeFile(index);
                                }}
                              >
                                <X className="h-4 w-4" />
                              </Button>
                            </div>
                          ))}
                        </div>
                      </>
                    ) : (
                      <>
                        <div className="w-14 h-14 rounded-full bg-secondary/10 flex items-center justify-center text-secondary">
                          <UploadCloud className="h-7 w-7" />
                        </div>
                        <div>
                          <p className="text-lg font-medium text-dark">Drag & drop your files here</p>
                          <p className="text-sm text-muted-foreground mt-1">or click to browse from your computer</p>
                        </div>
                        <p className="text-xs text-muted-foreground/70">
                          Supported formats: .xlsx, .xls, .csv • Maximum 5 files
                        </p>
                      </>
                    )}
                    
                    {error && (
                      <div className="bg-destructive/10 border border-destructive/20 rounded-lg p-3 flex items-start gap-3 text-destructive animate-in fade-in slide-in-from-top-2 mt-2 w-full">
                        <AlertCircle className="h-5 w-5 mt-0.5 shrink-0" />
                        <div>
                          <p className="font-medium">Error</p>
                          <p className="text-sm opacity-90">{error}</p>
                        </div>
                      </div>
                    )}

                    {success && (
                      <div className="bg-success/10 border border-success/20 rounded-lg p-3 flex items-start gap-3 text-success animate-in fade-in slide-in-from-top-2 mt-2 w-full">
                        <CheckCircle2 className="h-5 w-5 mt-0.5 shrink-0" />
                        <div>
                          <p className="font-medium">Conversion Successful!</p>
                          <p className="text-sm opacity-90">Your files have been processed and are ready for download.</p>
                        </div>
                      </div>
                    )}

                    <div className="flex items-center justify-end gap-3 pt-3 mt-2 w-full">
                    {success ? (
                      <>
                        <Button 
                          size="lg" 
                          variant="outline"
                          className="border-primary text-primary hover:bg-primary/5 shadow-md hover:shadow-lg transition-all"
                          onClick={(e) => {
                            e.stopPropagation();
                            setShowInlinePreview(!showInlinePreview);
                          }}
                        >
                          <Eye className="mr-2 h-5 w-5" />
                          {showInlinePreview ? 'Hide Preview' : 'Preview'}
                        </Button>
                        <Button 
                          size="lg" 
                          className="bg-success hover:bg-success2 text-white shadow-md hover:shadow-lg transition-all w-full sm:w-auto"
                          onClick={(e) => {
                            e.stopPropagation();
                            handleDownload();
                          }}
                        >
                          <Download className="mr-2 h-5 w-5" />
                          Download Converted File
                        </Button>
                      </>
                    ) : (
                      <Button 
                        size="lg" 
                        className={cn(
                          "bg-primary hover:bg-primary-hover text-white shadow-md hover:shadow-lg transition-all w-full sm:w-auto",
                          (files.length === 0 || !selectedDispatch) && "opacity-50 cursor-not-allowed"
                        )}
                        disabled={files.length === 0 || !selectedDispatch || isProcessing}
                        onClick={(e) => {
                          e.stopPropagation();
                          handleConvert();
                        }}
                      >
                        {isProcessing ? (
                          <>
                            <Loader2 className="mr-2 h-5 w-5 animate-spin" />
                            Processing...
                          </>
                        ) : (
                          <>
                            Convert Data
                          </>
                        )}
                      </Button>
                    )}
                    </div>
                  </div>
                </CardContent>
              </Card>
              
              {/* Inline Preview Section */}
              {success && showInlinePreview && (
                <PreviewSection
                  workbook={convertedData}
                  title="Material Import Preview"
                  onClose={() => setShowInlinePreview(false)}
                  onDataChange={(modifiedWorkbook) => setConvertedData(modifiedWorkbook)}
                >
                  <AIModificationPanel
                    workbook={convertedData}
                    originalWorkbook={originalConvertedData}
                    onModify={(modifiedWorkbook) => setConvertedData(modifiedWorkbook)}
                    onRevert={() => setConvertedData(originalConvertedData)}
                  />
                </PreviewSection>
              )}
            </TabsContent>
            
            <TabsContent value="mix-material" className="space-y-4 animate-in fade-in slide-in-from-bottom-4 duration-500">
              <Card className="border-border shadow-sm overflow-hidden">
                <CardContent className="pt-20 pb-20 text-center">
                  <div className="max-w-md mx-auto space-y-4">
                    <div className="w-20 h-20 rounded-full bg-primary/10 flex items-center justify-center text-primary mx-auto mb-6">
                      <FileSpreadsheet className="h-10 w-10" />
                    </div>
                    <h3 className="text-2xl font-bold text-dark">Mix & Material Upload</h3>
                    <p className="text-lg text-muted-foreground">
                      Coming Soon
                    </p>
                    <p className="text-sm text-muted-foreground">
                      This feature will allow you to upload both mix and material data simultaneously for streamlined processing.
                    </p>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>
          </Tabs>
        </div>
      </main>
    </div>
  );
}