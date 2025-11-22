import React, { useState } from 'react';

export const TableHeader = ({
  columns,
  startCol,
  tableData,
  onResizeStart,
  onDragStart,
  onDragOver,
  onDrop,
  onDragEnd,
  tableHeaderRef
}) => {
  const [isDropZoneActive, setIsDropZoneActive] = useState(false);

  const numDataCols = tableData.length > 0 ? tableData[0].length : 0;
  const visibleCols = columns.slice(startCol, startCol + numDataCols);

  return (
    <div ref={tableHeaderRef} className="table-header">
      <table>
        <thead>
          <tr>
            {visibleCols.map((col, idx) => (
              <th
                key={startCol + idx}
                draggable="true"
                onDragStart={(e) => onDragStart(e, idx)}
                onDragOver={(e) => onDragOver(e, idx)}
                onDrop={(e) => onDrop(e, idx)}
                onDragEnd={onDragEnd}
                style={{
                  width: col.width || 150,
                  minWidth: col.width || 150,
                  maxWidth: col.width || 150,
                  position: 'relative'
                }}
              >
                {col.name}
                <div
                  className="resize-handle"
                  onMouseDown={(e) => onResizeStart(e, idx)}
                />

                {idx === visibleCols.length - 1 && (
                  <div
                    className="drop-zone-end-overlay"
                    style={{
                      position: 'absolute',
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: '12px',  // Same width as resize handle
                      background: isDropZoneActive ? 'rgba(59, 130, 246, 0.1)' : 'transparent',
                      borderLeft: isDropZoneActive ? '3px solid #3b82f6' : 'none',
                      pointerEvents: 'auto',
                      zIndex: 5,  // Below resize handle (which is z-index 10)
                      transition: 'all 0.2s'
                    }}
                    onDragOver={(e) => {
                      e.preventDefault();
                      e.stopPropagation();
                      e.dataTransfer.dropEffect = 'move';
                      setIsDropZoneActive(true);
                    }}
                    onDragLeave={() => {
                      setIsDropZoneActive(false);
                    }}
                    onDrop={(e) => {
                      e.preventDefault();
                      e.stopPropagation();
                      setIsDropZoneActive(false);
                      onDrop(e, visibleCols.length);
                    }}
                  />
                )}
              </th>
            ))}
          </tr>
        </thead>
      </table>
    </div>
  );
};
