package net.a_cappella.datasubscriber;

import net.a_cappella.madrigal.common.interfaces.ISwingBean;
import net.a_cappella.presto.ps.PrestoClient;
import net.a_cappella.presto.ps.sql.SqlParser;
import net.a_cappella.presto.ps.sql.SqlParserResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.swing.*;
import javax.swing.border.EtchedBorder;
import java.awt.*;
import java.awt.event.*;
import java.util.concurrent.atomic.AtomicBoolean;

public class DataSubscriber extends WindowAdapter implements ISwingBean, FocusListener {
    private static final Logger log = LoggerFactory.getLogger(DataSubscriber.class);

    private final int _initialWidth;
    private final int _initialHeight;
	private JTabbedPane _tabbedPane;
	private int _tabCount = 0;

    private final PrestoClient _client;
    public PrestoClient getClient() {
    	return _client;
    }
    private String _ftGroup;
    private final AtomicBoolean _active = new AtomicBoolean(false);

	public DataSubscriber(PrestoClient client, int initialWidth, int initialHeight) {
		_client = client;
		_initialWidth = initialWidth;
		_initialHeight = initialHeight;
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
		_tabbedPane.addContainerListener(
				new ContainerListener() {
					@Override
					public void componentAdded(ContainerEvent e) {
					}

					@Override
					public void componentRemoved(ContainerEvent e) {
						((TabContents) e.getChild()).unSubscribe();
					}
				}
		);

		topPanel.setLayout(new BorderLayout());
		topPanel.add(_tabbedPane, BorderLayout.CENTER);

		addTabbedPaneTab();
	}

	private class MyFrame extends JFrame {
		public MyFrame(final DataSubscriber controller) {
			super("Data Subscriber");

			setDefaultCloseOperation(DO_NOTHING_ON_CLOSE);
			addWindowListener(controller);
			setSize(new Dimension(_initialWidth, _initialHeight));
			addMenuBar(controller);
		}

		private void addMenuBar(final DataSubscriber controller) {
			JMenuBar menuBar = new JMenuBar();
			setJMenuBar(menuBar);

			JMenu menu = new JMenu("File");
			menu.setMnemonic(KeyEvent.VK_F);
			menuBar.add(menu);

			JMenuItem item = new JMenuItem("Print");
			item.setMnemonic(KeyEvent.VK_P);
			item.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					log.info("Print request");
					int selIdx = _tabbedPane.getSelectedIndex();
					if (selIdx>=0) {
						TabContents tabContents = (TabContents) _tabbedPane.getComponentAt(selIdx);
						JTable table = tabContents.getTable();
						try {
						    if (!table.print()) {
						        System.err.println("User cancelled printing");
						    }
						} catch (java.awt.print.PrinterException x) {
						    System.err.format("Cannot print %s%n", x.getMessage());
						}
					}
				}
			});
			menu.add(item);

			item = new JMenuItem("Exit");
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

	// This method must be invoked from the event-dispatching thread.
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
		TabContents tabContents = new TabContents(this);
		_tabbedPane.add(title, tabContents);
		_tabbedPane.setTabComponentAt(noOfTabs, new TabWithButton(_tabbedPane));
		_tabbedPane.setSelectedIndex(noOfTabs);
		// sns.addListener(tabContents); // TODO remove when closing the tab!!!
	}

	public JTabbedPane getTabbedPane() {
		return _tabbedPane;
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
				String sql = tabContents.getSql();
				if (sql!=null && !"".equals(sql)) {
					try {
				        SqlParserResult sqlComps = SqlParser.parseSql(sql);
				    	String subject = sqlComps.getFromTable();
						_tabbedPane.setTitleAt(selIdx, subject);
					} catch (Exception x) {}
				}
			}
        }
	}
}
