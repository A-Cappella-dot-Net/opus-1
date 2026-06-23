import React from 'react';
import './StatusBar.css';

export const StatusBar = ({ statusText, selectedCount }) => {
  return (
    <div className="status-bar">
      {statusText}
      {selectedCount > 0 && (
        <span className="selection-info">
          | {selectedCount} row{selectedCount !== 1 ? 's' : ''} selected
        </span>
      )}
    </div>
  );
};