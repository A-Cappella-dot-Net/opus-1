import { useState, useEffect, useRef } from 'react';

export const useWebSocket = (onAuthError) => {
  const [wsReady, setWsReady] = useState(false);
  const [isConnected, setIsConnected] = useState(false);
  const ws = useRef(null);
  const messageHandlers = useRef([]);
  const onAuthErrorRef = useRef(onAuthError);
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
        const delay = Math.min(1000 * Math.pow(2, reconnectAttempts.current), 10000); // Exponential backoff, max 30s
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

    ws.current.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);

        // Handle authentication errors
        if (data.type === 'error' &&
            (data.message?.toLowerCase().includes('not authenticated') ||
             data.message?.toLowerCase().includes('authentication'))) {
          console.log('Authentication error received from server');
          if (onAuthErrorRef.current) {
            onAuthErrorRef.current();
          }
        }

        // Allow other handlers to process messages too
        messageHandlers.current.forEach(handler => handler(event));
      } catch (error) {
        console.error('Error parsing WebSocket message:', error);
      }
    };

    ws.current.onerror = (error) => {
      console.error('WebSocket error:', error);
      setIsConnected(false);
    };
  };

  // Update the ref when callback changes, without triggering effect
  useEffect(() => {
    onAuthErrorRef.current = onAuthError;
  }, [onAuthError]);

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
    // Connect once on mount and tear down on unmount; `connect` is intentionally
    // not a dependency to avoid reconnecting on every render.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const sendMessage = (message) => {
    if (ws.current && ws.current.readyState === WebSocket.OPEN) {
      ws.current.send(JSON.stringify(message));
    } else {
      console.warn('WebSocket not ready, cannot send message:', message);
    }
  };

  const addMessageHandler = (handler) => {
    messageHandlers.current.push(handler);
  };

  const removeMessageHandler = (handler) => {
    messageHandlers.current = messageHandlers.current.filter(h => h !== handler);
  };

  return { ws, wsReady, sendMessage, isConnected, addMessageHandler, removeMessageHandler };
};