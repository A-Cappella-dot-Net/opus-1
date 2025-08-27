package net.a_cappella.datasubscriber;

import net.a_cappella.continuo.datatypes.PDate;
import net.a_cappella.continuo.datatypes.PNanos;
import net.a_cappella.continuo.datatypes.PTime;
import net.a_cappella.continuo.datatypes.PTimestamp;
import net.a_cappella.continuo.managed.ObjectManager;
import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.continuo.obj.PubType;
import net.a_cappella.continuo.obj.meta.FieldMetaInfo;
import net.a_cappella.continuo.obj.meta.ObjMetaInfo;
import net.a_cappella.continuo.ps.ISubscriptionListener;
import net.a_cappella.presto.ps.PrestoClient;
import net.a_cappella.presto.ps.sql.SqlParser;
import net.a_cappella.presto.ps.sql.SqlParserResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.swing.*;
import javax.swing.table.*;
import java.awt.*;
import java.awt.event.*;
import java.util.ArrayList;
import java.util.List;

public class TabContents extends JPanel implements ActionListener, ItemListener, ISubscriptionListener {
    private static final Logger log = LoggerFactory.getLogger(TabContents.class);

	private static final String LABEL_SQL = "Sql";
	private static final String LABEL_KEY = "Key";

	private static final String ACTION_STOP = "Stop";
	private static final String ACTION_CLEAN = "Clean";
	private static final String ACTION_EXECUTE = "Execute";

	private final DataSubscriber _subscriber;
	private final PrestoClient _client;
	private Long _subId;
	private final JTextField _sqlField;
	private final JCheckBox _keyCheckBox;
	private final JTextField _keyField;
	private final JTable _table;
	private final JLabel _resultField;

	public TabContents(DataSubscriber subscriber) {
		_subscriber = subscriber;
		_client = subscriber.getClient();

		_sqlField = new JTextField();
		_sqlField.setToolTipText("e.g., select * from user.dir where ecn=btec");
		_sqlField.addActionListener(this);
		_sqlField.addFocusListener(subscriber);

		JLabel sqlLabel = new JLabel(LABEL_SQL + ": ");
		sqlLabel.setLabelFor(_sqlField);

		_keyCheckBox = new JCheckBox();
		_keyCheckBox.setToolTipText("Check off if you want records grouped by Obj key");
		_keyCheckBox.addItemListener(this);

		_keyField = new JTextField();
		_keyField.setToolTipText("e.g., ecn");
		_keyField.addActionListener(this);

		JLabel keyLabel = new JLabel(LABEL_KEY + ": ");
		sqlLabel.setLabelFor(_keyField);

		// Lay out the text controls and the labels.
		JPanel inputsPanel = new JPanel(new GridBagLayout());
		inputsPanel.setBorder(BorderFactory.createEmptyBorder(5, 5, 5, 5));

		GridBagConstraints c = new GridBagConstraints();
		c.anchor = GridBagConstraints.EAST;

		c.gridx = 0;
		c.gridy = 0;
		c.gridwidth = 1;
		c.fill = GridBagConstraints.NONE;
		c.weightx = 0.0;
		inputsPanel.add(sqlLabel, c);

		c.gridx = 1;
		c.gridy = 0;
		c.gridwidth = 4;
		c.fill = GridBagConstraints.HORIZONTAL;
		c.weightx = 2.0;
		inputsPanel.add(_sqlField, c);

		c.gridx = 5;
		c.gridy = 0;
		c.gridwidth = 1;
		c.weightx = 0.1;
		c.anchor = GridBagConstraints.EAST;
		c.fill = GridBagConstraints.NONE;
		inputsPanel.add(keyLabel, c);

		c.gridx = 6;
		c.gridy = 0;
		c.gridwidth = 2;
		c.fill = GridBagConstraints.HORIZONTAL;
		c.anchor = GridBagConstraints.EAST;
		c.weightx = 1.0;
		inputsPanel.add(_keyField, c);

		c.gridx = 8;
		c.gridy = 0;
		c.gridwidth = 1;
		c.weightx = 0.0;
		c.anchor = GridBagConstraints.EAST;
		c.fill = GridBagConstraints.NONE;
		inputsPanel.add(_keyCheckBox, c);

		c.gridx = 0;
		c.gridy = 1;
		c.gridwidth = 9;
		c.fill = GridBagConstraints.HORIZONTAL;
		c.weightx = 0.5;
		inputsPanel.add(createButtons(this), c);

		// Create a table and put it in a scroll pane
		_table = new JTable(new MyTableModel());
		_table.setFillsViewportHeight(true);
		_table.setAutoResizeMode(JTable.AUTO_RESIZE_OFF);

		TableRowSorter<MyTableModel> sorter = new TableRowSorter<>((MyTableModel) _table.getModel());
		// TODO may wish to subclass TableRowSorter; also, to allow for multiple columns sorting
		_table.setRowSorter(sorter);
		_table.setDefaultRenderer(PTimestamp.class, new PTimestampRenderer());
		_table.setDefaultRenderer(PNanos.class, new PNanosRenderer());
		_table.setDefaultRenderer(PDate.class, new PDateRenderer());
		_table.setDefaultRenderer(PTime.class, new PTimeRenderer());

		initColumnSizes(_table);

		JScrollPane scrollPane = new JScrollPane(_table);
		scrollPane.setVerticalScrollBarPolicy(JScrollPane.VERTICAL_SCROLLBAR_AS_NEEDED);
		scrollPane.setPreferredSize(new Dimension(250, 250));
		scrollPane.setBorder(BorderFactory.createEtchedBorder());

		// Create a label to put messages during an action event.
		_resultField = new JLabel("Not queried/subscribed yet...");
		_resultField.setBorder(BorderFactory.createEmptyBorder(5, 5, 5, 5));

		// Put everything together.
		setLayout(new BorderLayout());
		add(inputsPanel, BorderLayout.PAGE_START);
		add(scrollPane, BorderLayout.CENTER);
		add(_resultField, BorderLayout.PAGE_END);
	}

