import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
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

// ── Auto-width computation ────────────────────────────────────────────────────

const CHAR_PX = 7.5;
const COL_PADDING = 24;
const MIN_COL_WIDTH = 48;
const MAX_COL_WIDTH = 300;
const SAMPLE_ROWS = 150;

/**
 * Estimate column widths from header text and actual cell content.
 * Headers are displayed with words on separate lines, so we use longest word length.
 * Empty columns get just enough space for their header.
 */
function computeAutoWidths(headers: any[], rows: any[][]): Record<number, number> {
  const widths: Record<number, number> = {};
  const sample = Math.min(rows.length, SAMPLE_ROWS);

  headers.forEach((header, i) => {
    // Header: displayed word-wrapped, so width = longest word in header
    const words = String(header || `Col ${i + 1}`).split(/\s+/);
    const headerLen = Math.max(...words.map((w) => w.length));

    // Content: max string length in sampled rows (skip empty values)
    let contentLen = 0;
    for (let r = 0; r < sample; r++) {
      const v = rows[r]?.[i];
      if (v != null && v !== "") {
        contentLen = Math.max(contentLen, String(v).length);
      }
    }

    const len = Math.max(headerLen, contentLen);
    widths[i] = Math.min(MAX_COL_WIDTH, Math.max(MIN_COL_WIDTH, Math.round(len * CHAR_PX + COL_PADDING)));
  });

  return widths;
}

// ── Component ─────────────────────────────────────────────────────────────────

