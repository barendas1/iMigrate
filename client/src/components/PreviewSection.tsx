import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { ChevronLeft, ChevronRight, X } from "lucide-react";
import { useEffect, useState } from "react";
import * as XLSX from "xlsx";

interface PreviewSectionProps {
  workbook: XLSX.WorkBook | null;
  title: string;
  onClose: () => void;
  onDataChange?: (workbook: XLSX.WorkBook) => void;
  children?: React.ReactNode;
}

export function PreviewSection({ workbook, title, onClose, onDataChange, children }: PreviewSectionProps) {
  const [currentPage, setCurrentPage] = useState(1);
  const [columnWidths, setColumnWidths] = useState<{ [key: number]: number }>({});
  const [editingCell, setEditingCell] = useState<{ row: number; col: number } | null>(null);
  const [editValue, setEditValue] = useState("");
  const [data, setData] = useState<any[][]>(() => {
    if (!workbook) return [];
    const sheetName = workbook.SheetNames[0];
    const worksheet = workbook.Sheets[sheetName];
    return XLSX.utils.sheet_to_json(worksheet, { header: 1 });
  });
  
  const rowsPerPage = 100;
  
  // Auto-refresh preview when workbook changes
  useEffect(() => {
    if (workbook) {
      const sheetName = workbook.SheetNames[0];
      const worksheet = workbook.Sheets[sheetName];
      const newData = XLSX.utils.sheet_to_json(worksheet, { header: 1 }) as any[][];
      setData(newData);
    }
  }, [workbook]);

  if (!workbook) return null;

  // Get headers (first row) and rows (rest)
  const headers = data[0] || [];
  const allRows = data.slice(1);
  const totalRows = allRows.length;
  const totalPages = Math.ceil(totalRows / rowsPerPage);
  
  // Get current page rows
  const startIndex = (currentPage - 1) * rowsPerPage;
  const endIndex = startIndex + rowsPerPage;
  const rows = allRows.slice(startIndex, endIndex);

  // Handle column resize
  const handleMouseDown = (colIndex: number, e: React.MouseEvent) => {
    e.preventDefault();
    const startX = e.pageX;
    const startWidth = columnWidths[colIndex] || 150;

    const handleMouseMove = (moveEvent: MouseEvent) => {
      const diff = moveEvent.pageX - startX;
      const newWidth = Math.max(80, startWidth + diff);
      setColumnWidths(prev => ({ ...prev, [colIndex]: newWidth }));
    };

    const handleMouseUp = () => {
      document.removeEventListener('mousemove', handleMouseMove);
      document.removeEventListener('mouseup', handleMouseUp);
    };

    document.addEventListener('mousemove', handleMouseMove);
    document.addEventListener('mouseup', handleMouseUp);
  };

  // Handle cell edit
  const handleCellClick = (rowIndex: number, colIndex: number) => {
    const actualRowIndex = startIndex + rowIndex;
    setEditingCell({ row: actualRowIndex, col: colIndex });
    setEditValue(String(allRows[actualRowIndex][colIndex] || ""));
  };

  const handleCellBlur = () => {
    if (editingCell) {
      // Update the data
      const newData = [...data];
      const actualRowIndex = editingCell.row + 1; // +1 because data includes headers
      if (!newData[actualRowIndex]) {
        newData[actualRowIndex] = [];
      }
      newData[actualRowIndex][editingCell.col] = editValue;
      setData(newData);

      // Update the workbook
      const sheetName = workbook.SheetNames[0];
      const newWorksheet = XLSX.utils.aoa_to_sheet(newData);
      const newWorkbook = XLSX.utils.book_new();
      XLSX.utils.book_append_sheet(newWorkbook, newWorksheet, sheetName);
      
      if (onDataChange) {
        onDataChange(newWorkbook);
      }

      setEditingCell(null);
      setEditValue("");
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      handleCellBlur();
    } else if (e.key === 'Escape') {
      setEditingCell(null);
      setEditValue("");
    }
  };

  return (
    <Card className="border-border shadow-sm overflow-hidden animate-in fade-in slide-in-from-bottom-4 duration-500">
      <CardHeader className="bg-secondary/1 border-b border-border pb-6 flex flex-row items-center justify-between">
        <div>
          <CardTitle className="text-xl text-secondary">{title}</CardTitle>
          <CardDescription>
            Showing {startIndex + 1}-{Math.min(endIndex, totalRows)} of {totalRows} rows • Click any cell to edit
          </CardDescription>
        </div>
        <Button 
          variant="ghost" 
          size="sm"
          onClick={onClose}
          className="text-muted-foreground hover:text-destructive"
        >
          <X className="h-4 w-4" />
        </Button>
      </CardHeader>
      
      <CardContent className="pt-4 space-y-3">
        {/* AI Modification Panel (if provided as children) */}
        {children && (
          <div className="mb-4">
            {children}
          </div>
        )}

        <div className="h-[500px] w-full rounded-lg border overflow-auto">
          <div className="inline-block min-w-full">
            <Table>
              <TableHeader className="bg-secondary/10 sticky top-0 z-10">
                <TableRow>
                  {headers.map((header: any, index: number) => (
                    <TableHead 
                      key={index} 
                      className="font-semibold text-dark relative group border-r border-border last:border-r-0"
                      style={{ 
                        width: columnWidths[index] || 150,
                        minWidth: columnWidths[index] || 150,
                        maxWidth: columnWidths[index] || 150
                      }}
                    >
                      <div className="flex flex-col items-center justify-center text-center whitespace-pre-wrap break-words leading-tight py-2">
                        {(header || `Column ${index + 1}`).toString().split(' ').join('\n')}
                      </div>
                      <div
                        className="absolute right-0 top-0 bottom-0 w-1 cursor-col-resize hover:bg-primary/50 group-hover:bg-primary/30"
                        onMouseDown={(e) => handleMouseDown(index, e)}
                      />
                    </TableHead>
                  ))}
                </TableRow>
              </TableHeader>
              <TableBody>
                {rows.map((row: any[], rowIndex: number) => (
                  <TableRow key={rowIndex} className="hover:bg-secondary/5">
                    {headers.map((_: any, colIndex: number) => {
                      const actualRowIndex = startIndex + rowIndex;
                      const isEditing = editingCell?.row === actualRowIndex && editingCell?.col === colIndex;
                      
                      return (
                        <TableCell 
                          key={colIndex} 
                          className="whitespace-nowrap p-0 border-r border-border last:border-r-0"
                          style={{ 
                            width: columnWidths[colIndex] || 150,
                            minWidth: columnWidths[colIndex] || 150,
                            maxWidth: columnWidths[colIndex] || 150,
                          }}
                        >
                          {isEditing ? (
                            <Input
                              value={editValue}
                              onChange={(e) => setEditValue(e.target.value)}
                              onBlur={handleCellBlur}
                              onKeyDown={handleKeyDown}
                              autoFocus
                              className="h-full border-0 rounded-none focus-visible:ring-2 focus-visible:ring-primary"
                            />
                          ) : (
                            <div
                              className="px-4 py-2 cursor-text hover:bg-primary/5"
                              onClick={() => handleCellClick(rowIndex, colIndex)}
                              style={{
                                overflow: 'hidden',
                                textOverflow: 'ellipsis'
                              }}
                            >
                              {row[colIndex] !== undefined && row[colIndex] !== null 
                                ? String(row[colIndex]) 
                                : ''}
                            </div>
                          )}
                        </TableCell>
                      );
                    })}
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        </div>

        {/* Pagination Controls */}
        <div className="flex items-center justify-between pt-2">
          <div className="text-sm text-muted-foreground">
            Page {currentPage} of {totalPages}
          </div>
          <div className="flex gap-2">
            <Button
              variant="outline"
              size="sm"
              onClick={() => setCurrentPage(prev => Math.max(1, prev - 1))}
              disabled={currentPage === 1}
            >
              <ChevronLeft className="h-4 w-4 mr-1" />
              Previous
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={() => setCurrentPage(prev => Math.min(totalPages, prev + 1))}
              disabled={currentPage === totalPages}
            >
              Next
              <ChevronRight className="h-4 w-4 ml-1" />
            </Button>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}