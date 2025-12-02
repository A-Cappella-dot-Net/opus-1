import React, { useState, useEffect } from 'react';
import './Login.css';

export const Login = ({ ws, wsReady, onLoginSuccess }) => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    if (!ws.current) return;

    const handleMessage = (event) => {
      const msg = JSON.parse(event.data);

      if (msg.type === 'login_response') {
        if (msg.success) {
          sessionStorage.setItem('username', username);
          sessionStorage.setItem('isAuthenticated', 'true');
          onLoginSuccess(username);
        } else {
          setError(msg.message || 'Invalid credentials');
          setIsLoading(false);
        }
      }
    };

    ws.current.addEventListener('message', handleMessage);

    return () => {
      if (ws.current) {
        ws.current.removeEventListener('message', handleMessage);
      }
    };
  }, [ws, username, onLoginSuccess]);

  const handleSubmit = (e) => {
    e.preventDefault();
    setError('');
    setIsLoading(true);

    if (ws.current && ws.current.readyState === WebSocket.OPEN) {
      ws.current.send(JSON.stringify({
        type: 'login',
        username: username,
        password: password
      }));
    } else {
      setError('Connection to server failed');
      setIsLoading(false);
    }
  };

  return (
    <div className="login-container">
      <div className="login-box">
        <h1>View Client</h1>

        {!wsReady && (
          <div className="connection-status" style={{
            padding: '10px',
            marginBottom: '15px',
            backgroundColor: '#fff3cd',
            border: '1px solid #ffc107',
            borderRadius: '4px',
            color: '#856404'
          }}>
            Connecting to server...
          </div>
        )}

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label htmlFor="username">Username</label>
            <input
              id="username"
              type="text"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              required
              autoFocus
              disabled={isLoading || !wsReady}
            />
          </div>

          <div className="form-group">
            <label htmlFor="password">Password</label>
            <input
              id="password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              disabled={isLoading || !wsReady}
            />
          </div>

          {error && <div className="error-message">{error}</div>}

          <button type="submit" disabled={isLoading || !wsReady}>
            {!wsReady ? 'Connecting...' : isLoading ? 'Logging in...' : 'Login'}
          </button>
        </form>
      </div>
    </div>
  );
};