	public String getSql() {
		return _sqlField.getText();
	}

	public JTable getTable() {
		return _table;
	}

	public void setResult(String text) {
		_resultField.setText(text);
	}

	private void initColumnSizes(JTable table) {
		MyTableModel model = (MyTableModel)table.getModel();
		TableColumn column;
		Component rendererComponent;
		int headerWidth;
		int cellWidth;
		Object[] colValues = model.getColumnValues();
		int[] colSizes = new int[colValues.length];

		TableCellRenderer headerRenderer = table.getTableHeader().getDefaultRenderer();
		for (int i=0; i<colValues.length; i++) {
			column = table.getColumnModel().getColumn(i);

			rendererComponent = headerRenderer.getTableCellRendererComponent(null, column.getHeaderValue(), false, false, 0, 0);
			headerWidth = rendererComponent.getPreferredSize().width;

			rendererComponent = table.getDefaultRenderer(model.getColumnClass(i)).
			getTableCellRendererComponent(table, colValues[i],	false, false, 0, i);
			cellWidth = rendererComponent.getPreferredSize().width;

//			log.info("Initializing width of column "+i+". HeaderWidth="+headerWidth+"; CellWidth="+cellWidth);

			colSizes[i] = Math.max(headerWidth, cellWidth);
		}
//		log.info("before: "+Arrays.toString(colSizes));
		Dimension d = _subscriber.getTabbedPane().getSize();
		int width = 15;
		for (int i=0; i<colValues.length; i++) {
			width += colSizes[i];
		}
		if (colValues.length>0 && width<d.width) {
			int space = d.width - width;
			int delta = space / colSizes.length;
			
			if (delta>0) {
				for (int i=0; i<colValues.length; i++) {
					colSizes[i] += delta;
				}
			}
		}
//		log.info("after: "+Arrays.toString(colSizes));

		for (int i=0; i<colValues.length; i++) {
			column = table.getColumnModel().getColumn(i);
			column.setPreferredWidth(colSizes[i]);
		}
	}



	private JRadioButton _qnsButton;
	private JRadioButton _qButton;
	private JRadioButton _sButton;

