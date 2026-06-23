import React from 'react';
import './TabBar.css';

export const TabBar = ({ tabs, activeTab, onTabChange, onTabClose, onAddTab }) => {
  return (
    <div className="tab-bar">
      {tabs.map(tab => (
        <div
          key={tab.id}
          className={`tab ${activeTab === tab.id ? 'active' : ''}`}
        >
          <span onClick={() => onTabChange(tab.id)}>{tab.label}</span>
          {tabs.length > 1 && (
            <span
              className="tab-close"
              onClick={(e) => {
                e.stopPropagation();
                onTabClose(tab.id);
              }}
            >
              ×
            </span>
          )}
        </div>
      ))}
      <button onClick={onAddTab} className="add-tab-btn">
        + Add Tab
      </button>
    </div>
  );
};
