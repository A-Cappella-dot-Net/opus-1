import React from 'react';
import './ControlsPanel.css';

export const ControlsPanel = ({
  snsSql,
  setSnsSql,
  pinByKey,
  setPinByKey,
  appendToBottom,
  setAppendToBottom,
  opType,
  setOpType,
  onAutoFit,
  state,
  onStart,
  onStop,
  onClear,
  onPause,
  onResume
}) => {
  // Determine if controls should be editable (only in 'new' state)
  const isEditable = state === 'new';

  // Determine which buttons to show based on state
  const showStart = state === 'new';
  const showStop = state === 'running' || state === 'paused';
  const showClear = state === 'stopped';
  const showPause = state === 'running';
  const showResume = state === 'paused';

  return (
    <div className="controls-panel">
      <div className="control-row">
        <input
          type="text"
          value={snsSql}
          onChange={(e) => setSnsSql(e.target.value)}
          className="text-input"
          placeholder="Enter sql..."
          disabled={!isEditable}
        />

        {/* Pin By Key - Single Toggle Button */}
        <div className="segmented-control">
          <button
            onClick={() => setPinByKey(!pinByKey)}
            className={`segment-button single ${pinByKey ? 'selected' : ''}`}
            disabled={!isEditable}
            title="When enabled, pins rows by their key column to maintain position"
          >
            Pin By Key
          </button>
        </div>
      </div>

      <div className="control-row">
        {/* Add to - Two Button Segmented Control */}
        <div className="segmented-control">
          <button
            onClick={() => setAppendToBottom(false)}
            className={`segment-button left ${!appendToBottom ? 'selected' : ''}`}
            disabled={!isEditable}
            title="Add new rows to the top of the table"
          >
            Top
          </button>
          <button
            onClick={() => setAppendToBottom(true)}
            className={`segment-button right ${appendToBottom ? 'selected' : ''}`}
            disabled={!isEditable}
            title="Add new rows to the bottom of the table"
          >
            Bottom
          </button>
        </div>

        {/* Action - Three Button Segmented Control */}
        <div className="segmented-control">
          <button
            onClick={() => setOpType('snapSubscribe')}
            className={`segment-button left ${opType === 'snapSubscribe' ? 'selected' : ''}`}
            disabled={!isEditable}
            title="Take a snapshot of current data and subscribe to future updates"
          >
            Snap & Subscribe
          </button>
          <button
            onClick={() => setOpType('snap')}
            className={`segment-button middle ${opType === 'snap' ? 'selected' : ''}`}
            disabled={!isEditable}
            title="Take a one-time snapshot of current data only"
          >
            Snap
          </button>
          <button
            onClick={() => setOpType('subscribe')}
            className={`segment-button right ${opType === 'subscribe' ? 'selected' : ''}`}
            disabled={!isEditable}
            title="Subscribe to future updates without initial snapshot"
          >
            Subscribe
          </button>
        </div>
      </div>

      <div className="control-row">
        <button onClick={onAutoFit} className="btn btn-purple">
          Auto-Fit Columns
        </button>
        {/* First button group: Start/Stop/Clear */}
        <div className="button-group">
          {showStart && (
            <button onClick={onStart} className="btn btn-green">
              Start
            </button>
          )}
          {showStop && (
            <button onClick={onStop} className="btn btn-red">
              Stop
            </button>
          )}
          {showClear && (
            <button onClick={onClear} className="btn btn-gray">
              Clear
            </button>
          )}
        </div>

        {/* Second button group: Pause/Resume */}
        <div className="button-group">
          {showPause && (
            <button onClick={onPause} className="btn btn-orange">
              Pause
            </button>
          )}
          {showResume && (
            <button onClick={onResume} className="btn btn-blue">
              Resume
            </button>
          )}
        </div>
      </div>
    </div>
  );
};