	protected JComponent createButtons(ActionListener listener) {
		JPanel panel = new JPanel(new FlowLayout(FlowLayout.TRAILING));

		_qnsButton = new JRadioButton("Snap&Subscribe");
		_qnsButton.setMnemonic(KeyEvent.VK_N);
		_qnsButton.setSelected(true);

		_qButton = new JRadioButton("Snap");
		_qButton.setMnemonic(KeyEvent.VK_Q);

		_sButton = new JRadioButton("Subscribe");
		_sButton.setMnemonic(KeyEvent.VK_S);

		ButtonGroup group = new ButtonGroup();
		group.add(_qnsButton);
		group.add(_qButton);
		group.add(_sButton);

		panel.add(_qnsButton);
		panel.add(_qButton);
		panel.add(_sButton);

		_qnsButton.addActionListener(this);
		_qButton.addActionListener(this);
		_sButton.addActionListener(this);

		JButton button = new JButton("Stop");
		button.addActionListener(listener);
		button.setActionCommand(ACTION_STOP);
		button.setToolTipText("Stop subscription");
		panel.add(button);

		button = new JButton("Clean");
		button.addActionListener(listener);
		button.setActionCommand(ACTION_CLEAN);
		button.setToolTipText("Empty the table");
		panel.add(button);

		button = new JButton("Execute");
		button.addActionListener(listener);
		button.setActionCommand(ACTION_EXECUTE);
		button.setToolTipText("Start snap and/or subscription");
		panel.add(button);

		panel.setBorder(BorderFactory.createEmptyBorder(0, 0, 5, 5));
		return panel;
	}

	@Override
	// ActionListener
	public void actionPerformed(ActionEvent e) {
		String command = e.getActionCommand();
		log.info("action: " + command);

		if (ACTION_STOP.equals(command)) {
			if (unSubscribe()) {
				_resultField.setText(ACTION_STOP+" invoked...");
			} else {
				_resultField.setText("No active subscription...");
			}
		} else if (ACTION_CLEAN.equals(command)) {
			MyTableModel model = (MyTableModel)_table.getModel();
			model.clean();
//			_keyField.setText("");
//			_keyCheckBox.setSelected(false);
			_resultField.setText(ACTION_CLEAN+" invoked...");
		} else if (ACTION_EXECUTE.equals(command)) {
			MyTableModel model = (MyTableModel)_table.getModel();
			String sql = _sqlField.getText();
			String keys = _keyField.getText();
			try {
				SqlParserResult sqlComps = SqlParser.parseSql(sql);
				List<String> selectFields = sqlComps.getSelectFields(); // TODO if selectFields is empty then get from meta info
				model.setColumns(selectFields);
				List<String> keyFields = SqlParser.parseListOfKeys(keys);
				model.setKeyFields(keyFields);
				if (_qnsButton.isSelected()) {
					_subId = _client.snapSubscribe(sqlComps, this);
					_resultField.setText(_qnsButton.getText()+" executing...");
				} else if (_qButton.isSelected()) {
					_subId = _client.snap(sqlComps, this);
					_resultField.setText(_qButton.getText()+" executed...");
				} else if (_sButton.isSelected()) {
					_subId = _client.subscribe(sqlComps, this);
					_resultField.setText(_sButton.getText()+" executing...");
				}
			} catch (Exception x) {
				log.error("", x);
				_resultField.setText(x.getMessage());
			}
		}
	}

	@Override
	// ItemListener
	public void itemStateChanged(ItemEvent e) {
		int stateChanged = e.getStateChange();
		log.info("state: " + stateChanged);

		MyTableModel model = (MyTableModel)_table.getModel();
		if (stateChanged == ItemEvent.SELECTED) {
			String sql = _sqlField.getText();
			try {
		        SqlParserResult sqlComps = SqlParser.parseSql(sql);
		    	String subject = sqlComps.getFromTable();
				ObjMetaInfo metaInfo = ObjectManager.getInstance().getSubjectMetaInfo(subject);
				if (metaInfo == null) {
					_resultField.setText("Unknown subject '"+subject+"'");
				} else {
					String keys = "";
					List<String> keysList = new ArrayList<>();
					for (FieldMetaInfo fmi : metaInfo.getKeys()) {
						keys += (("".equals(keys)) ? "" : ",") + fmi.getName();
						keysList.add(fmi.getName());
					}
					_keyField.setText(keys);
					model.setGroupByKey(true);
				}
			} catch (Exception x) {
				log.error("", x);
				_resultField.setText(x.getMessage());
			}
		} else {
//			_keyField.setText("");
			model.setGroupByKey(false);
		}
	}

	public boolean unSubscribe() {
		if (_subId!=null) {
			_client.unsubscribe(_subId);
			_subId = null;
			return true;
		}
		return false;
	}


	private class MyTableModel extends AbstractTableModel {
		private List<Obj>    _data = new ArrayList<Obj>();
		private boolean      _groupByKey;
		private String[]     _keyFields = {};
		private List<Object> _index = new ArrayList<>();
		private String[]     _fixedColumnNames = {};
		private Object[]     _fixedColumnValues = {};
		private Class[]      _fixedColumnClasses = {};
		private String[]     _columnNames = {};
		private Object[]     _columnValues = {};
		private Class[]      _columnClasses = {};
		private boolean      _hasAllColumns;


