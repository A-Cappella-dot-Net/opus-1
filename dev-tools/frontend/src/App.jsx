import React, { useState, useEffect } from 'react';
import { TabBar } from './components/TabBar/TabBar';
import { TabContent } from './components/TabContent/TabContent';
import { PublisherTabContent } from './components/Publisher/PublisherTabContent';
import { Login } from './components/Login/Login';
import { ModeSelector } from './components/ModeSelector/ModeSelector';
import { useWebSocket } from './hooks/useWebSocket';
import './App.css';

const App = () => {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [username, setUsername] = useState(null);
  const [mode, setMode] = useState(null); // null, 'subscriber', or 'publisher'

  const [tabs, setTabs] = useState([{ id: 'tab-1', label: 'Tab 1' }]);
  const [activeTab, setActiveTab] = useState('tab-1');
  const [tabCounter, setTabCounter] = useState(1);

  const { ws, wsReady } = useWebSocket();

  useEffect(() => {
    // Check URL parameters first
    const urlParams = new URLSearchParams(window.location.search);
    const urlMode = urlParams.get('mode');
    const urlUsername = urlParams.get('username');
    const autoAuth = urlParams.get('autoAuth');

    // Then check sessionStorage
    const isAuth = sessionStorage.getItem('isAuthenticated');
    const user = sessionStorage.getItem('username');
    const savedMode = sessionStorage.getItem('mode');

    // If URL has auto-auth params, set them up
    if (autoAuth === 'true' && urlUsername && urlMode) {
      sessionStorage.setItem('isAuthenticated', 'true');
      sessionStorage.setItem('username', urlUsername);
      sessionStorage.setItem('mode', urlMode);

      setUsername(urlUsername);
      setIsAuthenticated(true);
      setMode(urlMode);

      // Clean up URL
      window.history.replaceState({}, '', window.location.pathname);

      if (ws.current && ws.current.readyState === WebSocket.OPEN) {
        ws.current.send(JSON.stringify({
          type: 'reauth',
          username: urlUsername
        }));
      }
    } else if (isAuth === 'true' && user) {
      setUsername(user);
      setIsAuthenticated(true);

      if (savedMode) {
        setMode(savedMode);
      }

      if (ws.current && ws.current.readyState === WebSocket.OPEN) {
        ws.current.send(JSON.stringify({
          type: 'reauth',
          username: user
        }));
      }
    }
  }, [ws, wsReady]);

  const handleLoginSuccess = (user) => {
    setUsername(user);
    setIsAuthenticated(true);
  };

  const handleModeSelect = (selectedMode) => {
    setMode(selectedMode);
    sessionStorage.setItem('mode', selectedMode);
  };

  const handleLogout = () => {
    sessionStorage.removeItem('isAuthenticated');
    sessionStorage.removeItem('username');
    sessionStorage.removeItem('mode');
    setUsername(null);
    setIsAuthenticated(false);
    setMode(null);

    if (ws.current && ws.current.readyState === WebSocket.OPEN) {
      ws.current.send(JSON.stringify({
        type: 'logout'
      }));
    }
  };

  const handleBackToModeSelect = () => {
    setMode(null);
    sessionStorage.removeItem('mode');
  };

  const addTab = () => {
    const newCounter = tabCounter + 1;
    const newTab = { id: `tab-${newCounter}`, label: `Tab ${newCounter}` };
    setTabs([...tabs, newTab]);
    setTabCounter(newCounter);
    setActiveTab(newTab.id);
  };

  const removeTab = (tabId) => {
    if (tabs.length === 1) return;

    const newTabs = tabs.filter(t => t.id !== tabId);
    setTabs(newTabs);

    if (activeTab === tabId) {
      setActiveTab(newTabs[0].id);
    }

    if (ws.current && ws.current.readyState === WebSocket.OPEN) {
      ws.current.send(JSON.stringify({
        type: 'close_tab',
        tabId: tabId,
        mode: mode
      }));
    }
  };

  const updateTabLabel = (tabId, newLabel) => {
    setTabs(prevTabs =>
      prevTabs.map(tab =>
        tab.id === tabId ? { ...tab, label: newLabel } : tab
      )
    );
  };

  const handlePublishAll = () => {
    if (!ws.current || ws.current.readyState !== WebSocket.OPEN) {
      console.error('WebSocket not connected');
      return;
    }

    // Create a custom event that tabs will respond to
    const publishAllEvent = new CustomEvent('collect-publish-data');
    const collectedData = [];

    // Set up a one-time listener for responses
    const handleDataCollection = (event) => {
      collectedData.push(event.detail);
    };

    window.addEventListener('publish-data-response', handleDataCollection);

    // Dispatch the collection request
    window.dispatchEvent(publishAllEvent);

    // Wait a bit for all tabs to respond
    setTimeout(() => {
      window.removeEventListener('publish-data-response', handleDataCollection);

      // Filter out empty data
      const validData = collectedData.filter(data =>
        data.subject.trim() && data.message.trim()
      );

      if (validData.length === 0) {
        console.log('No valid tabs to publish');
        return;
      }

      ws.current.send(JSON.stringify({
        type: 'publish_all',
        mode: 'publisher',
        tabs: validData
      }));
    }, 100);
  };

  // Show login screen if not authenticated
  if (!isAuthenticated) {
    return <Login ws={ws} onLoginSuccess={handleLoginSuccess} />;
  }

  // Show mode selector if authenticated but no mode selected
  if (!mode) {
    return <ModeSelector onModeSelect={handleModeSelect} username={username} />;
  }

  // Show subscriber or publisher based on mode
  return (
    <div className="app-container">
      <div className="app-header">
        <div className="mode-indicator">
          Mode: <strong>{mode === 'subscriber' ? 'Subscriber' : 'Publisher'}</strong>
        </div>
        <div className="user-info">
          Welcome, {username}
          <button onClick={handleBackToModeSelect} className="mode-btn">
            Change Mode
          </button>
          <button onClick={handleLogout} className="logout-btn">
            Logout
          </button>
        </div>
      </div>

      <TabBar
        tabs={tabs}
        activeTab={activeTab}
        onTabChange={setActiveTab}
        onTabClose={removeTab}
        onAddTab={addTab}
      />

      {mode === 'subscriber' ? (
        tabs.map(tab => (
          <TabContent
            key={tab.id}
            tabId={tab.id}
            isActive={activeTab === tab.id}
            ws={ws}
            wsReady={wsReady}
            tabLabel={tab.label}
            onUpdateTabLabel={updateTabLabel}
            mode="subscriber"
          />
        ))
      ) : (
        tabs.map(tab => (
          <PublisherTabContent
            key={tab.id}
            tabId={tab.id}
            isActive={activeTab === tab.id}
            ws={ws}
            wsReady={wsReady}
            tabLabel={tab.label}
            onUpdateTabLabel={updateTabLabel}
            mode="publisher"
          />
        ))
      )}

      {mode === 'publisher' && (
        <div className="publish-all-container">
          <button
            onClick={handlePublishAll}
            className="btn btn-blue publish-all-btn"
          >
            Publish All
          </button>
        </div>
      )}
    </div>
  );
};

export default App;