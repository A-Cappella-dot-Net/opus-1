import React from 'react';
import './ControlsPanel.css';

export const ControlsPanel = ({
  snsSql,
  setSnsSql,
  pinByKey,
  setPinByKey,
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
        <label className={`checkbox-label ${!isEditable ? 'disabled' : ''}`}>
          <input
            type="checkbox"
            checked={pinByKey}
            onChange={(e) => setPinByKey(e.target.checked)}
            disabled={!isEditable}
          />
          Pin By Key
        </label>
      </div>

      <div className="control-row">
        <label className={`radio-label ${!isEditable ? 'disabled' : ''}`}>
          <input
            type="radio"
            value="snapSubscribe"
            checked={opType === 'snapSubscribe'}
            onChange={(e) => setOpType(e.target.value)}
            disabled={!isEditable}
          />
          Snap & Subscribe
        </label>
        <label className={`radio-label ${!isEditable ? 'disabled' : ''}`}>
          <input
            type="radio"
            value="snap"
            checked={opType === 'snap'}
            onChange={(e) => setOpType(e.target.value)}
            disabled={!isEditable}
          />
          Snap
        </label>
        <label className={`radio-label ${!isEditable ? 'disabled' : ''}`}>
          <input
            type="radio"
            value="subscribe"
            checked={opType === 'subscribe'}
            onChange={(e) => setOpType(e.target.value)}
            disabled={!isEditable}
          />
          Subscribe
        </label>
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