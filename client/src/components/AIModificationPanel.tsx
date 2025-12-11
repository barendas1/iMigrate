import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Collapsible, CollapsibleContent, CollapsibleTrigger } from "@/components/ui/collapsible";
import { AlertCircle, ChevronDown, Loader2, Sparkles } from "lucide-react";
import { useState } from "react";
import * as XLSX from "xlsx";

interface AIModificationPanelProps {
  workbook: XLSX.WorkBook | null;
  originalWorkbook: XLSX.WorkBook | null;
  onModify: (modifiedWorkbook: XLSX.WorkBook) => void;
  onRevert: () => void;
}

export function AIModificationPanel({ workbook, originalWorkbook, onModify, onRevert }: AIModificationPanelProps) {
  const apiKey = import.meta.env.VITE_OPENAI_API_KEY || "";
  const [instruction, setInstruction] = useState("");
  const [isProcessing, setIsProcessing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const [logs, setLogs] = useState<string[]>([]);
  const [isOpen, setIsOpen] = useState(false);

  const handleModify = async () => {
    if (!workbook || !apiKey.trim() || !instruction.trim()) {
      setError("Please provide both API key and modification instructions");
      return;
    }

    setIsProcessing(true);
    setError(null);
    setSuccess(false);
    setLogs([]);
    
    const addLog = (message: string) => {
      setLogs(prev => [...prev, `[${new Date().toLocaleTimeString()}] ${message}`]);
    };
    
    addLog('Starting AI transformation...');

    try {
      // Get the first sheet from the workbook
      const sheetName = workbook.SheetNames[0];
      const worksheet = workbook.Sheets[sheetName];
      const data: any[][] = XLSX.utils.sheet_to_json(worksheet, { header: 1 });
      
      const headers = data[0] || [];
      const rows = data.slice(1);
      
      addLog(`Processing ${rows.length} rows with ${headers.length} columns`);

      // Prepare data for OpenAI
      const dataPreview = {
        headers,
        sampleRows: rows.slice(0, 5), // Send first 5 rows as context
        totalRows: rows.length
      };

      // Call OpenAI API
      addLog('Sending request to OpenAI...');
      const response = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${apiKey}`
        },
        body: JSON.stringify({
          model: "gpt-4o-mini",
          messages: [
            {
              role: "system",
              content: `You are a data transformation assistant. Generate JavaScript code that transforms spreadsheet data.

IMPORTANT: Your response must be ONLY executable JavaScript code that:
1. Modifies the 'headers' array (if needed)
2. Modifies the 'rows' array (array of arrays)
3. Returns an object: { headers: newHeaders, rows: newRows }

RULES:
- Do NOT wrap in a function declaration
- Do NOT include explanations, comments, or markdown
- Use headers.indexOf() to find column positions
- Column names may contain spaces, parentheses, slashes - use exact string matching
- The code has access to 'headers' (array of strings) and 'rows' (array of arrays)

EXAMPLE:
To change all values in column "Plant Code" to "ABC":
const colIndex = headers.indexOf("Plant Code");
const newRows = rows.map(row => {
  const newRow = [...row];
  newRow[colIndex] = "ABC";
  return newRow;
});
return { headers, rows: newRows };`
            },
            {
              role: "user",
              content: `Data structure:
Headers: ${JSON.stringify(headers)}
Sample rows (first 5 of ${rows.length}): ${JSON.stringify(dataPreview.sampleRows)}

Task: ${instruction}

Generate the transformation code:`
            }
          ],
          temperature: 0.3
        })
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error?.message || "OpenAI API request failed");
      }

      const result = await response.json();
      let code = result.choices[0].message.content;
      
      addLog('Received AI response, executing transformation...');

      // Clean up the code
      code = code.replace(/```javascript\n?/g, '').replace(/```js\n?/g, '').replace(/```\n?/g, '').trim();
      
      // Remove any function declarations and extract the body
      code = code.replace(/^function\s+\w+\s*\([^)]*\)\s*\{/m, '');
      code = code.replace(/^\([^)]*\)\s*=>\s*\{/m, '');
      code = code.replace(/\}\s*$/m, '');
      
      console.log('Executing AI code:', code);
      
      // Execute the transformation with better error handling
      let newHeaders, newRows;
      try {
        const transformFunction = new Function('headers', 'rows', `
          'use strict';
          ${code}
          // If the code doesn't return anything, assume headers and rows were modified in place
          if (typeof result !== 'undefined') {
            return result;
          }
          return { headers, rows };
        `);

        const transformResult = transformFunction([...headers], rows.map(row => [...row]));
        
        // Validate the result
        if (!transformResult || typeof transformResult !== 'object') {
          throw new Error('Transformation did not return a valid object');
        }
        if (!Array.isArray(transformResult.headers)) {
          throw new Error('Transformation did not return valid headers array');
        }
        if (!Array.isArray(transformResult.rows)) {
          throw new Error('Transformation did not return valid rows array');
        }
        
        newHeaders = transformResult.headers;
        newRows = transformResult.rows;
        
        // Calculate what changed
        let rowsModified = 0;
        let cellsModified = 0;
        
        for (let i = 0; i < Math.min(rows.length, newRows.length); i++) {
          let rowChanged = false;
          for (let j = 0; j < Math.max(rows[i]?.length || 0, newRows[i]?.length || 0); j++) {
            if (rows[i]?.[j] !== newRows[i]?.[j]) {
              cellsModified++;
              rowChanged = true;
            }
          }
          if (rowChanged) rowsModified++;
        }
        
        // Account for added/removed rows
        if (newRows.length > rows.length) {
          rowsModified += newRows.length - rows.length;
          cellsModified += (newRows.length - rows.length) * (newHeaders.length || 0);
        } else if (newRows.length < rows.length) {
          rowsModified += rows.length - newRows.length;
        }
        
        const stats = {
          originalRows: rows.length,
          newRows: newRows.length,
          originalHeaders: headers.length,
          newHeaders: newHeaders.length,
          rowsModified,
          cellsModified
        };
        console.log('Transformation successful:', stats);
        addLog(`Updated ${cellsModified} cells across ${rowsModified} rows`);
        addLog(`Result: ${stats.newRows} rows, ${stats.newHeaders} columns`);
      } catch (execError: any) {
        console.error('Code execution error:', execError);
        console.error('Generated code was:', code);
        throw new Error(`Transformation failed: ${execError.message}\n\nGenerated code:\n${code}`);
      }

      // Create new workbook with modified data
      const newData = [newHeaders, ...newRows];
      const newWorksheet = XLSX.utils.aoa_to_sheet(newData);
      const newWorkbook = XLSX.utils.book_new();
      XLSX.utils.book_append_sheet(newWorkbook, newWorksheet, sheetName);

      addLog('Updating preview with modified data...');
      onModify(newWorkbook);
      setSuccess(true);
      addLog('✓ Modification applied successfully!');
      setInstruction(""); // Clear instruction after successful modification
    } catch (err: any) {
      console.error('AI Modification Error:', err);
      setError(err.message || "Failed to modify data. Please check your instruction and try again.");
    } finally {
      setIsProcessing(false);
    }
  };

  return (
    <Card className="border-border shadow-sm overflow-hidden p-0 gap-0">
      <Collapsible open={isOpen} onOpenChange={setIsOpen}>
        <CollapsibleTrigger asChild>
          <CardHeader className="bg-primary/5 border-b border-border pb-3 pt-3 cursor-pointer hover:bg-primary/10 transition-colors">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Sparkles className="h-5 w-5 text-primary" />
                <CardTitle className="text-lg text-secondary">AI Data Modification</CardTitle>
              </div>
              <ChevronDown 
                className={`h-5 w-5 text-muted-foreground transition-transform duration-200 ${isOpen ? 'transform rotate-180' : ''}`}
              />
            </div>
          </CardHeader>
        </CollapsibleTrigger>
        
        <CollapsibleContent>
          <CardContent className="pt-4 space-y-3">
            <CardDescription className="text-sm">
              Use AI to modify your preview data with natural language instructions
            </CardDescription>
            
            <div className="space-y-2">
              <Label htmlFor="instruction">Modification Instructions</Label>
              <div className="relative flex items-stretch">
                <Textarea
                  id="instruction"
                  placeholder="Example: In column 'Plant Code', append a 0 to each value"
                  value={instruction}
                  onChange={(e) => setInstruction(e.target.value)}
                  rows={3}
                  className="resize-none pr-24"
                />
                <Button
                  onClick={handleModify}
                  disabled={!workbook || !apiKey.trim() || !instruction.trim() || isProcessing}
                  className="absolute right-1 top-1 h-[70px] w-[10%] min-w-[60px] bg-primary hover:bg-primary-hover flex items-center justify-center"
                >
                  {isProcessing ? (
                    <Loader2 className="h-4 w-4 animate-spin" />
                  ) : (
                    <Sparkles className="h-4 w-4" />
                  )}
                </Button>
              </div>
              <p className="text-xs text-muted-foreground">
                Describe what changes you want to make to the data
              </p>
            </div>

            {error && (
              <div className="bg-destructive/10 border border-destructive/20 rounded-lg p-4 flex items-start gap-3 text-destructive">
                <AlertCircle className="h-5 w-5 mt-0.5 shrink-0" />
                <div className="flex-1">
                  <p className="font-medium">Error</p>
                  <pre className="text-xs opacity-90 mt-1 whitespace-pre-wrap max-h-40 overflow-y-auto font-mono">{error}</pre>
                </div>
              </div>
            )}

            {/* Logs Display */}
            {logs.length > 0 && (
              <div className="bg-secondary/5 border border-border rounded-lg p-3 space-y-1 max-h-32 overflow-y-auto">
                <p className="font-medium text-xs text-muted-foreground mb-2">Transformation Log:</p>
                {logs.map((log, index) => (
                  <p key={index} className="text-xs font-mono text-muted-foreground">{log}</p>
                ))}
              </div>
            )}

            {/* Success message and Revert button in compact horizontal layout */}
            {success && workbook && originalWorkbook && (
              <div className="flex items-center gap-2">
                <div className="flex-1 bg-success/10 border border-success/20 rounded-lg px-3 py-2 text-success flex items-center gap-2">
                  <span className="text-sm font-medium">✓ Modified successfully</span>
                </div>
                <Button
                  onClick={onRevert}
                  variant="outline"
                  size="sm"
                  className="border-destructive/30 text-destructive hover:bg-destructive/10 whitespace-nowrap"
                >
                  Revert
                </Button>
              </div>
            )}
          </CardContent>
        </CollapsibleContent>
      </Collapsible>
    </Card>
  );
}