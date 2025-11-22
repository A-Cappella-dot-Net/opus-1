import React from 'react';

export const CustomScrollbar = ({
  direction = 'vertical',
  thumbRatio,
  thumbPosition,
  onTrackClick,
  onThumbMouseDown,
  onScrollClick,
  trackRef
}) => {
  const isVertical = direction === 'vertical';

  return (
    <div className={`scroll-container ${direction}`}>
      <button
        className={`scroll-arrow ${direction}`}
        onClick={() => onScrollClick(isVertical ? 'top' : 'start')}
        title={isVertical ? 'Scroll to top' : 'Scroll to start'}
      >
        {isVertical ? '⏫' : '⏮'}
      </button>
      <button
        className={`scroll-arrow ${direction}`}
        onClick={() => onScrollClick(isVertical ? 'up' : 'left')}
        title={isVertical ? 'Scroll up' : 'Scroll left'}
      >
        {isVertical ? '▲' : '◀'}
      </button>
      <div
        ref={trackRef}
        className={`custom-scrollbar ${isVertical ? '' : 'horizontal'}`}
        onMouseDown={onTrackClick}
      >
        <div
          className={`custom-scrollbar-thumb ${direction}`}
          style={isVertical ? {
            height: `${thumbRatio * 100}%`,
            top: `${thumbPosition * (100 - thumbRatio * 100)}%`
          } : {
            width: `${thumbRatio * 100}%`,
            left: `${thumbPosition * (100 - thumbRatio * 100)}%`
          }}
          onMouseDown={onThumbMouseDown}
        />
      </div>
      <button
        className={`scroll-arrow ${direction}`}
        onClick={() => onScrollClick(isVertical ? 'down' : 'right')}
        title={isVertical ? 'Scroll down' : 'Scroll right'}
      >
        {isVertical ? '▼' : '▶'}
      </button>
      <button
        className={`scroll-arrow ${direction}`}
        onClick={() => onScrollClick(isVertical ? 'bottom' : 'end')}
        title={isVertical ? 'Scroll to bottom' : 'Scroll to end'}
      >
        {isVertical ? '⏬' : '⏭'}
      </button>
    </div>
  );
};