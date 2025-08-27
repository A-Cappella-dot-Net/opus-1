package net.a_cappella.datapublisher;

import net.a_cappella.continuo.datatypes.PDate;
import net.a_cappella.continuo.datatypes.PNanos;
import net.a_cappella.continuo.datatypes.PTime;
import net.a_cappella.continuo.datatypes.PTimestamp;
import net.a_cappella.continuo.managed.ObjectManager;
import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.continuo.obj.meta.FieldMetaInfo;
import net.a_cappella.continuo.obj.meta.FieldType;
import net.a_cappella.continuo.obj.meta.ObjMetaInfo;
import net.a_cappella.madrigal.common.constants.MadrigalLogOp;
import net.a_cappella.madrigal.common.constants.MadrigalMode;
import net.a_cappella.madrigal.common.interfaces.ISwingBean;
import net.a_cappella.madrigal.common.obj.EcnUserStatusObj;
import net.a_cappella.madrigal.common.obj.UserStatusObj;
import net.a_cappella.madrigal.user.UserManagerClient;
import net.a_cappella.presto.obj.MapObj;
import net.a_cappella.presto.ps.PrestoClient;
import org.apache.commons.text.StringEscapeUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.swing.*;
import javax.swing.border.EtchedBorder;
import java.awt.*;
import java.awt.event.*;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

public class DataPublisher extends WindowAdapter implements ActionListener, FocusListener, ISwingBean {
    private static final Logger log = LoggerFactory.getLogger(DataPublisher.class);

    public static final String ACTION_SUBJECT = "Subject";
	public static final String ACTION_TEMPLATE = "Template";
	public static final String ACTION_PUBLISH = "Publish";
	public static final String ACTION_PUBLISH_ALL = "PublishAll";
	public static String NL = "\n";

	private JTabbedPane _tabbedPane;
	private int _tabCount = 0;

    private UserManagerClient _userManagerClient;

    private final PrestoClient _client;

    public DataPublisher(PrestoClient client) {
        _client = client;
        System.out.println((SwingUtilities.isEventDispatchThread() ? "" : "Not ")+"On Event Dispatch Thread");
	}

    public void init() {
        Dimension screenSize = Toolkit.getDefaultToolkit().getScreenSize();
		JFrame frame = new MyFrame(this);
		Dimension size = frame.getSize();
		int x = (int) (screenSize.getWidth() - size.getWidth()) / 2;
		int y = (int) (screenSize.getHeight() - size.getHeight()) / 2;
		frame.setLocation(new Point(x, y));
		frame.setVisible(true);

		JPanel topPanel = new JPanel();
		frame.add(topPanel);

		_tabbedPane = new JTabbedPane();
		_tabbedPane.setBorder(BorderFactory.createCompoundBorder(
				BorderFactory.createEtchedBorder(EtchedBorder.RAISED, Color.GRAY, Color.DARK_GRAY),
				BorderFactory.createEmptyBorder(2, 2, 2, 2)));
		_tabbedPane.setTabLayoutPolicy(JTabbedPane.SCROLL_TAB_LAYOUT);

		topPanel.setLayout(new BorderLayout());
		topPanel.add(_tabbedPane, BorderLayout.CENTER);
		topPanel.add(createButtons(this), BorderLayout.PAGE_END);

		addTabbedPaneTab();
	}




	private class MyFrame extends JFrame {
		public MyFrame(final DataPublisher controller) {
			super("Data Publisher");

			setDefaultCloseOperation(DO_NOTHING_ON_CLOSE);
			addWindowListener(controller);
			setSize(new Dimension(500, 700));
			addMenuBar(controller);
		}

