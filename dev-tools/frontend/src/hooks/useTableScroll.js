import { useRef, useCallback } from 'react';

export const useTableScroll = (tabId, ws, startRow, startCol, topOffset, totalRows, columns, actualRowHeight) => {
  const vThumbDragRef = useRef({ dragging: false, startY: 0, startScroll: 0 });
  const hThumbDragRef = useRef({ dragging: false, startX: 0, startScroll: 0 });

  const scrollVertical = useCallback((direction, tableBodyRef) => {
    const currentScroll = startRow * actualRowHeight + topOffset;
    const totalHeight = totalRows * actualRowHeight;
    const viewportHeight = tableBodyRef.current?.clientHeight || 0;
    const scrollableHeight = totalHeight - viewportHeight;

    let viewportPositionFromTop;
    if (direction === 'up') {
      viewportPositionFromTop = Math.max(0, currentScroll - actualRowHeight);
    } else if (direction === 'down') {
      viewportPositionFromTop = Math.min(scrollableHeight, currentScroll + actualRowHeight);
    } else if (direction === 'top') {
      viewportPositionFromTop = 0;
    } else if (direction === 'bottom') {
      viewportPositionFromTop = scrollableHeight;
    }

    if (ws.current && ws.current.readyState === WebSocket.OPEN) {
      ws.current.send(JSON.stringify({
        type: 'scroll_update',
        tabId: tabId,
        viewportPositionFromTop: viewportPositionFromTop
      }));
    }
  }, [tabId, ws, startRow, startCol, topOffset, totalRows, actualRowHeight]);

  const scrollHorizontal = useCallback((direction, tableBodyRef) => {
    let totalWidth = 0;
    for (let i = 0; i < columns.length; i++) {
      totalWidth += columns[i]?.width || 150;
    }

    const viewportWidth = tableBodyRef.current?.clientWidth || 0;
    const maxScrollWidth = Math.max(0, totalWidth - viewportWidth);

    let scrolledWidth = 0;
    for (let i = 0; i < startCol && i < columns.length; i++) {
      scrolledWidth += columns[i]?.width || 150;
    }
    const currentScroll = scrolledWidth + topOffset;

    const scrollStep = 150;
    let viewportPositionFromLeft;

    if (direction === 'left') {
      viewportPositionFromLeft = Math.max(0, currentScroll - scrollStep);
    } else if (direction === 'right') {
      viewportPositionFromLeft = Math.min(maxScrollWidth, currentScroll + scrollStep);
    } else if (direction === 'start') {
      viewportPositionFromLeft = 0;
    } else if (direction === 'end') {
      viewportPositionFromLeft = maxScrollWidth;
    }

    if (ws.current && ws.current.readyState === WebSocket.OPEN) {
      ws.current.send(JSON.stringify({
        type: 'scroll_update',
        tabId: tabId,
        startCol: startCol,
        scrollLeftPixels: viewportPositionFromLeft
      }));
    }
  }, [tabId, ws, startCol, columns, topOffset]);

  return {
    scrollVertical,
    scrollHorizontal,
    vThumbDragRef,
    hThumbDragRef
  };
};