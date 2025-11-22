import { useState, useEffect, useRef } from 'react';

export const useWebSocket = () => {
  const [wsReady, setWsReady] = useState(false);
  const ws = useRef(null);

  useEffect(() => {
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const isDevelopment = window.location.port === '3000';
    const host = isDevelopment ? 'localhost:8080' : window.location.host;

    ws.current = new WebSocket(`${protocol}//${host}/ws`);

    ws.current.onopen = () => {
      console.log('Connected to ViewServer');
      setWsReady(true);
    };

    ws.current.onerror = (error) => {
      console.error('WebSocket error:', error);
    };

    ws.current.onclose = () => {
      console.log('Disconnected from ViewServer');
      setWsReady(false);
    };

    return () => {
      if (ws.current) {
        ws.current.close();
      }
    };
  }, []);

  const sendMessage = (message) => {
    if (ws.current && ws.current.readyState === WebSocket.OPEN) {
      ws.current.send(JSON.stringify(message));
    }
  };

  return { ws, wsReady, sendMessage };
};