export function PreviewSection({ workbook, title, onClose, onDataChange, children }: PreviewSectionProps) {
  const [currentPage, setCurrentPage] = useState(1);
  const [columnWidths, setColumnWidths] = useState<Record<number, number>>({});
  const [editingCell, setEditingCell] = useState<{ row: number; col: number } | null>(null);
  const [editValue, setEditValue] = useState("");

  const [data, setData] = useState<any[][]>(() => {
    if (!workbook) return [];
    const ws = workbook.Sheets[workbook.SheetNames[0]];
    return XLSX.utils.sheet_to_json(ws, { header: 1 }) as any[][];
  });

  // Sync data + recompute widths when workbook changes
  useEffect(() => {
    if (!workbook) return;
    const ws = workbook.Sheets[workbook.SheetNames[0]];
    const newData = XLSX.utils.sheet_to_json(ws, { header: 1 }) as any[][];
    setData(newData);
    setColumnWidths(computeAutoWidths(newData[0] || [], newData.slice(1)));
    setCurrentPage(1);
  }, [workbook]);

  if (!workbook) return null;

  const headers = data[0] || [];
  const allRows = data.slice(1);
  const totalRows = allRows.length;

  const rowsPerPage = 100;
  const totalPages = Math.max(1, Math.ceil(totalRows / rowsPerPage));
  const startIndex = (currentPage - 1) * rowsPerPage;
  const rows = allRows.slice(startIndex, startIndex + rowsPerPage);

  // ── Column resize ──────────────────────────────────────────────────────────

  const handleMouseDown = (colIndex: number, e: React.MouseEvent) => {
    e.preventDefault();
    const startX = e.pageX;
    const startWidth = columnWidths[colIndex] ?? MIN_COL_WIDTH;

    const onMove = (ev: MouseEvent) => {
      const newWidth = Math.max(36, startWidth + ev.pageX - startX);
      setColumnWidths((prev) => ({ ...prev, [colIndex]: newWidth }));
    };
    const onUp = () => {
      document.removeEventListener("mousemove", onMove);
      document.removeEventListener("mouseup", onUp);
    };
    document.addEventListener("mousemove", onMove);
    document.addEventListener("mouseup", onUp);
  };

  // ── Cell editing ───────────────────────────────────────────────────────────

  const handleCellClick = (rowIndex: number, colIndex: number) => {
    const actualRow = startIndex + rowIndex;
    setEditingCell({ row: actualRow, col: colIndex });
    setEditValue(String(allRows[actualRow]?.[colIndex] ?? ""));
  };

  const commitEdit = () => {
    if (!editingCell) return;
    const newData = data.map((r) => [...r]);
    const targetRow = editingCell.row + 1; // +1 for header
    if (!newData[targetRow]) newData[targetRow] = [];
    newData[targetRow][editingCell.col] = editValue;
    setData(newData);

    if (onDataChange) {
      const sheetName = workbook.SheetNames[0];
      const newWs = XLSX.utils.aoa_to_sheet(newData);
      const newWb = XLSX.utils.book_new();
      XLSX.utils.book_append_sheet(newWb, newWs, sheetName);
      onDataChange(newWb);
    }
    setEditingCell(null);
    setEditValue("");
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "Enter") commitEdit();
    else if (e.key === "Escape") { setEditingCell(null); setEditValue(""); }
  };

  // ── Render ─────────────────────────────────────────────────────────────────

  return (
    <Card className="border-border shadow-sm overflow-hidden animate-in fade-in slide-in-from-bottom-4 duration-500">
      <CardHeader className="bg-secondary/1 border-b border-border pb-4 flex flex-row items-center justify-between">
        <div>
          <CardTitle className="text-xl text-secondary">{title}</CardTitle>
          <CardDescription>
            Showing {startIndex + 1}–{Math.min(startIndex + rowsPerPage, totalRows)} of {totalRows} rows · Click any cell to edit
          </CardDescription>
        </div>
        <Button variant="ghost" size="sm" onClick={onClose} className="text-muted-foreground hover:text-destructive">
          <X className="h-4 w-4" />
        </Button>
      </CardHeader>

      <CardContent className="pt-4 space-y-3">
        {children && <div className="mb-4">{children}</div>}

        {/* Table — single container that scrolls both axes */}
        <div
          className="h-[500px] rounded-lg border overflow-auto relative"
          style={{ WebkitOverflowScrolling: "touch" }}
        >
          <table
            className="border-collapse"
            style={{ tableLayout: "fixed", minWidth: "max-content" }}
          >
            <thead>
              <tr>
                {headers.map((header: any, i: number) => {
                  const w = columnWidths[i] ?? MIN_COL_WIDTH;
                  return (
                    <th
                      key={i}
                      className="sticky top-0 z-20 bg-card font-semibold text-dark text-xs border-r border-b border-border last:border-r-0 relative group select-none"
                      style={{ width: w, minWidth: w, maxWidth: w, boxSizing: "border-box" }}
                    >
                      <div className="px-2 py-2 text-center whitespace-normal break-words leading-tight">
                        {String(header || `Col ${i + 1}`)}
                      </div>
                      {/* Resize handle */}
                      <div
                        className="absolute right-0 top-0 bottom-0 w-1.5 cursor-col-resize hover:bg-primary/60 group-hover:bg-primary/20 z-10"
                        onMouseDown={(e) => handleMouseDown(i, e)}
                      />
                    </th>
                  );
                })}
              </tr>
            </thead>

            <tbody>
              {rows.map((row: any[], rowIndex: number) => (
                <tr key={rowIndex} className="hover:bg-secondary/5 border-b border-border last:border-b-0">
                  {headers.map((_: any, colIndex: number) => {
                    const actualRow = startIndex + rowIndex;
                    const isEditing = editingCell?.row === actualRow && editingCell?.col === colIndex;
                    const w = columnWidths[colIndex] ?? MIN_COL_WIDTH;
                    const cellValue = row[colIndex] != null && row[colIndex] !== ""
                      ? String(row[colIndex])
                      : "";

                    return (
                      <td
                        key={colIndex}
                        className="border-r border-border last:border-r-0 p-0 text-xs"
                        style={{ width: w, minWidth: w, maxWidth: w, boxSizing: "border-box" }}
                      >
                        {isEditing ? (
                          <Input
                            value={editValue}
                            onChange={(e) => setEditValue(e.target.value)}
                            onBlur={commitEdit}
                            onKeyDown={handleKeyDown}
                            autoFocus
                            className="h-full border-0 rounded-none focus-visible:ring-2 focus-visible:ring-primary text-xs px-2 py-1"
                          />
                        ) : (
                          <div
                            className="px-2 py-1.5 cursor-text hover:bg-primary/5 overflow-hidden whitespace-nowrap text-ellipsis"
                            title={cellValue}
                            onClick={() => handleCellClick(rowIndex, colIndex)}
                          >
                            {cellValue}
                          </div>
                        )}
                      </td>
                    );
                  })}
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        <div className="flex items-center justify-between pt-1">
          <span className="text-sm text-muted-foreground">
            Page {currentPage} of {totalPages}
          </span>
          <div className="flex gap-2">
            <Button
              variant="outline"
              size="sm"
              onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
              disabled={currentPage === 1}
            >
              <ChevronLeft className="h-4 w-4 mr-1" />
              Previous
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))}
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
