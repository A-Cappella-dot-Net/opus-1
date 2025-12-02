import React, { useState, useEffect, useCallback } from 'react';
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
  const [mode, setMode] = useState(null);
  const [pendingTokenAuth, setPendingTokenAuth] = useState(false);
  const [reauthPending, setReauthPending] = useState(false);

  const [tabs, setTabs] = useState([{ id: 'tab-1', label: 'Tab 1' }]);
  const [activeTab, setActiveTab] = useState('tab-1');
  const [tabCounter, setTabCounter] = useState(1);

  console.log('=== App render ===', { isAuthenticated, username, mode });

  // Handle authentication errors from the server
  const handleAuthError = useCallback(() => {
//     console.log('Clearing authentication due to server error');
    console.log('=== handleAuthError called ===');
    console.log('Current state:', { isAuthenticated, username, mode });

    sessionStorage.removeItem('isAuthenticated');
    sessionStorage.removeItem('username');
    sessionStorage.removeItem('mode');

    console.log('SessionStorage cleared');

    setUsername(null);
    setIsAuthenticated(false);
    setMode(null);

    console.log('State setters called');
  }, [isAuthenticated, username, mode]);

  const { ws, wsReady, isConnected } = useWebSocket(handleAuthError);

  // Listen for permanent connection failures
  useEffect(() => {
    const handleConnectionFailed = () => {
      console.log('Max reconnection attempts reached - clearing session and showing login');
      // Clear session and redirect to login instead of asking user to refresh
      sessionStorage.clear();
      setUsername(null);
      setIsAuthenticated(false);
      setMode(null);
      setReauthPending(false);
      setPendingTokenAuth(false);
      alert('Unable to connect to server. Please log in again.');
    };

    window.addEventListener('websocket-connection-failed', handleConnectionFailed);
    return () => {
      window.removeEventListener('websocket-connection-failed', handleConnectionFailed);
    };
  }, []);

  // Initial setup: check URL params for token auth OR sessionStorage for existing session
  useEffect(() => {
    const urlParams = new URLSearchParams(window.location.search);
    const urlMode = urlParams.get('mode');
    const token = urlParams.get('token');

    console.log('Initial setup - URL params:', { urlMode, token: token ? 'present' : 'none' });

    // Token-based auth (new window from "Open Both")
    if (token && urlMode) {
      console.log('Found token in URL, setting up for token auth');
      sessionStorage.setItem('pending_token', token);
      sessionStorage.setItem('mode', urlMode);
      setMode(urlMode);
      setPendingTokenAuth(true);

      // Clean up URL
      window.history.replaceState({}, '', window.location.pathname);
    } else {
      // Check for existing session (page refresh)
      const isAuth = sessionStorage.getItem('isAuthenticated');
      const user = sessionStorage.getItem('username');
      const savedMode = sessionStorage.getItem('mode');

      console.log('Checking sessionStorage:', { isAuth, user, savedMode });

      if (isAuth === 'true' && user) {
        console.log('Found existing session, setting reauthPending=true');
        setUsername(user);
        setIsAuthenticated(true);
        setReauthPending(true);

        if (savedMode) {
          setMode(savedMode);
        }
      }
    }
  }, []);

  // Handle token-based authentication when WebSocket is ready
  useEffect(() => {
    console.log('Token auth effect:', { wsReady, hasCurrent: !!ws.current, pendingTokenAuth });

    if (!wsReady || !ws.current || !pendingTokenAuth) return;

    const pendingToken = sessionStorage.getItem('pending_token');
    console.log('Pending token from storage:', pendingToken);

    if (pendingToken) {
      console.log('Sending auth_with_token message');

      ws.current.send(JSON.stringify({
        type: 'auth_with_token',
        token: pendingToken
      }));

      sessionStorage.removeItem('pending_token');

      const authHandler = (event) => {
        console.log('Received WebSocket message during auth:', event.data);

        try {
          const data = JSON.parse(event.data);
          const messageType = data.type?.trim();

          if (messageType === 'auth_success') {
            console.log('Auth success! Username:', data.username);
            setUsername(data.username);
            setIsAuthenticated(true);
            sessionStorage.setItem('isAuthenticated', 'true');
            sessionStorage.setItem('username', data.username);
            setPendingTokenAuth(false);
            ws.current.removeEventListener('message', authHandler);
          } else if (messageType === 'error' && data.context === 'token_auth') {
            console.error('Token authentication failed:', data.message);
            alert('Authentication failed. Please log in again.');
            sessionStorage.clear();
            setMode(null);
            setIsAuthenticated(false);
            setPendingTokenAuth(false);
            ws.current.removeEventListener('message', authHandler);
          }
        } catch (error) {
          console.error('Error parsing auth response:', error);
        }
      };

      ws.current.addEventListener('message', authHandler);

      const timeoutId = setTimeout(() => {
        console.log('Auth timeout - pendingTokenAuth:', pendingTokenAuth);
        if (pendingTokenAuth) {
          ws.current.removeEventListener('message', authHandler);
          alert('Authentication timeout. Please try again.');
          sessionStorage.clear();
          setMode(null);
          setIsAuthenticated(false);
          setPendingTokenAuth(false);
        }
      }, 10000);

      return () => {
        clearTimeout(timeoutId);
        ws.current?.removeEventListener('message', authHandler);
      };
    }
  }, [wsReady, pendingTokenAuth]);

  // Handle reauth when WebSocket connects (for page refresh)
  useEffect(() => {
    console.log('Reauth effect check:', { wsReady, hasCurrent: !!ws.current, reauthPending });

    if (!wsReady || !ws.current || !reauthPending) return;

    const username = sessionStorage.getItem('username');
    const isAuth = sessionStorage.getItem('isAuthenticated');

    console.log('Reauth effect - checking credentials:', { isAuth, username });

    if (isAuth === 'true' && username) {
      console.log('Sending reauth for:', username);
      ws.current.send(JSON.stringify({
        type: 'reauth',
        username: username
      }));

      const reauthHandler = (event) => {
        try {
          const data = JSON.parse(event.data);
          const messageType = data.type?.trim();

          console.log('Received message during reauth:', messageType, data);

          if (messageType === 'error' && (data.message === 'Not authenticated' || data.context === 'token_auth')) {
            console.log('Reauth failed - server lost session, redirecting to login');
            alert('Your session has expired. Please log in again.');
            sessionStorage.clear();
            setUsername(null);
            setIsAuthenticated(false);
            setMode(null);
            setReauthPending(false);
            ws.current.removeEventListener('message', reauthHandler);
          } else if (messageType === 'auth_success') {
            console.log('Reauth successful');
            setReauthPending(false);
            ws.current.removeEventListener('message', reauthHandler);
          }
        } catch (error) {
          console.error('Error parsing reauth response:', error);
        }
      };

      ws.current.addEventListener('message', reauthHandler);

      const timeoutId = setTimeout(() => {
        console.log('Reauth timeout - assuming success');
        setReauthPending(false);
        ws.current?.removeEventListener('message', reauthHandler);
      }, 5000);

      return () => {
        clearTimeout(timeoutId);
        ws.current?.removeEventListener('message', reauthHandler);
      };
    } else {
      console.log('No credentials to reauth with');
      setReauthPending(false);
    }
  }, [wsReady, reauthPending]);

  const handleLoginSuccess = (user) => {
    setUsername(user);
    setIsAuthenticated(true);
    sessionStorage.setItem('isAuthenticated', 'true');
    sessionStorage.setItem('username', user);
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

    const publishAllEvent = new CustomEvent('collect-publish-data');
    const collectedData = [];

    const handleDataCollection = (event) => {
      collectedData.push(event.detail);
    };

    window.addEventListener('publish-data-response', handleDataCollection);
    window.dispatchEvent(publishAllEvent);

    setTimeout(() => {
      window.removeEventListener('publish-data-response', handleDataCollection);

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

  // Show loading screen while authenticating
  if (pendingTokenAuth || reauthPending) {
    return (
      <div className="app-container" style={{
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        height: '100vh',
        flexDirection: 'column',
        gap: '20px'
      }}>
        <div style={{ fontSize: '48px' }}>⏳</div>
        <div style={{ fontSize: '20px' }}>Authenticating...</div>
      </div>
    );
  }

  // Show login screen if not authenticated
  if (!isAuthenticated) {
    return <Login ws={ws} wsReady={wsReady} onLoginSuccess={handleLoginSuccess} />;
  }

  // Show mode selector if authenticated but no mode selected
  if (!mode) {
    return <ModeSelector onModeSelect={handleModeSelect} username={username} ws={ws} />;
  }

  // Show subscriber or publisher based on mode
  return (
    <div className="app-container">
      <div className="app-header">
        <div className="mode-indicator">
          Mode: <strong>{mode === 'subscriber' ? 'Subscriber' : 'Publisher'}</strong>
          <span style={{
            marginLeft: '10px',
            fontSize: '12px',
            color: isConnected ? '#4CAF50' : '#ff9800'
          }}>
            {isConnected ? '● Connected' : '○ Reconnecting...'}
          </span>
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