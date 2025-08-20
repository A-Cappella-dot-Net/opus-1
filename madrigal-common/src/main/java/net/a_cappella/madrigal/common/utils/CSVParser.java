package net.a_cappella.madrigal.common.utils;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.LineNumberReader;
import java.io.Reader;
import java.util.*;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class CSVParser {
    private static final Logger log = LoggerFactory.getLogger(CSVParser.class);

	private final String _fileName;
	private final char _delimiter;
	private String[] _columns;
	private final Map<String, Integer> _columnIndex;
	private final Map<String, Integer> _rowKey;
	private final List<String[]> _rows;

	public CSVParser(String file) throws IOException, CSVParseException {
		this(file, ';');
	}

	public CSVParser(String fileName, char delimiter) throws IOException, CSVParseException {
		_columnIndex = new HashMap<>();
		_rowKey = new HashMap<>();
		_rows = new ArrayList<>();
		_fileName = fileName;
		_delimiter = delimiter;
		LineNumberReader stream = new LineNumberReader(new BufferedReader(new FileReader(_fileName)));
		retrieveColumns(stream);
		retrieveRows(stream);
		retrieveRowsKeys();
	}

	public CSVParser(String fileName, char delimiter, CSVWriter.CSVHeader csvHeader) throws IOException, CSVParseException {
		_columnIndex = new HashMap<>();
		_rowKey = new HashMap<>();
		_rows = new ArrayList<>();
		_fileName = fileName;
		_delimiter = delimiter;
		_columns = new String[csvHeader.getFieldNames().size()];
		int i = 0;
		for (String key : csvHeader.getFieldNames()) {
			_columns[i] = key;
			_columnIndex.put(_columns[i].trim(), i);
			++i;
		}
		LineNumberReader stream = new LineNumberReader(new BufferedReader(
				new FileReader(_fileName)));
		retrieveRows(stream);
		retrieveRowsKeys();
	}

	public CSVParser(String file, String[] expectedColumns) throws IOException, CSVParseException {
		this(file, ';', expectedColumns);
	}

	public CSVParser(InputStream resourceAsStream, String[] expectedColumns) throws IOException, CSVParseException {
		_fileName = null;
		_columnIndex = new HashMap<>();
		_rowKey = new HashMap<>();
		_rows = new ArrayList<>();
		_delimiter = ';';

		LineNumberReader stream = new LineNumberReader(new BufferedReader(
				new InputStreamReader(resourceAsStream)));
		retrieveColumns(stream);
		checkExpectedColumns(expectedColumns);
		retrieveRows(stream);
		retrieveRowsKeys();
	}

	public CSVParser(String file, char delim, String[] expectedColumns) throws IOException, CSVParseException {
		_columnIndex = new HashMap<>();
		_rowKey = new HashMap<>();
		_rows = new ArrayList<>();
		_fileName = file;
		_delimiter = delim;

		LineNumberReader stream = new LineNumberReader(new BufferedReader(
				new FileReader(_fileName)));
		retrieveColumns(stream);
		checkExpectedColumns(expectedColumns);
		retrieveRows(stream);
		retrieveRowsKeys();
	}

	public CSVParser(InputStream resourceAsStream) throws IOException, CSVParseException {
		_fileName = null;
		_columnIndex = new HashMap<>();
		_rowKey = new HashMap<>();
		_rows = new ArrayList<>();
		_delimiter = ';';

		LineNumberReader stream = new LineNumberReader(new BufferedReader(
				new InputStreamReader(resourceAsStream)));
		retrieveColumns(stream);
		retrieveRows(stream);
		retrieveRowsKeys();
	}

	public CSVParser(InputStream resourceAsStream, char delim) throws IOException, CSVParseException {
		_fileName = null;
		_columnIndex = new HashMap<>();
		_rowKey = new HashMap<>();
		_rows = new ArrayList<>();
		_delimiter = delim;

		LineNumberReader stream = new LineNumberReader(new BufferedReader(
				new InputStreamReader(resourceAsStream)));
		retrieveColumns(stream);
		retrieveRows(stream);
		retrieveRowsKeys();
	}

	public CSVParser(Reader reader) throws IOException, CSVParseException {
		_fileName = null;
		_columnIndex = new HashMap<>();
		_rowKey = new HashMap<>();
		_rows = new ArrayList<>();
		_delimiter = ';';

		LineNumberReader stream = new LineNumberReader(new BufferedReader(
				reader));
		retrieveColumns(stream);
		retrieveRows(stream);
		retrieveRowsKeys();
	}

	public CSVParser(Reader reader, char delim) throws IOException, CSVParseException {
		_fileName = null;
		_columnIndex = new HashMap<>();
		_rowKey = new HashMap<>();
		_rows = new ArrayList<>();
		_delimiter = delim;

		LineNumberReader stream = new LineNumberReader(new BufferedReader(
				reader));
		retrieveColumns(stream);
		retrieveRows(stream);
		retrieveRowsKeys();
	}

	public String getFileName() {
		return _fileName;
	}

	public String[] getColumns() {
		return _columns;
	}

	private void checkExpectedColumns(String[] expectedColumns) throws CSVParseException {
		for (int i = 0; i < expectedColumns.length; ++i) {
			boolean found = false;
			for (int j = 0; (j < _columns.length) && (!(found)); ++j) {
				if (_columns[j].equalsIgnoreCase(expectedColumns[i])) {
					found = true;
				}
			}
			if (found) continue;
			throw new CSVParseException("Column " + expectedColumns[i]
					+ " was expected and is missing.");
		}
	}

	public List<String[]> getRows() {
		return _rows;
	}

	public int getRowCount() {
		return _rows.size();
	}

	public String getValue(int rownum, int colindex) throws CSVParseException {
		if ((colindex >= 0) && (colindex < _columns.length)) {
			if ((rownum >= 0) && (rownum < _rows.size()))
				return _rows.get(rownum)[colindex];
			throw new CSVParseException("Invalid row number: " + rownum);
		}
		throw new CSVParseException("Invalid column index: " + colindex);
	}

	public String getValue(int rownum, String columnName) throws CSVParseException {
		Integer colnum = _columnIndex.get(columnName);
		if (colnum != null) {
			if ((rownum >= 0) && (rownum < _rows.size())) {
				String ret = _rows.get(rownum)[colnum];
				return ((ret == null) ? ret : ret.trim());
			}
			throw new CSVParseException("Invalid row number: " + rownum);
		}
		throw new CSVParseException("Invalid column name: " + columnName);
	}

	public String getValue(String key, String columnName) throws CSVParseException {
		Integer colnum = _columnIndex.get(columnName);
		Integer rownumAsInteger = _rowKey.get(key);
		if (rownumAsInteger == null)
			throw new CSVParseException("key + " + key
					+ " doesn't exist in the csv file");
		int rownum = rownumAsInteger;
		if (colnum != null) {
			if ((rownum >= 0) && (rownum < _rows.size()))
				return _rows.get(rownum)[colnum];
			throw new CSVParseException("Invalid row number: " + rownum);
		}
		throw new CSVParseException("Invalid column name: " + columnName);
	}

	public long getLongValue(int rownum, String columnName) throws CSVParseException {
		String value = getValue(rownum, columnName);
		try {
			return Long.parseLong(value);
		} catch (NumberFormatException nfe) {
			Integer colnum = _columnIndex.get(columnName);
			throw new CSVParseException("Unable to parse long value at row "
					+ rownum + ", column " + colnum + ": " + value);
		}
	}

	public long getLongValue(String key, String columnName) throws CSVParseException {
		String value = getValue(key, columnName);
		try {
			return Long.parseLong(value);
		} catch (NumberFormatException nfe) {
			Integer colnum = _columnIndex.get(columnName);
			throw new CSVParseException("Unable to parse long value at row "
					+ key + ", column " + colnum + ": " + value);
		}
	}

	public double getDoubleValue(int rownum, String columnName) throws CSVParseException {
		String value = getValue(rownum, columnName);
		try {
			return Double.parseDouble(value);
		} catch (NumberFormatException nfe) {
			try {
				return Double.parseDouble(value.replace(',', '.'));
			} catch (NumberFormatException nfe2) {
				Integer colnum = _columnIndex.get(columnName);
				throw new CSVParseException(
						"Unable to parse double value at row " + rownum
								+ ", column " + colnum + ": "
								+ value);
			}
		}
	}

	public double getDoubleValue(String key, String columnName) throws CSVParseException {
		String value = getValue(key, columnName);
		try {
			return Double.parseDouble(value);
		} catch (NumberFormatException nfe) {
			try {
				return Double.parseDouble(value.replace(',', '.'));
			} catch (NumberFormatException nfe2) {
				Integer colnum = _columnIndex.get(columnName);
				throw new CSVParseException(
						"Unable to parse double value at row " + key
								+ ", column " + colnum + ": "
								+ value);
			}
		}
	}

	private void retrieveColumns(LineNumberReader stream) throws CSVParseException, IOException {
		String header = stream.readLine();
		if (header == null)
			throw new CSVParseException("header is missing");
		ArrayList<String> vColumns = new ArrayList<String>();
		StringTokenizer tokenizer = new StringTokenizer(header,
				String.valueOf(_delimiter));
		while (tokenizer.hasMoreElements()) {
			vColumns.add(tokenizer.nextToken());
		}
		_columns = new String[vColumns.size()];
		for (int i = 0; i < vColumns.size(); ++i) {
			_columns[i] = vColumns.get(i);
			_columnIndex.put(_columns[i].trim(), i);
		}
	}

	private void retrieveRows(LineNumberReader stream) throws CSVParseException, IOException {
		String line = stream.readLine();
		while (line != null) {
			String data = line.trim();
			if ((!(data.isEmpty())) && (data.charAt(0) != '#'))
				_rows.add(parseLine(data, stream.getLineNumber()));
			line = stream.readLine();
		}
	}

	private void retrieveRowsKeys() throws CSVParseException {
		String key;
		for (int k = 0; k < _rows.size(); ++k) {
			key = getValue(k, _columns[0]);
			if (key == null) {
				log.debug("Skipping null value at row[" + k + "]");
			} else
				_rowKey.put(key, k);
		}
	}

	private String[] parseLine(String line, int lineNumber) throws CSVParseException {
		String[] values = new String[_columns.length];
		boolean wasValue = false;
		int currentPosition = 0;
		int currentColumn = 0;
		while ((currentPosition < line.length())
				&& (currentColumn < _columns.length)) {
			String token;
			if (line.charAt(currentPosition) == _delimiter) {
				token = String.valueOf(_delimiter);
				++currentPosition;
			} else if (line.charAt(currentPosition) == '"') {
				int endOfFieldPosition = line.indexOf(34, currentPosition + 1);

				while ((endOfFieldPosition > 0)
						&& (endOfFieldPosition + 1 < line.length())
						&& (line.charAt(endOfFieldPosition + 1) != _delimiter)) {
					endOfFieldPosition = line.indexOf(34,
							endOfFieldPosition + 1);
				}

				if (endOfFieldPosition < 0)
					throw new CSVParseException(
							"unclosed character literal at line " + lineNumber);

				token = replace(
						line.substring(currentPosition + 1, endOfFieldPosition),
						"\"\"", "\"");
				currentPosition = endOfFieldPosition + 1;
			} else {
				int endOfFieldPosition = line.indexOf(_delimiter,
						currentPosition);

				if (endOfFieldPosition < 0) {
					endOfFieldPosition = line.length();
				}

				token = line.substring(currentPosition, endOfFieldPosition);
				currentPosition = endOfFieldPosition;
			}

			if ((!(wasValue))
					&& (!(token.equals(String.valueOf(_delimiter))))) {
				values[currentColumn] = token;
				wasValue = true;
			} else {
				wasValue = false;
				++currentColumn;
			}
		}

		return values;
	}

	private String replace(String str, String pattern, String value) {
		if ((str != null) && (pattern != null) && (value != null)) {
			int patternPosition = str.indexOf(pattern);
			while (patternPosition >= 0) {
				str = str.substring(0, patternPosition) + value
						+ str.substring(patternPosition + pattern.length());
				patternPosition = str.indexOf(pattern,
						patternPosition + value.length());
			}
		}
		return str;
	}
}
