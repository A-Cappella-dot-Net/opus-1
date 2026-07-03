import React, { useState, useEffect, useRef } from 'react';
import './PublisherTabContent.css';

export const PublisherTabContent = ({ tabId, isActive, ws, wsReady, tabLabel, onUpdateTabLabel, mode }) => {
  const [subject, setSubject] = useState('');
  const [message, setMessage] = useState('');
  const [statusText, setStatusText] = useState('Ready');
  const [isLoadingTemplate, setIsLoadingTemplate] = useState(false);
  const hasInitialized = useRef(false);

  useEffect(() => {
    if (!ws.current || !wsReady) return;
    const socket = ws.current;

    const handleMessage = (event) => {
      const msg = JSON.parse(event.data);

      if (msg.mode && msg.mode !== 'publisher') {
        return;
      }

      if (msg.tabId !== tabId) return;

      switch (msg.type) {
        case 'update_tab_label':
          if (onUpdateTabLabel && msg.label) {
            onUpdateTabLabel(tabId, msg.label);
          }
          break;

        case 'template_response':
          setMessage(msg.template || '');
          setIsLoadingTemplate(false);
          break;

        case 'update_status':
          setStatusText(msg.status);
          break;

        default:
          break;
      }
    };

    socket.addEventListener('message', handleMessage);

    // Only send init message for active tab
    if (!hasInitialized.current && isActive) {
      hasInitialized.current = true;

      // Use setTimeout to ensure WebSocket is fully ready
      setTimeout(() => {
        if (ws.current && ws.current.readyState === WebSocket.OPEN) {
          console.log('Sending init_publisher_tab for', tabId);

          ws.current.send(JSON.stringify({
            type: 'init_publisher_tab',
            tabId: tabId,
            mode: 'publisher'
          }));
        } else {
          console.error('WebSocket not ready, state:', ws.current?.readyState);
        }
      }, 100);  // 100ms delay
    }

    return () => {
      socket.removeEventListener('message', handleMessage);
    };
  }, [isActive, tabId, wsReady, onUpdateTabLabel, ws]);

  // Separate useEffect for Publish All event listener
  useEffect(() => {
    const handleCollectData = () => {
      if (subject.trim() || message.trim()) {
        const dataEvent = new CustomEvent('publish-data-response', {
          detail: {
            tabId: tabId,
            subject: subject,
            message: message
          }
        });
        window.dispatchEvent(dataEvent);
      }
    };

    window.addEventListener('collect-publish-data', handleCollectData);

    return () => {
      window.removeEventListener('collect-publish-data', handleCollectData);
    };
  }, [tabId, subject, message]);

  const handleTemplate = () => {
    if (!subject.trim()) {
      setStatusText('Error: Subject is required');
      return;
    }

    setIsLoadingTemplate(true);
    setStatusText('Loading template...');

    if (ws.current && ws.current.readyState === WebSocket.OPEN) {
      ws.current.send(JSON.stringify({
        type: 'request_template',
        tabId: tabId,
        mode: 'publisher',
        subject: subject
      }));
    }
  };

  const handlePublish = () => {
    if (!subject.trim()) {
      setStatusText('Error: Subject is required');
      return;
    }

    if (!message.trim()) {
      setStatusText('Error: Message is empty');
      return;
    }

    setStatusText('Publishing...');

    if (ws.current && ws.current.readyState === WebSocket.OPEN) {
      ws.current.send(JSON.stringify({
        type: 'publish',
        tabId: tabId,
        mode: 'publisher',
        subject: subject,
        message: message
      }));
    }
  };

  return (
    <div
      className={`publisher-tab-content ${isActive ? 'active' : ''}`}
      data-publisher-tab={tabId}
      style={{ display: isActive ? 'flex' : 'none' }}  // Hide with CSS instead
    >
      <div className="publisher-controls">
        <div className="subject-row">
          <label htmlFor={`subject-${tabId}`} className="subject-label">Subject:</label>
          <input
            id={`subject-${tabId}`}
            type="text"
            value={subject}
            onChange={(e) => setSubject(e.target.value)}
            className="subject-input"
            placeholder="Enter subject..."
          />
        </div>

        <div className="message-container">
          <textarea
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            className="message-textarea"
            placeholder="Click 'Template' to load a template, or type your message here..."
          />
        </div>

        <div className="button-row">
          <button
            onClick={handleTemplate}
            className="btn btn-orange"
            disabled={isLoadingTemplate || !subject.trim()}
          >
            {isLoadingTemplate ? 'Loading...' : 'Template'}
          </button>
          <button
            onClick={handlePublish}
            className="btn btn-blue"
            disabled={!subject.trim() || !message.trim()}
          >
            Publish
          </button>
        </div>
      </div>

      <div className="publisher-status-bar">
        {statusText}
      </div>
    </div>
  );
};