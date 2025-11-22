import React from 'react';
import { TableHeader } from './TableHeader';
import { TableBody } from './TableBody';
import { CustomScrollbar } from './CustomScrollbar';
import { ROW_HEIGHT } from '../../constants';
import './DataTable.css';

export const DataTable = ({
  tableData,
  columns,
  startRow,
  startCol,
  topOffset,
  leftOffset,
  totalRows,
  scrollMetrics,
  selectedRows,
  onRowClick,
  onResizeStart,
  onDragStart,
  onDragOver,
  onDrop,
  onDragEnd,
  onVerticalScroll,
  onHorizontalScroll,
  tableContainerRef,
  tableHeaderRef,
  tableBodyRef,
  vScrollTrackRef,
  hScrollTrackRef,
  handleVerticalTrackClick,
  handleVerticalThumbMouseDown,
  handleHorizontalTrackClick,
  handleHorizontalThumbMouseDown
}) => {
  const totalHeight = totalRows * ROW_HEIGHT;
  const viewportHeight = tableBodyRef.current?.clientHeight || 0;
  const showVerticalScroll = totalHeight > viewportHeight;

  let totalColumnsWidth = 0;
  for (let i = 0; i < columns.length; i++) {
    totalColumnsWidth += columns[i]?.width || 150;
  }
  const viewportWidth = tableBodyRef.current?.clientWidth || 0;
  const showHorizontalScroll = totalColumnsWidth > viewportWidth;

  return (
    <div className="table-container" ref={tableContainerRef}>
      <div className="table-wrapper">
        <div className="table-main">
          <TableHeader
            columns={columns}
            startCol={startCol}
            tableData={tableData}
            onResizeStart={onResizeStart}
            onDragStart={onDragStart}
            onDragOver={onDragOver}
            onDrop={onDrop}
            onDragEnd={onDragEnd}
            tableHeaderRef={tableHeaderRef}
          />

          <TableBody
            tableData={tableData}
            columns={columns}
            startRow={startRow}
            startCol={startCol}
            topOffset={topOffset}
            leftOffset={leftOffset}
            selectedRows={selectedRows}
            onRowClick={onRowClick}
            tableBodyRef={tableBodyRef}
          />

          {showHorizontalScroll && (
            <CustomScrollbar
              direction="horizontal"
              thumbRatio={scrollMetrics.horizontalThumbRatio}
              thumbPosition={scrollMetrics.horizontalThumbPosition}
              onTrackClick={handleHorizontalTrackClick}
              onThumbMouseDown={handleHorizontalThumbMouseDown}
              onScrollClick={onHorizontalScroll}
              trackRef={hScrollTrackRef}
            />
          )}
        </div>

        {showVerticalScroll && (
          <CustomScrollbar
            direction="vertical"
            thumbRatio={scrollMetrics.verticalThumbRatio}
            thumbPosition={scrollMetrics.verticalThumbPosition}
            onTrackClick={handleVerticalTrackClick}
            onThumbMouseDown={handleVerticalThumbMouseDown}
            onScrollClick={onVerticalScroll}
            trackRef={vScrollTrackRef}
          />
        )}
      </div>
    </div>
  );
};