import { useState, useCallback } from 'react';

export const useRowSelection = (visibleStartRow) => {
  const [selectedRows, setSelectedRows] = useState(new Set());
  const [lastSelectedRow, setLastSelectedRow] = useState(null);

  const handleRowClick = useCallback((e, rowIndex) => {
    const absoluteRowIndex = visibleStartRow + rowIndex;

    if (e.shiftKey && lastSelectedRow !== null) {
      // Range selection
      const start = Math.min(lastSelectedRow, absoluteRowIndex);
      const end = Math.max(lastSelectedRow, absoluteRowIndex);
      const newSelected = new Set(selectedRows);
      for (let i = start; i <= end; i++) {
        newSelected.add(i);
      }
      setSelectedRows(newSelected);
    } else if (e.ctrlKey || e.metaKey) {
      // Toggle individual row
      const newSelected = new Set(selectedRows);
      if (newSelected.has(absoluteRowIndex)) {
        newSelected.delete(absoluteRowIndex);
      } else {
        newSelected.add(absoluteRowIndex);
      }
      setSelectedRows(newSelected);
      setLastSelectedRow(absoluteRowIndex);
    } else {
      // Single selection
      setSelectedRows(new Set([absoluteRowIndex]));
      setLastSelectedRow(absoluteRowIndex);
    }
  }, [visibleStartRow, lastSelectedRow, selectedRows]);

  const clearSelection = useCallback(() => {
    setSelectedRows(new Set());
    setLastSelectedRow(null);
  }, []);

  return {
    selectedRows,
    lastSelectedRow,
    handleRowClick,
    clearSelection,
    setSelectedRows,
    setLastSelectedRow
  };
};