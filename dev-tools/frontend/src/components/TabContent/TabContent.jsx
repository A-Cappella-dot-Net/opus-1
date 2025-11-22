import React, { useState, useEffect, useRef, useCallback } from 'react';
import { ControlsPanel } from '../ControlsPanel/ControlsPanel';
import { DataTable } from '../DataTable/DataTable';
import { StatusBar } from '../StatusBar/StatusBar';
import { useTableScroll } from '../../hooks/useTableScroll';
import { useColumnResize } from '../../hooks/useColumnResize';
import { useRowSelection } from '../../hooks/useRowSelection';
import { sendTabAction } from '../../utils/websocketHelpers';
import { ROW_HEIGHT } from '../../constants';
import './TabContent.css';

export const TabContent = ({ tabId, isActive, ws, wsReady, tabLabel, onUpdateTabLabel }) => {
  const [snsSql, setSnsSql] = useState('');
  const [pinByKey, setPinByKey] = useState(false);
  const [opType, setOpType] = useState('snapSubscribe');
  const [statusText, setStatusText] = useState('Not snapped / subscribed yet...');
  const [state, setState] = useState('new');

  const [tableData, setTableData] = useState([]);
  const [startRow, setStartRow] = useState(0);
  const [startCol, setStartCol] = useState(0);
  const [topOffset, setTopOffset] = useState(0);
  const [leftOffset, setLeftOffset] = useState(0);
  const [totalRows, setTotalRows] = useState(0);
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
  const tableContainerRef = useRef(null);
  const vScrollTrackRef = useRef(null);
  const hScrollTrackRef = useRef(null);
  const resizeTimeoutRef = useRef(null);
  const lastViewportDimensionsRef = useRef({ width: 0, height: 0 });
  const dragRef = useRef({ dragging: false, draggedIndex: -1, targetIndex: -1 });
  const hasInitialized = useRef(false);

  // Use custom hooks
  const { selectedRows, handleRowClick, clearSelection, setSelectedRows, setLastSelectedRow } =
    useRowSelection(startRow);

  const { scrollVertical, scrollHorizontal, vThumbDragRef, hThumbDragRef } =
    useTableScroll(tabId, ws, startRow, startCol, topOffset, totalRows, columns);

  const { handleResizeStart, handleResizeMove, handleResizeEnd } =
    useColumnResize(tabId, ws, startCol, columns, setColumns);

  // WebSocket message handler
  useEffect(() => {
    if (!ws.current || !wsReady) return;

    const handleMessage = (event) => {
      const msg = JSON.parse(event.data);

      // Filter messages by mode - only process subscriber messages
      if (msg.mode && msg.mode !== 'subscriber') {
        return; // Ignore messages meant for other modes
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

        case 'meta_data':
          setTotalRows(msg.totalRows || 0);
          setTotalCols(msg.totalCols || 0);
          setColumns(msg.columns || []);
          if (msg.columns && msg.columns.length > 0) {
            setColumnOrder(msg.columns.map((_, idx) => idx));
          }
          break;

        case 'viewport_data':
          setTableData(msg.data || []);
          setStartRow(msg.startRow || 0);
          setStartCol(msg.startCol || 0);
          setTopOffset(msg.topOffset || 0);
          setLeftOffset(msg.leftOffset || 0);
          setTotalRows(msg.totalRows || 0);
          setTotalCols(msg.totalCols || 0);
          setScrollMetrics({
            verticalThumbRatio: msg.verticalThumbRatio || 1,
            verticalThumbPosition: msg.verticalThumbPosition || 0,
            horizontalThumbRatio: msg.horizontalThumbRatio || 1,
            horizontalThumbPosition: msg.horizontalThumbPosition || 0
          });
          break;

        case 'column_update':
          setTotalCols((msg.columns || []).length);
          setColumns(msg.columns || []);
          setColumnOrder((msg.columns || []).map((_, idx) => idx));
          break;

        case 'cell_update':
          setTableData(prev => {
            const rowIdx = msg.row - startRow;
            const colIdx = msg.col - startCol;
            if (rowIdx >= 0 && rowIdx < prev.length && colIdx >= 0 && colIdx < prev[0]?.length) {
              const newData = [...prev];
              newData[rowIdx] = [...newData[rowIdx]];
              newData[rowIdx][colIdx] = msg.value;
              return newData;
            }
            return prev;
          });
          break;

        case 'clear_table':
          setTableData([]);
          setColumns([]);
          setColumnOrder([]);
          setStartRow(0);
          setStartCol(0);
          setTotalRows(0);
          setTotalCols(0);
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
        if (ws.current && ws.current.readyState === WebSocket.OPEN) {
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
  }, [isActive, tabId, wsReady, onUpdateTabLabel, startRow, startCol, clearSelection, ws]);

  // Reset hasInitialized on unmount (for page refresh)
  useEffect(() => {
    return () => {
      hasInitialized.current = false;
    };
  }, []);

  // Viewport calculation
  const calculateViewportSize = useCallback(() => {
    if (!tableBodyRef.current) return;

    const viewportHeight = tableBodyRef.current.clientHeight;
    const viewportWidth = tableBodyRef.current.clientWidth;

    const rows = Math.max(1, Math.ceil(viewportHeight / ROW_HEIGHT));
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
  }, [tabId, columns, ws]);

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
      const totalHeight = totalRows * ROW_HEIGHT;
      const deltaScroll =
         e.deltaMode === 1 ? e.deltaY * ROW_HEIGHT :
         e.deltaMode === 2 ? e.deltaY * ROW_HEIGHT * Math.floor(viewportHeight / ROW_HEIGHT) :
         e.deltaY;
      const currentScroll = startRow * ROW_HEIGHT + topOffset;
      const scrollableHeight = Math.max(0, totalHeight - viewportHeight);
      const viewportPositionFromTop = Math.max(0, Math.min(scrollableHeight, currentScroll + deltaScroll));

      if (viewportPositionFromTop !== currentScroll && ws.current && ws.current.readyState === WebSocket.OPEN) {
        ws.current.send(JSON.stringify({
          type: 'scroll_update',
          tabId: tabId,
          startCol: startCol,
          viewportPositionFromTop: viewportPositionFromTop
        }));
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
  }, [isActive, calculateViewportSize, startRow, topOffset, totalRows, tabId, startCol, ws]);

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

        const totalHeight = totalRows * ROW_HEIGHT;
        const viewportHeight = tableBodyRef.current?.clientHeight || 0;
        const scrollableHeight = Math.max(0, totalHeight - viewportHeight);

        const viewportPositionFromTop =
          Math.max(0, Math.min(scrollableHeight, vThumbDragRef.current.startScroll + deltaScroll * scrollableHeight));

        if (ws.current && ws.current.readyState === WebSocket.OPEN) {
          ws.current.send(JSON.stringify({
            type: 'scroll_update',
            tabId: tabId,
            startCol: startCol,
            viewportPositionFromTop: viewportPositionFromTop
          }));
        }
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

        console.log('maxScrollWidth=', maxScrollWidth, ' hThumbDragRef.current.startScroll=', hThumbDragRef.current.startScroll, ' deltaScroll=', deltaScroll);

        const viewportPositionFromLeft = Math.max(0, Math.min(maxScrollWidth,
          hThumbDragRef.current.startScroll + deltaScroll * maxScrollWidth));

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
  }, [isActive, tabId, columns, startCol, startRow, topOffset, totalRows, scrollMetrics,
      handleResizeMove, handleResizeEnd, vThumbDragRef, hThumbDragRef, ws]);

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
      const currentScroll = startRow * ROW_HEIGHT + topOffset;
      const totalHeight = totalRows * ROW_HEIGHT;
      const scrollableHeight = Math.max(0, totalHeight - viewportHeight);

      const viewportPositionFromTop = clickY < thumbTop
        ? Math.max(0, currentScroll - viewportHeight)
        : Math.min(scrollableHeight, currentScroll + viewportHeight);

      if (ws.current && ws.current.readyState === WebSocket.OPEN) {
        ws.current.send(JSON.stringify({
          type: 'scroll_update',
          tabId: tabId,
          startCol: startCol,
          viewportPositionFromTop: viewportPositionFromTop
        }));
      }
    }
  };

  const handleVerticalThumbMouseDown = (e) => {
    e.preventDefault();
    e.stopPropagation();

    const currentScroll = startRow * ROW_HEIGHT + topOffset;
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
        opType={opType}
        setOpType={setOpType}
        onAutoFit={autoFitColumns}
        state={state}
        onStart={() => sendTabAction(ws, tabId, 'start', { snsSql, pinByKey, opType })}
        onStop={() => sendTabAction(ws, tabId, 'stop')}
        onClear={() => sendTabAction(ws, tabId, 'clear')}
        onPause={() => sendTabAction(ws, tabId, 'pause')}
        onResume={() => sendTabAction(ws, tabId, 'resume')}
      />

      <DataTable
        tableData={tableData}
        columns={columns}
        startRow={startRow}
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
      />

      <StatusBar
        statusText={statusText}
        selectedCount={selectedRows.size}
      />
    </div>
  );
};