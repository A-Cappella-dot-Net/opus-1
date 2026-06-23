/**
 * Format cell value based on column type
 */
export const formatCellValue = (value, column) => {
  if (value === null || value === undefined) {
    return '';
  }

  const type = column.type || 'string';

  switch (type) {
    case 'integer':
      return formatInteger(value);

    case 'decimal':
      return formatDecimal(value, column.decimals || 2);

    case 'datetime':
      return formatDateTime(value, column.format);

    case 'boolean':
      return formatBoolean(value);

    case 'string':
    default:
      return String(value);
  }
};

/**
 * Format integer with thousand separators
 */
const formatInteger = (value) => {
  const num = parseInt(value, 10);
  if (isNaN(num)) return String(value);

  return num.toLocaleString('en-US', {
    maximumFractionDigits: 0
  });
};

/**
 * Format decimal with specified precision
 */
const formatDecimal = (value, decimals = 2) => {
  const num = parseFloat(value);
  if (isNaN(num)) return String(value);

  return num.toLocaleString('en-US', {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals
  });
};



// (a) PTimestamp - milliseconds since Unix epoch
const decodeTimestamp = (millis) => {
  return new Date(millis);
};

// (b) PNanos - nanoseconds since Unix epoch
const decodeNanos = (nanosObj) => {
  // Create Date from milliseconds
  const date = new Date(nanosObj.value);

  // Store the sub-millisecond nanos for later display
  date._subMilliNanos = nanosObj.nanos;

  return date;
};

// (c) PDate - date in yyyymmdd format (e.g., 20241125)
const decodeDate = (yyyymmdd) => {
  const year = Math.floor(yyyymmdd / 10000);
  const month = Math.floor((yyyymmdd % 10000) / 100) - 1; // JS months are 0-indexed (0-11)
  const day = yyyymmdd % 100;
  return new Date(year, month, day);
};

// (d) PTime - time in hhmmssSSS format (e.g., 143045123 = 14:30:45.123)
const decodeTime = (hhmmssSSS) => {
  const hours = Math.floor(hhmmssSSS / 10000000);
  const minutes = Math.floor((hhmmssSSS % 10000000) / 100000);
  const seconds = Math.floor((hhmmssSSS % 100000) / 1000);
  const millis = hhmmssSSS % 1000;

  // Create a Date object with today's date and the specified time
  const date = new Date();
  date.setHours(hours, minutes, seconds, millis);
  return date;
};



/**
 * Format datetime
 * Supports: ISO string, Unix timestamp (ms or seconds), Date object
 */
const formatDateTime = (obj, format = 'ISO') => {
  if (!obj || !obj.type || obj.value === undefined) {
    return String(obj);
  }

  let date;
  switch (obj.type) {
    case 'timestamp':
      date = decodeTimestamp(obj.value);
      break;
    case 'nanos':
      date = decodeNanos(obj);
      break;
    case 'date':
      date = decodeDate(obj.value);
      break;
    case 'time':
      date = decodeTime(obj.value);
      break;
    default:
      return String(obj);
  }

  if (isNaN(date.getTime())) {
    return String(obj);
  }

  let formatted;
  switch (format) {
    case 'ISO':
      // Custom ISO-like format: YYYY-MM-DD HH:MM:SS.mmm (no T, no Z)
      const year = date.getUTCFullYear();
      const month = String(date.getUTCMonth() + 1).padStart(2, '0');
      const day = String(date.getUTCDate()).padStart(2, '0');
      const hours = String(date.getUTCHours()).padStart(2, '0');
      const minutes = String(date.getUTCMinutes()).padStart(2, '0');
      const seconds = String(date.getUTCSeconds()).padStart(2, '0');
      const millis = String(date.getUTCMilliseconds()).padStart(3, '0');
      formatted = `${year}-${month}-${day} ${hours}:${minutes}:${seconds}.${millis}`;
      break;
    case 'locale':
      formatted = date.toLocaleString('en-US');
      break;
    case 'date':
      // Just date: YYYY-MM-DD
      const y = date.getUTCFullYear();
      const m = String(date.getUTCMonth() + 1).padStart(2, '0');
      const d = String(date.getUTCDate()).padStart(2, '0');
      formatted = `${y}-${m}-${d}`;
      break;
    case 'time':
      // Just time: HH:MM:SS.mmm
      const h = String(date.getUTCHours()).padStart(2, '0');
      const min = String(date.getUTCMinutes()).padStart(2, '0');
      const s = String(date.getUTCSeconds()).padStart(2, '0');
      const ms = String(date.getUTCMilliseconds()).padStart(3, '0');
      formatted = `${h}:${min}:${s}.${ms}`;
      break;
    case 'short':
      // Format: MM/DD/YYYY HH:MM:SS
      formatted = date.toLocaleString('en-US', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit'
      });
      break;
    default:
      formatted = date.toISOString();
  }

  // Add sub-millisecond precision if available
  if (date._subMilliNanos !== undefined) {
    const micros = Math.floor(date._subMilliNanos / 1000);
    const nanos = date._subMilliNanos % 1000;
    formatted += `${micros.toString().padStart(3, '0')}${nanos.toString().padStart(3, '0')}`;
  }

  return formatted;
};

/**
 * Format boolean as Yes/No or custom values
 */
const formatBoolean = (value) => {
  if (typeof value === 'boolean') {
    return value ? 'Yes' : 'No';
  }

  // Handle string representations
  const strValue = String(value).toLowerCase();
  if (strValue === 'true' || strValue === '1' || strValue === 'yes') {
    return 'Yes';
  }
  if (strValue === 'false' || strValue === '0' || strValue === 'no') {
    return 'No';
  }

  return String(value);
};

/**
 * Get CSS class for cell alignment based on column type
 */
export const getCellAlignment = (column) => {
  // Use explicit align if provided
  if (column.align) {
    return column.align;
  }

  // Default alignment by type
  const type = column.type || 'string';
  switch (type) {
    case 'integer':
    case 'decimal':
      return 'right';
    case 'boolean':
      return 'center';
    case 'datetime':
    case 'string':
    default:
      return 'left';
  }
};

/**
 * Get CSS class name for cell styling
 */
export const getCellClassName = (value, column) => {
  const classes = [];

  // Add type-based class
  if (column.type) {
    classes.push(`cell-type-${column.type}`);
  }

  // Add special styling for negative numbers
  if ((column.type === 'integer' || column.type === 'decimal')) {
    const num = parseFloat(value);
    if (!isNaN(num) && num < 0) {
      classes.push('cell-negative');
    }
  }

  // Add styling for boolean
  if (column.type === 'boolean') {
    const isTrue = value === true ||
                   String(value).toLowerCase() === 'true' ||
                   value === 1 ||
                   value === '1';
    classes.push(isTrue ? 'cell-bool-true' : 'cell-bool-false');
  }

  return classes.join(' ');
};