		@Override // AbstractTableModel
		public int getColumnCount() {
			return _fixedColumnNames.length + _columnNames.length;
		}

		@Override // AbstractTableModel
		public int getRowCount() {
			return _data.size();
		}

		@Override // AbstractTableModel
		public String getColumnName(int col) {
			if (col<_fixedColumnNames.length) {
				return _fixedColumnNames[col];
			}
			return _columnNames[col-_fixedColumnNames.length];
		}

		@Override // AbstractTableModel
		public Object getValueAt(int row, int col) {
			try {
				return _data.get(row).get(getColumnName(col));
			} catch (Exception x) {
				log.error("", x);
			}
			return null;
		}

		@Override // AbstractTableModel
		public Class getColumnClass(int col) {
			if (getRowCount()==0) return String.class;
			if (col<_fixedColumnNames.length) {
				return _fixedColumnClasses[col];
			}
			return _columnClasses[col-_fixedColumnNames.length];
		}

		@Override // AbstractTableModel
		public boolean isCellEditable(int row, int col) {
			return false;
		}


		public void clean() {
			_fixedColumnNames = new String[0];
			_fixedColumnValues = new Object[0];
			_fixedColumnClasses = new Class[0];
			_columnNames = new String[0];
			_columnValues = new Object[0];
			_columnClasses = new Class[0];
			for (int i=0; i<_data.size(); i++) {
				_data.get(i).stopUsing();
			}
			_data = new ArrayList<>();
			_keyFields = new String[0];
			_groupByKey = false;
			_index = new ArrayList<>();

			fireTableStructureChanged();
		}

		public Object[] getColumnValues() {
			Object[] values = new Object[_fixedColumnValues.length+_columnValues.length];
			for (int i=0; i<_fixedColumnValues.length; i++) {
				values[i] = _fixedColumnValues[i];
			}
			for (int i=0; i<_columnValues.length; i++) {
				values[i+_fixedColumnValues.length] = _columnValues[i];
			}
			return values;
		}

		public void setColumns(List<String> fixedColumnNames) {
			_hasAllColumns = false;
			int fixedColumnCount = 0;
			for (String colName : fixedColumnNames) {
				if ("*".equals(colName)) {
					_hasAllColumns = true;
				} else {
					fixedColumnCount++;
				}
			}
			_fixedColumnNames = new String[fixedColumnCount];
			int i = 0;
			for (String colName : fixedColumnNames) {
				if (!"*".equals(colName)) {
					_fixedColumnNames[i++] = colName;
				}
			}
			_fixedColumnValues = new Object[fixedColumnCount];
			_fixedColumnClasses = new Class[fixedColumnCount];
		}

		public void setKeyFields(List<String> keysList) {
			if (keysList==null) {
				_keyFields = new String[0];
			} else {
				_keyFields = new String[keysList.size()];
				for (int i=0; i<_keyFields.length; i++) {
					_keyFields[i] = keysList.get(i);
				}
			}
		}

		public void setGroupByKey(boolean groupByKey) {
			_groupByKey = groupByKey;
		}

		public void add(Obj obj) {
			if (obj.getPubType()== PubType.SNP) return;

			obj.startUsing();
			boolean columnAdded = false;
			try {
				if (_hasAllColumns) {
					if (log.isDebugEnabled()) log.debug("obj="+obj);
					int numFields = obj.getNumFields();
					for (int i=0; i<numFields; i++) {
						FieldMetaInfo fieldMetaInfo = obj.getFieldMetaInfo(i);
						Object fieldValue = obj.get(i);
						String fieldName = fieldMetaInfo.getName();
						columnAdded = addValueToColumn(fieldName, fieldValue, columnAdded);
					}
					if (obj.hasAdHocs()) {
						for (String fieldName : obj.getAdHocFields()) {
							Object fieldValue = obj.get(fieldName);
							columnAdded = addValueToColumn(fieldName, fieldValue, columnAdded);
						}
					}
				}
				for (int j=0; j<_fixedColumnNames.length; j++) {
					if (_fixedColumnValues[j]==null) {
						String selectField = _fixedColumnNames[j];
						Object object = obj.get(selectField);
						if (object!=null) {
							_fixedColumnValues[j] = object;
							_fixedColumnClasses[j] = object.getClass();
						} else {
							_fixedColumnClasses[j] = String.class; // will get NPE otherwise
						}
						columnAdded = true;
					}
				}

				Object key = null;
				if (_groupByKey) {
					key = obj.getObjKey();
				} else if (_keyFields.length>0) {
					key = getKeyValue(_keyFields, obj);
				}

				int newRowPos;
				boolean rowAdded = false;
				if (key != null) {
					newRowPos = _index.indexOf(key);
					if (newRowPos<0) {
						newRowPos = 0;
						rowAdded = true;
						_index.add(0, key);
						_data.add(0, obj);
					} else {
						_data.get(newRowPos).stopUsing();
						_data.set(newRowPos, obj);
					}
				} else {
					newRowPos = 0;
					rowAdded = true;
					_data.add(0, obj);
				}

				if (columnAdded) {
					fireTableStructureChanged();
					initColumnSizes(_table);
				} else if (rowAdded) {
					fireTableRowsInserted(newRowPos, newRowPos);
				} else {
					fireTableRowsUpdated(newRowPos, newRowPos);
				}
			} catch (Exception e) {
				e.printStackTrace();
			}
		}

