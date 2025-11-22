import { useRef, useCallback } from 'react';
import { MIN_COLUMN_WIDTH } from '../constants';

export const useColumnResize = (tabId, ws, startCol, columns, setColumns) => {
  const resizingRef = useRef({ isResizing: false, colIndex: -1, startX: 0, startWidth: 0 });

  const handleResizeStart = useCallback((e, colIndex) => {
    e.preventDefault();
    e.stopPropagation();

    const actualColIndex = startCol + colIndex;

    console.log('Resize start:', {
      colIndex,
      startCol,
      actualColIndex,
      totalColumns: columns.length,
      columnName: columns[actualColIndex]?.name
    });

    resizingRef.current = {
      isResizing: true,
      colIndex: actualColIndex,
      startX: e.clientX,
      startWidth: columns[actualColIndex]?.width || 150
    };

    e.target.classList.add('resizing');
  }, [startCol, columns]);

  const handleResizeMove = useCallback((e) => {
    if (!resizingRef.current.isResizing) return;

    const deltaX = e.clientX - resizingRef.current.startX;
    const newWidth = Math.max(MIN_COLUMN_WIDTH, resizingRef.current.startWidth + deltaX);

    setColumns(prev => {
      const newCols = [...prev];
      if (newCols[resizingRef.current.colIndex]) {
        newCols[resizingRef.current.colIndex] = {
          ...newCols[resizingRef.current.colIndex],
          width: newWidth
        };
      }
      return newCols;
    });
  }, [setColumns]);

  const handleResizeEnd = useCallback((e) => {
    if (!resizingRef.current.isResizing) return;

    const deltaX = e.clientX - resizingRef.current.startX;
    const newWidth = Math.max(MIN_COLUMN_WIDTH, resizingRef.current.startWidth + deltaX);

    if (ws.current && ws.current.readyState === WebSocket.OPEN) {
      ws.current.send(JSON.stringify({
        type: 'resize_column',
        tabId: tabId,
        colIndex: resizingRef.current.colIndex,
        newWidth: newWidth
      }));
    }

    document.querySelectorAll('.resize-handle.resizing').forEach(el => {
      el.classList.remove('resizing');
    });

    resizingRef.current = { isResizing: false, colIndex: -1, startX: 0, startWidth: 0 };
  }, [tabId, ws]);

  return {
    resizingRef,
    handleResizeStart,
    handleResizeMove,
    handleResizeEnd
  };
};