import React, { useState } from 'react';
import './ModeSelector.css';


export const ModeSelector = ({ onModeSelect, username, ws }) => {
  const [isLoading, setIsLoading] = useState(false);

  const requestAuthToken = () => {
    return new Promise((resolve) => {
      if (!ws.current || ws.current.readyState !== WebSocket.OPEN) {
        console.error('WebSocket not connected');
        resolve(null);
        return;
      }

      const messageHandler = (event) => {
        try {
          const data = JSON.parse(event.data);
          if (data.type === 'token_response') {
            ws.current.removeEventListener('message', messageHandler);
            resolve(data.token);
          } else if (data.type === 'error' && data.context === 'token_request') {
            ws.current.removeEventListener('message', messageHandler);
            console.error('Token request failed:', data.message);
            resolve(null);
          }
        } catch (error) {
          console.error('Error parsing message:', error);
        }
      };

      ws.current.addEventListener('message', messageHandler);

      ws.current.send(JSON.stringify({
        type: 'request_token'
      }));

      // Timeout after 5 seconds
      setTimeout(() => {
        ws.current.removeEventListener('message', messageHandler);
        resolve(null);
      }, 5000);
    });
  };

  const handleOpenBoth = async () => {
    setIsLoading(true);

    // Request a token from the server first
    const token = await requestAuthToken();

    setIsLoading(false);

    if (!token) {
      alert('Failed to get authentication token. Please try again.');
      return;
    }

    // Open subscriber in current window
    onModeSelect('subscriber');

    // Open publisher in new window with TOKEN
    const publisherUrl = `${window.location.origin}?mode=publisher&token=${encodeURIComponent(token)}`;
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
            disabled={isLoading}
          >
            <div className="button-icon">📊</div>
            <div className="button-title">Open Subscriber</div>
            <div className="button-description">Subscribe to data streams</div>
          </button>

          <button
            onClick={() => onModeSelect('publisher')}
            className="mode-button publisher-button"
            disabled={isLoading}
          >
            <div className="button-icon">📤</div>
            <div className="button-title">Open Publisher</div>
            <div className="button-description">Publish messages</div>
          </button>

          <button
            onClick={handleOpenBoth}
            className="mode-button both-button"
            disabled={isLoading}
          >
            <div className="button-icon">{isLoading ? '⏳' : '🔄'}</div>
            <div className="button-title">
              {isLoading ? 'Opening...' : 'Open Both'}
            </div>
            <div className="button-description">
              Subscriber here, Publisher in new window
            </div>
          </button>
        </div>
      </div>
    </div>
  );
};