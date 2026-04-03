/*
 * Copyright (c) 2026. Vladimir Ivanov
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package net.a_cappella.madrigal.common.utils;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.BufferedWriter;
import java.io.IOException;
import java.io.Writer;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;

public class CSVWriter {
    private static final Logger log = LoggerFactory.getLogger(CSVWriter.class);

    protected char delimiter;
	protected BufferedWriter out;
	protected CSVHeader header;

	public CSVWriter() {
		this.delimiter = ';';
		this.out = null;
		this.header = null;
	}

	public CSVWriter(Writer out, CSVHeader header) throws IOException {
		this(out, header, true, ';');
	}

	public CSVWriter(Writer out, CSVHeader header, boolean writeTheHeader,
			char delimiter) throws IOException {
		this.delimiter = ';';
		this.delimiter = delimiter;
		this.out = new BufferedWriter(out);
		this.header = header;
		if (writeTheHeader) {
			header.setDelimiter(delimiter);
			String line = header.getCSVLine();
			out.write(line);
			out.write("\n");
			out.flush();
		}
	}

	public void close() throws IOException {
		this.out.close();
	}

	public CSVRecord getEmptyRecord() {
		return new CSVRecord(this.header);
	}

	public void write(CSVRecord record) throws IOException {
		if (!(record.isWritable())) {
			if (log.isDebugEnabled()) {
				String line = record.getCSVLine();
				log.debug("Skipping non writable CSV record: " + line);
			}
			return;
		}
		String line = record.getCSVLine();
		if (log.isDebugEnabled())
			log.debug("Writing CSV record: " + line);
		this.out.write(line);
		this.out.newLine();
	}

	public void flush() throws IOException {
		this.out.flush();
	}

	public char getDelimiter() {
		return this.delimiter;
	}

	public void setDelimiter(char delimiter) {
		this.delimiter = delimiter;
	}

	public static class CSVHeader {
		private final ArrayList<String> fieldNames = new ArrayList<String>();
		private char delimiter = ';';

		public void registerField(String fieldName) {
			this.fieldNames.add(fieldName);
		}

		public String getCSVLine() {
			StringBuilder sb = new StringBuilder();
			for (String fieldName : this.fieldNames) {
				sb.append(fieldName);
				sb.append(delimiter);
			}
			return sb.toString();
		}

		public char getDelimiter() {
			return delimiter;
		}

		public void setDelimiter(char delimiter) {
			this.delimiter = delimiter;
		}

		public ArrayList<String> getFieldNames() {
			return this.fieldNames;
		}
	}

	public class CSVRecord {
		protected CSVHeader header1 = null;
		protected boolean writable = true;

		protected final Map<String, String> fieldValues = new HashMap<String, String>();

		public CSVRecord(CSVHeader paramCSVHeader) {
			this.header1 = paramCSVHeader;
		}

		public void setFieldValue(String fieldName, String value) {
			this.fieldValues.put(fieldName, value);
		}

		public String getFieldValue(String fieldName) {
			return ((String) this.fieldValues.get(fieldName));
		}

		public CSVHeader getCSVHeader() {
			return this.header1;
		}

		public void clearValues() {
			this.fieldValues.clear();
		}

		public void setNonWritable() {
			this.writable = false;
		}

		public void setWritable() {
			this.writable = true;
		}

		public boolean isWritable() {
			return this.writable;
		}

		public String getCSVLine() {
			StringBuilder sb = new StringBuilder();
			if (this.header1 == null) {
				return getCSVLineWithNoHeader();
			}
			boolean firstIter = true;
			for (String fieldName : this.header1.getFieldNames()) {
				String fieldValue = (String) this.fieldValues.get(fieldName);
				if (firstIter)
					firstIter = false;
				else {
					sb.append(CSVWriter.this.delimiter);
				}
				if (fieldValue != null) {
					sb.append(fieldValue);
				} else
					sb.append("");

			}
			return sb.toString();
		}

		public String getCSVLineWithNoHeader() {
			StringBuilder sb = new StringBuilder();
			Iterator<String> iter = this.fieldValues.values().iterator();
			while (iter.hasNext()) {
				String value = (String) iter.next();
				if (value != null)
					sb.append(value);
				else {
					sb.append("");
				}
				sb.append(CSVWriter.this.delimiter);
			}
			return sb.toString();
		}
	}
}
