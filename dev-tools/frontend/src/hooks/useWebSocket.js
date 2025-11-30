import { useState, useEffect, useRef } from 'react';

export const useWebSocket = () => {
  const [wsReady, setWsReady] = useState(false);
  const [isConnected, setIsConnected] = useState(false);
  const ws = useRef(null);
  const reconnectAttempts = useRef(0);
  const reconnectTimeout = useRef(null);
  const heartbeatInterval = useRef(null);
  const maxReconnectAttempts = 10;

  const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
  const isDevelopment = window.location.port === '3000';
  const host = isDevelopment ? 'localhost:8080' : window.location.host;
  const wsUrl = `${protocol}//${host}/ws`;

  const startHeartbeat = () => {
    stopHeartbeat(); // Clear any existing interval

    // Send heartbeat every 25 seconds
    heartbeatInterval.current = setInterval(() => {
      if (ws.current && ws.current.readyState === WebSocket.OPEN) {
        ws.current.send(JSON.stringify({ type: 'heartbeat' }));
      }
    }, 25000);
  };

  const stopHeartbeat = () => {
    if (heartbeatInterval.current) {
      clearInterval(heartbeatInterval.current);
      heartbeatInterval.current = null;
    }
  };

  const connect = () => {
    // Clear any existing connection
    if (ws.current) {
      ws.current.close();
    }

    console.log('Connecting to WebSocket:', wsUrl);
    ws.current = new WebSocket(wsUrl);

    ws.current.onopen = () => {
      console.log('Connected to ViewServer');
      setWsReady(true);
      setIsConnected(true);
      reconnectAttempts.current = 0; // Reset reconnect attempts on successful connection

      // Start heartbeat to keep connection alive
      startHeartbeat();
    };

    ws.current.onclose = (event) => {
      console.log('WebSocket closed. Code:', event.code, 'Reason:', event.reason);
      setWsReady(false);
      setIsConnected(false);
      stopHeartbeat();

      // Attempt to reconnect unless it's a normal closure (code 1000)
      if (event.code !== 1000 && reconnectAttempts.current < maxReconnectAttempts) {
        const delay = Math.min(1000 * Math.pow(2, reconnectAttempts.current), 30000); // Exponential backoff, max 30s
        console.log(`Reconnecting in ${delay}ms (attempt ${reconnectAttempts.current + 1}/${maxReconnectAttempts})...`);

        reconnectTimeout.current = setTimeout(() => {
          reconnectAttempts.current++;
          connect();
        }, delay);
      } else if (reconnectAttempts.current >= maxReconnectAttempts) {
        console.error('Max reconnection attempts reached. Please refresh the page.');
        // Dispatch a custom event that App.jsx can listen to
        window.dispatchEvent(new CustomEvent('websocket-connection-failed'));
      }
    };

    ws.current.onerror = (error) => {
      console.error('WebSocket error:', error);
      setIsConnected(false);
    };
  };

  useEffect(() => {
    connect();

    return () => {
      console.log('Cleaning up WebSocket...');
      if (reconnectTimeout.current) {
        clearTimeout(reconnectTimeout.current);
      }
      stopHeartbeat();
      if (ws.current) {
        ws.current.close(1000, 'Component unmounting'); // Normal closure
      }
    };
  }, []);

  const sendMessage = (message) => {
    if (ws.current && ws.current.readyState === WebSocket.OPEN) {
      ws.current.send(JSON.stringify(message));
    } else {
      console.warn('WebSocket not ready, cannot send message:', message);
    }
  };

  return { ws, wsReady, sendMessage, isConnected };
};