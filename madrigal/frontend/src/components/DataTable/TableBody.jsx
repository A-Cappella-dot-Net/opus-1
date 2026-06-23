import React from 'react';
import { formatCellValue, getCellAlignment, getCellClassName } from '../../utils/cellFormatters';

export const TableBody = ({
  tableData,
  columns,
  startRow,
  startCol,
  topOffset,
  leftOffset,
  selectedRows,
  onRowClick,
  tableBodyRef
}) => {
  return (
    <div className="table-body" ref={tableBodyRef}>
      <div className="table-body-inner" style={{ marginTop: `-${topOffset}px` }}>
        <table style={{ marginLeft: `-${leftOffset}px` }}>
          <tbody>
            {tableData.map((row, rowIdx) => {
              const absoluteRowIndex = startRow + rowIdx;
              const isSelected = selectedRows.has(absoluteRowIndex);
              return (
                <tr
                  key={absoluteRowIndex}
                  className={isSelected ? 'selected' : ''}
                  onClick={(e) => onRowClick(e, rowIdx)}
                  style={{ cursor: 'pointer' }}
                >
                  {row.map((cell, colIdx) => {
                    const column = columns[startCol + colIdx];
                    const formattedValue = formatCellValue(cell, column || {});
                    const alignment = getCellAlignment(column || {});
                    const cellClass = getCellClassName(cell, column || {});

                    return (
                      <td
                        key={startCol + colIdx}
                        className={cellClass}
                        style={{
                          width: column?.width || 150,
                          minWidth: column?.width || 150,
                          maxWidth: column?.width || 150,
                          textAlign: alignment
                        }}
                        title={formattedValue} // Show full value on hover
                      >
                        {formattedValue}
                      </td>
                    );
                  })}
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
};