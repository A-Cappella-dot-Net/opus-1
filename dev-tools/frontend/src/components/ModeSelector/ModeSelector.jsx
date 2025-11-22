import React from 'react';
import './ModeSelector.css';

export const ModeSelector = ({ onModeSelect, username }) => {
  const handleOpenBoth = () => {
    // Open subscriber in current window
    onModeSelect('subscriber');

    // Open publisher in new window with mode in URL
    const username = sessionStorage.getItem('username');
    const publisherUrl = `${window.location.origin}?mode=publisher&username=${encodeURIComponent(username)}&autoAuth=true`;
    window.open(publisherUrl, '_blank');
  };

  return (
    <div className="mode-selector-container">
      <div className="mode-selector-box">
        <h1>View Client</h1>
        <p className="welcome-text">Welcome, {username}!</p>
        <p className="instruction-text">Choose your mode:</p>

        <div className="mode-buttons">
          <button
            onClick={() => onModeSelect('subscriber')}
            className="mode-button subscriber-button"
          >
            <div className="button-icon">📊</div>
            <div className="button-title">Open Subscriber</div>
            <div className="button-description">Subscribe to data streams</div>
          </button>

          <button
            onClick={() => onModeSelect('publisher')}
            className="mode-button publisher-button"
          >
            <div className="button-icon">📤</div>
            <div className="button-title">Open Publisher</div>
            <div className="button-description">Publish messages</div>
          </button>

          <button
            onClick={handleOpenBoth}
            className="mode-button both-button"
          >
            <div className="button-icon">🔄</div>
            <div className="button-title">Open Both</div>
            <div className="button-description">Subscriber here, Publisher in new window</div>
          </button>
        </div>
      </div>
    </div>
  );
};