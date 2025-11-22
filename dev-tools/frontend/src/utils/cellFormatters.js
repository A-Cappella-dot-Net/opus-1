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

/**
 * Format datetime
 * Supports: ISO string, Unix timestamp (ms or seconds), Date object
 */
const formatDateTime = (value, format = 'ISO') => {
  let date;

  // Try parsing as various formats
  if (value instanceof Date) {
    date = value;
  } else if (typeof value === 'string') {
    date = new Date(value);
  } else if (typeof value === 'number') {
    // Assume milliseconds if > year 2000 in seconds
    date = value > 946684800000 ? new Date(value) : new Date(value * 1000);
  } else {
    return String(value);
  }

  if (isNaN(date.getTime())) {
    return String(value);
  }

  // Format based on specified format
  switch (format) {
    case 'ISO':
      return date.toISOString();

    case 'locale':
      return date.toLocaleString('en-US');

    case 'date':
      return date.toLocaleDateString('en-US');

    case 'time':
      return date.toLocaleTimeString('en-US');

    case 'short':
      // Format: MM/DD/YYYY HH:MM:SS
      return date.toLocaleString('en-US', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit'
      });

    default:
      return date.toISOString();
  }
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