		private boolean arrayContainsValue(String[] array, String value) {
			for (int i=0; i<array.length; i++) {
				if (value.equals(array[i])) return true;
			}
			return false;
		}
		private boolean addValueToColumn(String fieldName, Object fieldValue, boolean columnAdded) {
			if (!arrayContainsValue(_fixedColumnNames, fieldName) && !arrayContainsValue(_columnNames, fieldName)) {
				String[] tmpCol = _columnNames;
				Object[] tmpVal = _columnValues;
				Class[] tmpCls = _columnClasses;
				_columnNames = new String[tmpCol.length+1];
				_columnValues = new Object[tmpCol.length+1];
				_columnClasses = new Class[tmpCol.length+1];
				int k=0; boolean inserted = false;
				for (int j=0; j<_columnNames.length; j++) {
					if (j==_columnNames.length-1 && !inserted) {
						_columnNames[j] = fieldName;
						_columnValues[j] = fieldValue;
						_columnClasses[j] = (fieldValue==null) ? String.class : fieldValue.getClass();
						inserted = true;
					} else if (!inserted && fieldName.compareTo(tmpCol[j])<0) {
						_columnNames[j] = fieldName;
						_columnValues[j] = fieldValue;
						_columnClasses[j] = (fieldValue==null) ? String.class : fieldValue.getClass();
						inserted = true;
					} else {
						_columnNames[j] = tmpCol[k];
						_columnValues[j] = tmpVal[k];
						_columnClasses[j] = tmpCls[k];
						k++;
					}
				}
				columnAdded = true;
			}
			return columnAdded;
		}
		private String getKeyValue(String[] keyFields, Obj obj) {
			String keyVal = "|";
			for (String keyField : keyFields) {
				Object object = obj.get(keyField); // TODO primitive types
				keyVal += ((object==null) ? "null" : (object+""))+"|";
			}
			return keyVal;
		}
	}

	@Override // ISubscriptionListener
	public void onSubscriptionMessage(final Obj obj, final long subsId) {
		obj.startUsing();
		SwingUtilities.invokeLater( // creates a new lambda for each invocation
			() -> {
				MyTableModel model = (MyTableModel)_table.getModel();
				model.add(obj);
				obj.stopUsing();
			}
		);
	}

	private static class PTimestampRenderer extends DefaultTableCellRenderer {
	    public PTimestampRenderer() { super(); }

	    public void setValue(Object value) {
	        setText((value == null) ? "" : (value instanceof PTimestamp ? value.toString() : ("???"+value.getClass().getName())));
	    }
	}

	private static class PNanosRenderer extends DefaultTableCellRenderer {
	    public PNanosRenderer() { super(); }

	    public void setValue(Object value) {
	        setText((value == null) ? "" : (value instanceof PNanos ? value.toString() : ("???"+value.getClass().getName())));
	    }
	}

	private static class PDateRenderer extends DefaultTableCellRenderer {
	    public PDateRenderer() { super(); }

	    public void setValue(Object value) {
	        setText((value == null) ? "" : (value instanceof PDate ? value.toString() : ("???"+value.getClass().getName())));
	    }
	}

	private static class PTimeRenderer extends DefaultTableCellRenderer {
	    public PTimeRenderer() { super(); }

	    public void setValue(Object value) {
	        setText((value == null) ? "" : (value instanceof PTime ? value.toString() : ("???"+value.getClass().getName())));
	    }
	}

}
