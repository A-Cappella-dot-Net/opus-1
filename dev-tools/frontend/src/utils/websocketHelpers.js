export const sendWebSocketMessage = (ws, message) => {
  if (ws.current && ws.current.readyState === WebSocket.OPEN) {
    ws.current.send(JSON.stringify(message));
  }
};

export const sendTabAction = (ws, tabId, type, additionalData = {}) => {
  sendWebSocketMessage(ws, {
    type: type,
    tabId: tabId,
    mode: 'subscriber',
    ...additionalData
  });
};

export const sendScrollUpdate = (ws, tabId, startCol, scrollData) => {
  sendWebSocketMessage(ws, {
    type: 'scroll_update',
    tabId: tabId,
    startCol: startCol,
    ...scrollData
  });
};