		private void addMenuBar(final DataPublisher controller) {
			JMenuBar menuBar = new JMenuBar();
			setJMenuBar(menuBar);

			JMenu menu = new JMenu("File");
			menu.setMnemonic(KeyEvent.VK_F);
			menuBar.add(menu);

			JMenuItem item = new JMenuItem("Exit");
			item.setMnemonic(KeyEvent.VK_X);
			item.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					log.info("Exit request");
					controller.exit(MyFrame.this);
				}
			});
			menu.add(item);

			menu = new JMenu("Tab");
			menu.setMnemonic(KeyEvent.VK_T);
			menuBar.add(menu);

			item = new JMenuItem("New");
			item.setMnemonic(KeyEvent.VK_N);
			item.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					log.info("New Tab request");
					addTabbedPaneTab();
				}
			});
			menu.add(item);

			menu = new JMenu("Help");
			menu.setMnemonic(KeyEvent.VK_H);
			menuBar.add(menu);

			item = new JMenuItem("About");
			item.setMnemonic(KeyEvent.VK_A);
			item.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					log.info("Help About request");
				}
			});
			menu.add(item);
		}
	}

	// This method must be evoked from the event-dispatching thread.
	public void exit(JFrame frame) {
		if (true || exitConfirmed(frame)) { // TODO just for testing
			log.info("Exiting...");
			System.exit(0);
		}
		log.info("Exit operation not confirmed; staying alive.");
	}

	private boolean exitConfirmed(JFrame frame) {
		String s1 = "Exit";
		String s2 = "Cancel";
		Object[] options = { s1, s2 };
		int n = JOptionPane.showOptionDialog(frame,
				"Do you really want to exit?", "Exit Confirmation",
				JOptionPane.YES_NO_OPTION, JOptionPane.QUESTION_MESSAGE, null,
				options, s1);
		if (n == JOptionPane.YES_OPTION) {
			return true;
		} else {
			return false;
		}
	}

	@Override // WindowAdapter
	public void windowClosing(WindowEvent e) {
		exit((JFrame) e.getSource());
	}






	private void addTabbedPaneTab() {
		int noOfTabs = _tabbedPane.getTabCount();
		String title = "Tab " + (_tabCount++);
		_tabbedPane.add(title, new TabContents(this));
		_tabbedPane.setTabComponentAt(noOfTabs, new TabWithButton(_tabbedPane));
		_tabbedPane.setSelectedIndex(noOfTabs);
	}

	protected JComponent createButtons(ActionListener listener) {
		JPanel panel = new JPanel(new FlowLayout(FlowLayout.TRAILING));

		JButton button = new JButton("Template");
		button.addActionListener(listener);
		button.setActionCommand(ACTION_TEMPLATE);
		button.setToolTipText("Create template message for specified subject");
		panel.add(button);

		button = new JButton("Publish");
		button.addActionListener(listener);
		button.setActionCommand(ACTION_PUBLISH);
		button.setToolTipText("Publish from the selected tab");
		panel.add(button);

		button = new JButton("Publish All");
		button.addActionListener(listener);
		button.setActionCommand(ACTION_PUBLISH_ALL);
		button.setToolTipText("Publish from all the tabs");
		panel.add(button);

		panel.setBorder(BorderFactory.createEmptyBorder(0, 0, 5, 5));
		return panel;
	}




	@Override // ActionListener
	public void actionPerformed(ActionEvent e) {
		String command = e.getActionCommand();
		log.info("action: "+command);

		switch (command) {
		case ACTION_SUBJECT:
			int selIdx = _tabbedPane.getSelectedIndex();
			TabContents tabContents = (TabContents) _tabbedPane.getComponentAt(selIdx);
			String subject = tabContents.getSubject();
			if (subject!=null && !"".equals(subject)) {
				_tabbedPane.setTitleAt(selIdx, subject);
			}
			break;
		case ACTION_PUBLISH_ALL:
			log.info("Publish All invoked... ");
			int numTabs = _tabbedPane.getTabCount();
			for (int i=0; i<numTabs; i++) {
				publishFromTab(i);
			}
			break;
		case ACTION_PUBLISH:
			log.info("Publish invoked... ");
			selIdx = _tabbedPane.getSelectedIndex();
			if (selIdx>=0) {
				publishFromTab(selIdx);
			}
			break;
		case ACTION_TEMPLATE:
			log.info("Template invoked... ");
			selIdx = _tabbedPane.getSelectedIndex();
			if (selIdx>=0) {
				createTemplate(selIdx);
			}
			break;
		}
	}

	@Override // FocusListener
	public void focusGained(FocusEvent e) {
		log.info(e.toString());
	}
	@Override // FocusListener
	public void focusLost(FocusEvent e) {
		log.info(e.toString());
        Component component = e.getComponent();
        if (component instanceof JTextField) {
			int selIdx = _tabbedPane.getSelectedIndex();
			if (selIdx>=0) {
				TabContents tabContents = (TabContents) _tabbedPane.getComponentAt(selIdx);
				String subject = tabContents.getSubject();
				if (subject!=null && !"".equals(subject)) {
					_tabbedPane.setTitleAt(selIdx, subject);
				}
			}
        }
	}



	private void publishFromTab(int i) {
		String now = new SimpleDateFormat("[hh:mm:ss.SSS]").format(new Date());
		final TabContents tabContents = (TabContents) _tabbedPane.getComponentAt(i);
		String subject = tabContents.getSubject();
		String fieldsText = tabContents.getFieldsText();
		try {
			Map<String, Object> fieldsMap = parseText(fieldsText, subject);
			if (subject==null || "".equals(subject)) {
				tabContents.setResult(now+" Invalid subject '"+subject+"'" );
			} else {
				log.info("subject="+subject);
				log.info("fieldsMap="+fieldsMap);

				ObjMetaInfo metaInfo = ObjectManager.getInstance().getSubjectMetaInfo(subject);

				Obj obj;
				if (metaInfo == null) {
					MapObj map = new MapObj();
					map.setSubject(subject);
					obj = map;
				} else {
					obj = ObjectManager.getInstance().acquire(metaInfo.getObjType());
				}
				obj.set(fieldsMap);

				if (obj instanceof UserStatusObj) { // special handling
					UserStatusObj userStatus = (UserStatusObj) obj;
					if (MadrigalMode.REQUEST == userStatus.getMadrigalMode()) {
						String uid = userStatus.getUid();
						String pwd = userStatus.getPwd();
						MadrigalLogOp op = userStatus.getOp();
						boolean rejectIfLoggedIn = userStatus.isRejectIfLoggedIn();
						boolean forceLogout = userStatus.isForceLogout();

						if (_userManagerClient==null) {
							_userManagerClient = new UserManagerClient(_client, null) {
								private String userStatusResult = "";
								private String ecnUserStatusResult = "";
								@Override
								public void onUserStatusResult(UserStatusObj userStatus) {
									log.info("onUserStatusResult="+userStatus);
									String now = new SimpleDateFormat("[hh:mm:ss.SSS]").format(new Date());
									userStatusResult = now+" onUserStatusResult="+userStatus;
									tabContents.setResult(userStatusResult+" "+ecnUserStatusResult);
								}
								@Override
								public void onEcnUserStatusResult(EcnUserStatusObj ecnUserStatus) {
									log.info("onEcnUserStatusResult="+ecnUserStatus);
									String now = new SimpleDateFormat("[hh:mm:ss.SSS]").format(new Date());
									ecnUserStatusResult = now+" onEcnUserStatusResult="+ecnUserStatus;
									tabContents.setResult(userStatusResult+" "+ecnUserStatusResult);
								}
							};
							_userManagerClient.start();
						}
						if (MadrigalLogOp.login == op) {
							_userManagerClient.login(uid, pwd, rejectIfLoggedIn);
						} else if (MadrigalLogOp.logout == op) {
							_userManagerClient.logout(uid, pwd, forceLogout);
						} else {
							throw new Exception("unknown op "+op);
						}

						tabContents.setResult(now+" Published successfully on '"+subject+"'");
						return;
					}
				}

				_client.publish(obj);
				tabContents.setResult(now+" Published successfully on '"+subject+"'");
			}
		} catch (Exception e) {
			log.error("", e);
			tabContents.setResult(now+" Publication on '"+subject+"' failed. "+e.getMessage());
		}
	}

	private void createTemplate(int i) {
		String now = new SimpleDateFormat("[hh:mm:ss.SSS]").format(new Date());
		final TabContents tabContents = (TabContents) _tabbedPane.getComponentAt(i);
		String subject = tabContents.getSubject();
		ObjMetaInfo metaInfo = ObjectManager.getInstance().getSubjectMetaInfo(subject);

		String template = "";
		if (metaInfo == null) {
			tabContents.setResult(now+" Unknown subject '"+subject+"'");
		} else {
			template = "----- keys -----\n";
			for (FieldMetaInfo fmi : metaInfo.getKeys()) {
				template += fieldTemplate(fmi);
			}
			template += "----- non keys -----\n";
			for (FieldMetaInfo fmi : metaInfo.getNonKeys()) {
				template += fieldTemplate(fmi);
			}
		}
		template += "----- ad hocs -----\n";
		tabContents.setFieldsText(template);
		tabContents.setResult(now+" Template for '"+subject+"'");
	}
	private String fieldTemplate(FieldMetaInfo fieldMetaInfo) {
		return fieldMetaInfo.getName()+" = "+typedValue(fieldMetaInfo)+"\n";
	}

	private String typedValue(FieldMetaInfo fieldMetaInfo) {
		FieldType fieldType = fieldMetaInfo.getType();

		switch (fieldType) {
		case CHAR: return "' '";
		case STRING: return "";
		case SHORT:
		case INT:
		case LONG: return "0";
		case FLOAT:
		case DOUBLE: return "0.0";
		case BOOLEAN: return "false";
		case TIMESTAMP:
		case NANOS:
		case TIME:
		case DATE: return "now";
		case ENUM: {
			String className = fieldMetaInfo.getField().getGenericType().getTypeName();
			String enumValue = "";
			try {
				enumValue = Class.forName(className).getEnumConstants()[0].toString();
			} catch (Exception x) {}
			return className+"."+enumValue;
		}
		default: return "Unknown Type";
		}
	}


	private Map<String, Object> parseText(String fieldsText, String subject) throws Exception {
		if (fieldsText==null || "".equals(fieldsText)) return null;
		log.info("raw="+fieldsText);

		ObjMetaInfo metaInfo = ObjectManager.getInstance().getSubjectMetaInfo(subject);

		Map<String, Object> map = new HashMap<>();
		String[] entries = fieldsText.split(NL);
		for (int i=0; i<entries.length; i++) {
			String entry = entries[i];
			int pos = entry.indexOf('=');
			if (pos>0) {
				String key = entry.substring(0, pos).trim();
				String rawValue = entry.substring(pos+1).trim();
				Object value = covertToProperType(rawValue, (metaInfo==null) ? null : metaInfo.getFieldMetaInfo(key));
				map.put(key, value);
			}
		}
		log.info("map="+map);
		return map;
	}
	private Object covertToProperType(String str, FieldMetaInfo fmi) throws Exception {
		if (fmi!=null) {
			switch (fmi.getType()) {
			case CHAR:
				str = (str.startsWith("\'") && str.endsWith("\'")) ? StringEscapeUtils.unescapeJava(str.substring(1, str.length()-1)) : str;
				return str.charAt(0);
			case STRING: return (str.startsWith("\"") && str.endsWith("\"")) ? str.substring(1, str.length()-1) : str;
			case SHORT: return Short.parseShort(str);
			case INT: return Integer.parseInt(str);
			case LONG: return Long.parseLong(str);
			case FLOAT: return Float.parseFloat(str);
			case DOUBLE: return Double.parseDouble(str);
			case BOOLEAN: return Boolean.parseBoolean(str);
			case TIMESTAMP: return PTimestamp.parsePTimestamp(str);
			case NANOS: return PNanos.parsePNanos(str);
			case TIME: return PTime.parsePTime(str);
			case DATE: return PDate.parsePDate(str);
			case ENUM: return parseEnum(str);
			default: return "Unknown Type";
			}
		}
		// ad hoc fields
		if ("now".equals(str)) {
			return PTimestamp.parsePTimestamp(str);
		}
		if (str.startsWith("\'") && str.endsWith("\'")) {
			return StringEscapeUtils.unescapeJava(str.substring(1, str.length()-1)).charAt(0);
		}
		if (str.startsWith("\"") && str.endsWith("\"")) {
			str = str.substring(1, str.length()-1);
		}
		try {
			return Long.parseLong(str);
		} catch(NumberFormatException ignore) {}
		try {
			return Double.parseDouble(str);
		} catch(NumberFormatException ignore) {}
		try {
			return new PTimestamp(str);
		} catch (ParseException ignore) {}
		try {
			return new PDate(str);
		} catch (ParseException ignore) {}
		try {
			return new PTime(str);
		} catch (ParseException ignore) {}
		if ("true".equalsIgnoreCase(str)) {
			Boolean.parseBoolean(str);
			return Boolean.TRUE;
		} else if ("false".equalsIgnoreCase(str)) {
			return Boolean.FALSE;
		}
		return str;
	}

	private <T extends Enum<T>> T parseEnum(String str) throws Exception {
		int pos = str.lastIndexOf(".");
		String enumClass = str.substring(0, pos);
		String enumValue = str.substring(pos+1);
		Class<T> clazz = (Class<T>) Class.forName(enumClass);
		return Enum.valueOf(clazz, enumValue);
	}
}
