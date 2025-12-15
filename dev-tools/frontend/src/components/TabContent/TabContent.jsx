import React, { useState, useEffect, useRef, useCallback, useMemo } from 'react';
import { ControlsPanel } from '../ControlsPanel/ControlsPanel';
import { DataTable } from '../DataTable/DataTable';
import { StatusBar } from '../StatusBar/StatusBar';
import { useTableScroll } from '../../hooks/useTableScroll';
import { useColumnResize } from '../../hooks/useColumnResize';
import { useRowSelection } from '../../hooks/useRowSelection';
import { sendTabAction } from '../../utils/websocketHelpers';
import './TabContent.css';

export const TabContent = ({ tabId, isActive, ws, wsReady, tabLabel, onUpdateTabLabel }) => {
  const [snsSql, setSnsSql] = useState('');
  const [pinByKey, setPinByKey] = useState(false);
  const [opType, setOpType] = useState('snapSubscribe');
  const [appendToBottom, setAppendToBottom] = useState(true); // or false for top
  const [statusText, setStatusText] = useState('Not snapped / subscribed yet...');
  const [state, setState] = useState('new');

  // Buffer state - stores all cached rows (visible + hidden)
  const [bufferData, setBufferData] = useState([]);
  const [bufferStartRow, setBufferStartRow] = useState(0);
  const [bufferEndRow, setBufferEndRow] = useState(-1);

  // Visible viewport within buffer
  const [visibleStartRow, setVisibleStartRow] = useState(0);
  const [visibleEndRow, setVisibleEndRow] = useState(-1);

  // Offsets for smooth scrolling
  const [topOffset, setTopOffset] = useState(0);
  const [totalRows, setTotalRows] = useState(0);
  const [actualRowHeight, setActualRowHeight] = useState(33);

  const [startCol, setStartCol] = useState(0);
  const [leftOffset, setLeftOffset] = useState(0);
  const [totalCols, setTotalCols] = useState(0);

  const [scrollMetrics, setScrollMetrics] = useState({
    verticalThumbRatio: 1,
    verticalThumbPosition: 0,
    horizontalThumbRatio: 1,
    horizontalThumbPosition: 0
  });

  const [columns, setColumns] = useState([]);
  const [columnOrder, setColumnOrder] = useState([]);
  const [viewportSize, setViewportSize] = useState({ rows: 0, cols: 0 });

  const tableHeaderRef = useRef(null);
  const tableBodyRef = useRef(null);
  const actualRowHeightSentRef = useRef(false);
  const tableContainerRef = useRef(null);
  const vScrollTrackRef = useRef(null);
  const hScrollTrackRef = useRef(null);
  const resizeTimeoutRef = useRef(null);
  const lastViewportDimensionsRef = useRef({ width: 0, height: 0 });
  const dragRef = useRef({ dragging: false, draggedIndex: -1, targetIndex: -1 });
  const hasInitialized = useRef(false);

  // Throttle refs for scroll events
  const scrollThrottleRef = useRef({
    lastExecuted: 0,
    timeoutId: null,
    pendingArgs: null
  });

  // Use custom hooks
  const { selectedRows, handleRowClick, clearSelection, setSelectedRows, setLastSelectedRow } =
    useRowSelection(visibleStartRow);

  const { scrollVertical, scrollHorizontal, vThumbDragRef, hThumbDragRef } =
    useTableScroll(tabId, ws, visibleStartRow, startCol, topOffset, totalRows, columns, actualRowHeight);

  const { handleResizeStart, handleResizeMove, handleResizeEnd } =
    useColumnResize(tabId, ws, startCol, columns, setColumns);

  // Compute visible data from buffer
  const visibleTableData = useMemo(() => {
    if (bufferData.length === 0 || bufferEndRow < bufferStartRow) return [];
    const startIdx = visibleStartRow - bufferStartRow;
    const endIdx = visibleEndRow - bufferStartRow;
    if (startIdx < 0 || endIdx >= bufferData.length) return [];
    return bufferData.slice(startIdx, endIdx + 1);
  }, [bufferData, bufferStartRow, visibleStartRow, visibleEndRow]);

  // Throttle function for scroll events
  const throttle = useCallback((fn, delay = 50) => {
    return (...args) => {
      const now = Date.now();
      const timeSinceLastExecution = now - scrollThrottleRef.current.lastExecuted;

      if (scrollThrottleRef.current.timeoutId) {
        clearTimeout(scrollThrottleRef.current.timeoutId);
        scrollThrottleRef.current.timeoutId = null;
      }

      if (timeSinceLastExecution >= delay) {
        scrollThrottleRef.current.lastExecuted = now;
        scrollThrottleRef.current.pendingArgs = null;
        fn(...args);
      } else {
        scrollThrottleRef.current.pendingArgs = args;
        scrollThrottleRef.current.timeoutId = setTimeout(() => {
          scrollThrottleRef.current.lastExecuted = Date.now();
          if (scrollThrottleRef.current.pendingArgs) {
            fn(...scrollThrottleRef.current.pendingArgs);
            scrollThrottleRef.current.pendingArgs = null;
          }
          scrollThrottleRef.current.timeoutId = null;
        }, delay - timeSinceLastExecution);
      }
    };
  }, []);

  // Throttled scroll update function
  const sendScrollUpdate = useCallback(throttle((message) => {
    if (ws.current && ws.current.readyState === WebSocket.OPEN) {
      ws.current.send(JSON.stringify(message));
    }
  }, 50), [throttle, ws]);

  // WebSocket message handler
  useEffect(() => {
    if (!ws.current || !wsReady) return;

    const handleMessage = (event) => {
      const msg = JSON.parse(event.data);

      if (msg.mode && msg.mode !== 'subscriber') {
        return;
      }

      if (msg.tabId !== tabId) return;

      switch (msg.type) {
        case 'update_state':
          if (msg.state) {
            setState(msg.state);
          }
          break;

        case 'update_tab_label':
          if (onUpdateTabLabel && msg.label) {
            onUpdateTabLabel(tabId, msg.label);
          }
          break;

        case 'update_status':
          if (msg.status) {
            setStatusText(msg.status);
          }
          break;

        case 'full_update':
          const numRows = msg.data.length;
          setBufferData(msg.data || []);
          setBufferStartRow(msg.startRow || 0);
          setBufferEndRow(msg.startRow + numRows - 1);
          setVisibleStartRow(msg.startRow || 0);
          setVisibleEndRow(msg.startRow + numRows - 1);
          setTopOffset(msg.topOffset);
          setStartCol(msg.startCol);
          setLeftOffset(msg.leftOffset);
          break;

        case 'delta_update':
          // Insert rows at position, optionally remove from ends
          setBufferData(prev => {
            let newBuffer = [...prev];

            // First: Insert new rows at the specified position (absolute row index)
            const insertIndex = msg.position - msg.startRow;
            if (insertIndex >= 0 && insertIndex <= newBuffer.length) {
              newBuffer.splice(insertIndex, 0, ...msg.data);
            }

            // Second: Remove rows if specified
            if (msg.removeCount && msg.removeFrom) {
              if (msg.removeFrom === 'top') {
                // Remove from the beginning
                newBuffer.splice(0, msg.removeCount);
              } else if (msg.removeFrom === 'bottom') {
                // Remove from the end
                newBuffer.splice(newBuffer.length - msg.removeCount, msg.removeCount);
              }
            }

            return newBuffer;
          });

          setBufferStartRow(msg.startRow);
          setBufferEndRow(msg.endRow);
          setVisibleStartRow(msg.visibleStartRow);
          setVisibleEndRow(msg.visibleEndRow);
          setTopOffset(msg.topOffset || 0);
          break;

        case 'row_update':
          setBufferData(prev => {
            const rowIdx = msg.rowIndex;
            if (rowIdx < 0 || rowIdx > prev.length) {
              return prev;
            }
            const newBuffer = [...prev];
            newBuffer[rowIdx] = msg.data;
            return newBuffer;
          });
          break;

        case 'scroll_metrics_vertical':
          if (msg.totalRows !== undefined) setTotalRows(msg.totalRows);
          if (msg.verticalThumbRatio !== undefined || msg.verticalThumbPosition !== undefined) {
            setScrollMetrics(prev => ({
              ...prev,
              verticalThumbRatio: msg.verticalThumbRatio !== undefined ? msg.verticalThumbRatio : prev.verticalThumbRatio,
              verticalThumbPosition: msg.verticalThumbPosition !== undefined ? msg.verticalThumbPosition : prev.verticalThumbPosition
            }));
          }
          if (msg.visibleStartRow !== undefined) setVisibleStartRow(msg.visibleStartRow);
          if (msg.visibleEndRow !== undefined) setVisibleEndRow(msg.visibleEndRow);
          if (msg.startRow !== undefined) setBufferStartRow(msg.startRow);
          if (msg.endRow !== undefined) setBufferEndRow(msg.endRow);
          if (msg.topOffset !== undefined) setTopOffset(msg.topOffset);
          break;

        case 'scroll_metrics_horizontal':
          if (msg.horizontalThumbRatio !== undefined || msg.horizontalThumbPosition !== undefined) {
            setScrollMetrics(prev => ({
              ...prev,
              horizontalThumbRatio: msg.horizontalThumbRatio !== undefined ? msg.horizontalThumbRatio : prev.horizontalThumbRatio,
              horizontalThumbPosition: msg.horizontalThumbPosition !== undefined ? msg.horizontalThumbPosition : prev.horizontalThumbPosition
            }));
          }
          break;

        case 'column_update':
          if (msg.totalCols !== undefined) setTotalCols(msg.totalCols);
          if (msg.columns !== undefined) {
            setColumns(msg.columns);
            setColumnOrder(msg.columns.map((_, idx) => idx));
          }
          break;

        case 'clear_table':
          setBufferData([]);
          setBufferStartRow(0);
          setBufferEndRow(-1);
          setVisibleStartRow(0);
          setVisibleEndRow(-1);
          setColumns([]);
          setColumnOrder([]);
          setStartCol(0);
          setTotalRows(0);
          setTotalCols(0);
          setTopOffset(0);
          setLeftOffset(0);
          setStatusText('Not snapped / subscribed yet...');
          clearSelection();
          setScrollMetrics({
            verticalThumbRatio: 1,
            verticalThumbPosition: 0,
            horizontalThumbRatio: 1,
            horizontalThumbPosition: 0
          });
          break;
      }
    };

    ws.current.addEventListener('message', handleMessage);

    // Send init only once per tab, only when active
    if (isActive && !hasInitialized.current) {
      hasInitialized.current = true;

      setTimeout(() => {
        if (ws.current && ws.current.readyState === WebSocket.OPEN && tableBodyRef.current) {
          const viewportHeight = tableBodyRef.current.clientHeight;
          const viewportWidth = tableBodyRef.current.clientWidth;

          console.log('Sending init_tab for', tabId, ' viewportHeight=', viewportHeight, ' viewportWidth=', viewportWidth);

          ws.current.send(JSON.stringify({
            type: 'init_tab',
            tabId: tabId,
            mode: 'subscriber',
            viewportWidth: viewportWidth,
            viewportHeight: viewportHeight
          }));
        }
      }, 100);
    }

    return () => {
      if (ws.current) {
        ws.current.removeEventListener('message', handleMessage);
      }
    };
  }, [isActive, tabId, wsReady, onUpdateTabLabel, clearSelection, ws]);

  // Reset hasInitialized on unmount (for page refresh)
  useEffect(() => {
    return () => {
      hasInitialized.current = false;
    };
  }, []);

  // Viewport calculation
  const calculateViewportSize = useCallback(() => {
    if (!tableBodyRef.current || !isActive) return;

    const viewportHeight = tableBodyRef.current.clientHeight;
    const viewportWidth = tableBodyRef.current.clientWidth;

    if (viewportHeight === 0 || viewportWidth === 0) return;

    const rows = Math.max(1, Math.ceil(viewportHeight / actualRowHeight));
    let cols = 0;
    let totalWidth = 0;
    if (columns.length > 0) {
      for (let i = 0; i < columns.length; i++) {
        const colWidth = columns[i]?.width || 150;
        totalWidth += colWidth;
        cols++;
        if (totalWidth >= viewportWidth) break;
      }
      cols = Math.max(1, Math.min(cols, columns.length));
    } else {
      cols = Math.max(1, Math.floor(viewportWidth / 150));
    }
    setViewportSize({ rows, cols });

    const lastDimensions = lastViewportDimensionsRef.current;
    if (lastDimensions.width !== viewportWidth || lastDimensions.height !== viewportHeight) {
      if (ws.current && ws.current.readyState === WebSocket.OPEN) {
        lastViewportDimensionsRef.current = { width: viewportWidth, height: viewportHeight };

        ws.current.send(JSON.stringify({
          type: 'viewport_update',
          mode: 'subscriber',
          tabId: tabId,
          viewportWidth: viewportWidth,
          viewportHeight: viewportHeight
        }));
      }
    }
  }, [tabId, columns, ws, isActive, actualRowHeight]);

  useEffect(() => {
    if (!visibleTableData.length || actualRowHeightSentRef.current) return;

    const firstRow = tableBodyRef.current?.querySelector('tr');
    if (firstRow && ws.current && ws.current.readyState === WebSocket.OPEN) {
      const actualHeight = firstRow.getBoundingClientRect().height;
      console.log('Actual row height:', actualHeight);

      setActualRowHeight(actualHeight);

      ws.current.send(JSON.stringify({
        type: 'set_row_height',
        tabId: tabId,
        rowHeight: actualHeight
      }));

      actualRowHeightSentRef.current = true;
    }
  }, [visibleTableData, tabId, ws]);

  // Reset on unmount
  useEffect(() => {
    return () => {
      actualRowHeightSentRef.current = false;
    };
  }, []);

  // Resize and wheel event handlers
  useEffect(() => {
    if (!isActive) return;

    calculateViewportSize();

    const handleResize = () => {
      if (resizeTimeoutRef.current) clearTimeout(resizeTimeoutRef.current);
      resizeTimeoutRef.current = setTimeout(calculateViewportSize, 100);
    };

    const handleWheel = (e) => {
      e.preventDefault();
      const viewportHeight = tableBodyRef.current?.clientHeight || 0;
      const totalHeight = totalRows * actualRowHeight;
      const deltaScroll =
         e.deltaMode === WheelEvent.DOM_DELTA_LINE ? e.deltaY * actualRowHeight :
         e.deltaMode === WheelEvent.DOM_DELTA_PAGE ? e.deltaY * actualRowHeight * Math.floor(viewportHeight / actualRowHeight) :
         e.deltaY; // WheelEvent.DOM_DELTA_PIXEL
      const currentScroll = visibleStartRow * actualRowHeight + topOffset;
      const scrollableHeight = Math.max(0, totalHeight - viewportHeight);
      const viewportPositionFromTop = Math.max(0, Math.min(scrollableHeight, currentScroll + deltaScroll));

      if (viewportPositionFromTop !== currentScroll) {
        sendScrollUpdate({
          type: 'scroll_update',
          tabId: tabId,
          source: "wheel",
          viewportPositionFromTop: viewportPositionFromTop
        });
      }
    };

    window.addEventListener('resize', handleResize);
    const tableBody = tableBodyRef.current;
    if (tableBody) tableBody.addEventListener('wheel', handleWheel, { passive: false });

    return () => {
      window.removeEventListener('resize', handleResize);
      if (tableBody) tableBody.removeEventListener('wheel', handleWheel);
      if (resizeTimeoutRef.current) clearTimeout(resizeTimeoutRef.current);
    };
  }, [isActive, calculateViewportSize, visibleStartRow, topOffset, totalRows, actualRowHeight, tabId, startCol, sendScrollUpdate]);

  // Mouse drag handlers
  useEffect(() => {
    if (!isActive) return;

    const handleMouseMove = (e) => {
      handleResizeMove(e);

      if (vThumbDragRef.current.dragging) {
        const deltaY = e.clientY - vThumbDragRef.current.startY;
        const trackHeight = vScrollTrackRef.current?.clientHeight || 0;
        const thumbHeight = trackHeight * scrollMetrics.verticalThumbRatio;
        const maxThumbTop = trackHeight - thumbHeight;
        const deltaScroll = maxThumbTop > 0 ? (deltaY / maxThumbTop) : 0;

        const totalHeight = totalRows * actualRowHeight;
        const viewportHeight = tableBodyRef.current?.clientHeight || 0;
        const scrollableHeight = Math.max(0, totalHeight - viewportHeight);

        const viewportPositionFromTop =
          Math.max(0, Math.min(scrollableHeight, vThumbDragRef.current.startScroll + deltaScroll * scrollableHeight));

        sendScrollUpdate({
          type: 'scroll_update',
          tabId: tabId,
          source: "drag",
          viewportPositionFromTop: viewportPositionFromTop
        });
      }

      if (hThumbDragRef.current.dragging) {
        const deltaX = e.clientX - hThumbDragRef.current.startX;
        const trackWidth = hScrollTrackRef.current?.clientWidth || 0;
        const thumbWidth = trackWidth * scrollMetrics.horizontalThumbRatio;
        const maxThumbLeft = trackWidth - thumbWidth;
        const deltaScroll = maxThumbLeft > 0 ? (deltaX / maxThumbLeft) : 0;

        let totalWidth = 0;
        for (let i = 0; i < columns.length; i++) {
          totalWidth += columns[i]?.width || 150;
        }
        const viewportWidth = tableBodyRef.current?.clientWidth || 0;
        const maxScrollWidth = Math.max(0, totalWidth - viewportWidth);

        const viewportPositionFromLeft = Math.max(0, Math.min(maxScrollWidth,
          hThumbDragRef.current.startScroll + deltaScroll * maxScrollWidth));

        sendScrollUpdate({
          type: 'scroll_update',
          tabId: tabId,
          startCol: startCol,
          scrollLeftPixels: viewportPositionFromLeft
        });
      }
    };

    const handleMouseUp = (e) => {
      handleResizeEnd(e);
      vThumbDragRef.current = { dragging: false, startY: 0, startScroll: 0 };
      hThumbDragRef.current = { dragging: false, startX: 0, startScroll: 0 };
    };

    document.addEventListener('mousemove', handleMouseMove);
    document.addEventListener('mouseup', handleMouseUp);

    return () => {
      document.removeEventListener('mousemove', handleMouseMove);
      document.removeEventListener('mouseup', handleMouseUp);
    };
  }, [isActive, tabId, columns, startCol, visibleStartRow, topOffset, totalRows, actualRowHeight, scrollMetrics,
      handleResizeMove, handleResizeEnd, vThumbDragRef, hThumbDragRef, sendScrollUpdate]);

  // Sync header scroll with body
  useEffect(() => {
    if (tableHeaderRef.current) {
      tableHeaderRef.current.scrollLeft = leftOffset;
    }
  }, [leftOffset]);

  // Scroll track click handlers
  const handleVerticalTrackClick = (e) => {
    if (!vScrollTrackRef.current) return;

    const track = vScrollTrackRef.current;
    const trackRect = track.getBoundingClientRect();
    const clickY = e.clientY - trackRect.top;

    const trackHeight = track.clientHeight;
    const thumbHeight = trackHeight * scrollMetrics.verticalThumbRatio;
    const thumbTop = scrollMetrics.verticalThumbPosition * (trackHeight - thumbHeight);
    const thumbBottom = thumbTop + thumbHeight;

    if (clickY < thumbTop || clickY > thumbBottom) {
      const viewportHeight = tableBodyRef.current?.clientHeight || 0;
      const currentScroll = visibleStartRow * actualRowHeight + topOffset;
      const totalHeight = totalRows * actualRowHeight;
      const scrollableHeight = Math.max(0, totalHeight - viewportHeight);

      const viewportPositionFromTop = clickY < thumbTop
        ? Math.max(0, currentScroll - viewportHeight)
        : Math.min(scrollableHeight, currentScroll + viewportHeight);

      if (ws.current && ws.current.readyState === WebSocket.OPEN) {
        ws.current.send(JSON.stringify({
          type: 'scroll_update',
          tabId: tabId,
          source: "track",
          viewportPositionFromTop: viewportPositionFromTop
        }));
      }
    }
  };

  const handleVerticalThumbMouseDown = (e) => {
    e.preventDefault();
    e.stopPropagation();

    const currentScroll = visibleStartRow * actualRowHeight + topOffset;
    vThumbDragRef.current = {
      dragging: true,
      startY: e.clientY,
      startScroll: currentScroll
    };
  };

  const handleHorizontalTrackClick = (e) => {
    if (!hScrollTrackRef.current) return;

    const track = hScrollTrackRef.current;
    const trackRect = track.getBoundingClientRect();
    const clickX = e.clientX - trackRect.left;

    const trackWidth = track.clientWidth;
    const thumbWidth = trackWidth * scrollMetrics.horizontalThumbRatio;
    const thumbLeft = scrollMetrics.horizontalThumbPosition * (trackWidth - thumbWidth);
    const thumbRight = thumbLeft + thumbWidth;

    if (clickX < thumbLeft || clickX > thumbRight) {
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
      const currentScroll = scrolledWidth + leftOffset;

      const viewportPositionFromLeft = clickX < thumbLeft
        ? Math.max(0, currentScroll - viewportWidth)
        : Math.min(maxScrollWidth, currentScroll + viewportWidth);

      if (ws.current && ws.current.readyState === WebSocket.OPEN) {
        ws.current.send(JSON.stringify({
          type: 'scroll_update',
          tabId: tabId,
          startCol: startCol,
          scrollLeftPixels: viewportPositionFromLeft
        }));
      }
    }
  };

  const handleHorizontalThumbMouseDown = (e) => {
    e.preventDefault();
    e.stopPropagation();

    let scrolledWidth = 0;
    for (let i = 0; i < startCol && i < columns.length; i++) {
      scrolledWidth += columns[i]?.width || 150;
    }
    const currentScroll = scrolledWidth + leftOffset;

    hThumbDragRef.current = {
      dragging: true,
      startX: e.clientX,
      startScroll: currentScroll
    };
  };

  // Action handlers
  const autoFitColumns = () => {
    if (!tableBodyRef.current || columns.length === 0) return;

    const containerWidth = tableBodyRef.current.clientWidth;
    const visibleCols = Math.min(viewportSize.cols, columns.length);
    const newWidth = Math.floor(containerWidth / visibleCols);

    const updatedColumns = columns.map(col => ({
      ...col,
      width: Math.max(50, newWidth)
    }));

    setColumns(updatedColumns);

    if (ws.current && ws.current.readyState === WebSocket.OPEN) {
      updatedColumns.forEach((col, idx) => {
        ws.current.send(JSON.stringify({
          type: 'resize_column',
          tabId: tabId,
          colIndex: idx,
          newWidth: col.width
        }));
      });

      setTimeout(calculateViewportSize, 50);
    }
  };

  // Drag and drop handlers
  const handleDragStart = (e, colIndex) => {
    const rect = e.currentTarget.getBoundingClientRect();
    if (e.clientX > rect.right - 10) {
      e.preventDefault();
      return false;
    }

    const actualColIndex = startCol + colIndex;
    dragRef.current = {
      dragging: true,
      draggedIndex: actualColIndex,
      targetIndex: actualColIndex
    };

    e.currentTarget.classList.add('dragging');
    e.dataTransfer.effectAllowed = 'move';
    e.dataTransfer.setData('text/plain', actualColIndex.toString());
  };

  const handleDragOver = (e, colIndex) => {
    if (!dragRef.current.dragging) return;
    e.preventDefault();
    e.dataTransfer.dropEffect = 'move';

    const actualColIndex = startCol + colIndex;
    dragRef.current.targetIndex = actualColIndex;

    document.querySelectorAll('th.drag-over').forEach(el => el.classList.remove('drag-over'));
    e.currentTarget.classList.add('drag-over');
  };

  const handleDrop = (e, colIndex) => {
    e.preventDefault();
    e.stopPropagation();

    if (!dragRef.current.dragging) return;

    const draggedIdx = dragRef.current.draggedIndex;
    let targetIdx = startCol + colIndex;

    if (targetIdx >= columns.length) {
      targetIdx = columns.length - 1;
    } else if (targetIdx > draggedIdx) {
      targetIdx--;
    }

    if (draggedIdx !== targetIdx && draggedIdx >= 0 && targetIdx >= 0) {
      setColumns(prev => {
        const newCols = [...prev];
        const draggedCol = newCols[draggedIdx];
        newCols.splice(draggedIdx, 1);
        newCols.splice(targetIdx, 0, draggedCol);
        return newCols;
      });

      const newOrder = [...columnOrder];
      const draggedItem = newOrder[draggedIdx];
      newOrder.splice(draggedIdx, 1);
      newOrder.splice(targetIdx, 0, draggedItem);
      setColumnOrder(newOrder);

      if (ws.current && ws.current.readyState === WebSocket.OPEN) {
        ws.current.send(JSON.stringify({
          type: 'reorder_columns',
          tabId: tabId,
          columnOrder: newOrder
        }));
      }
    }

    document.querySelectorAll('th.dragging').forEach(el => el.classList.remove('dragging'));
    document.querySelectorAll('th.drag-over').forEach(el => el.classList.remove('drag-over'));
    dragRef.current = { dragging: false, draggedIndex: -1, targetIndex: -1 };
  };

  const handleDragEnd = () => {
    document.querySelectorAll('th.dragging').forEach(el => el.classList.remove('dragging'));
    document.querySelectorAll('th.drag-over').forEach(el => el.classList.remove('drag-over'));
    dragRef.current = { dragging: false, draggedIndex: -1, targetIndex: -1 };
  };

  if (!isActive) return null;

  return (
    <div className="tab-content active">
      <ControlsPanel
        snsSql={snsSql}
        setSnsSql={setSnsSql}
        pinByKey={pinByKey}
        setPinByKey={setPinByKey}
        appendToBottom={appendToBottom}
        setAppendToBottom={setAppendToBottom}
        opType={opType}
        setOpType={setOpType}
        onAutoFit={autoFitColumns}
        state={state}
        onStart={() => sendTabAction(ws, tabId, 'start', { snsSql, pinByKey, opType, appendToBottom })}
        onStop={() => sendTabAction(ws, tabId, 'stop')}
        onClear={() => sendTabAction(ws, tabId, 'clear')}
        onPause={() => sendTabAction(ws, tabId, 'pause')}
        onResume={() => sendTabAction(ws, tabId, 'resume')}
      />

      <DataTable
        tableData={visibleTableData}
        columns={columns}
        startRow={visibleStartRow}
        startCol={startCol}
        topOffset={topOffset}
        leftOffset={leftOffset}
        totalRows={totalRows}
        scrollMetrics={scrollMetrics}
        selectedRows={selectedRows}
        onRowClick={handleRowClick}
        onResizeStart={handleResizeStart}
        onDragStart={handleDragStart}
        onDragOver={handleDragOver}
        onDrop={handleDrop}
        onDragEnd={handleDragEnd}
        onVerticalScroll={(direction) => scrollVertical(direction, tableBodyRef)}
        onHorizontalScroll={(direction) => scrollHorizontal(direction, tableBodyRef)}
        tableContainerRef={tableContainerRef}
        tableHeaderRef={tableHeaderRef}
        tableBodyRef={tableBodyRef}
        vScrollTrackRef={vScrollTrackRef}
        hScrollTrackRef={hScrollTrackRef}
        handleVerticalTrackClick={handleVerticalTrackClick}
        handleVerticalThumbMouseDown={handleVerticalThumbMouseDown}
        handleHorizontalTrackClick={handleHorizontalTrackClick}
        handleHorizontalThumbMouseDown={handleHorizontalThumbMouseDown}
        actualRowHeight={actualRowHeight}
      />

      <StatusBar
        statusText={statusText}
        selectedCount={selectedRows.size}
      />
    </div>
  );
};