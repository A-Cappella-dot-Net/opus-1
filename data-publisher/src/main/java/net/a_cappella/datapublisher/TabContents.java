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

package net.a_cappella.datapublisher;

import javax.swing.*;
import java.awt.*;

public class TabContents extends JPanel {
	private final JTextField subjectField;
	private final JTextArea textArea;
	private final JLabel resultField;

	public TabContents(DataPublisher publisher) {
		subjectField = new JTextField();
		subjectField.setActionCommand(DataPublisher.ACTION_SUBJECT);
		subjectField.setToolTipText("e.g., user.dir");
		subjectField.addActionListener(publisher);
		subjectField.addFocusListener(publisher);

		JLabel subjectLabel = new JLabel(DataPublisher.ACTION_SUBJECT + ": ");
		subjectLabel.setLabelFor(subjectField);

		textArea = new JTextArea();
		textArea.setFont(new Font("Courier New", Font.PLAIN, 14));
		textArea.setLineWrap(true);
		textArea.setWrapStyleWord(true);
		textArea.setToolTipText(splitToolTip("e.g.,\necn=BTEC\nuser=marketmaker"));
		JScrollPane areaScrollPane = new JScrollPane(textArea);
		areaScrollPane.setVerticalScrollBarPolicy(JScrollPane.VERTICAL_SCROLLBAR_AS_NEEDED);
		areaScrollPane.setPreferredSize(new Dimension(250, 250));
		areaScrollPane.setBorder(BorderFactory.createEtchedBorder());

		// Lay out the text controls and the labels.
		JPanel inputsPanel = new JPanel(new GridBagLayout());
		inputsPanel.setBorder(BorderFactory.createEmptyBorder(5, 5, 5, 5));

		JLabel[] labels = { subjectLabel };
		JComponent[] textFields = { subjectField };
		addLabelTextRows(labels, textFields, inputsPanel);

		// Create a label to put messages during an action event.
		resultField = new JLabel("Nothing published yet...");
		resultField.setBorder(BorderFactory.createEmptyBorder(5, 5, 5, 5));

		// Put everything together.
		setLayout(new BorderLayout());
		add(inputsPanel, BorderLayout.PAGE_START);
		add(areaScrollPane, BorderLayout.CENTER);
		add(resultField, BorderLayout.PAGE_END);
	}

	public String getSubject() {
		return subjectField.getText();
	}
	public String getFieldsText() {
		return textArea.getText();
	}
	public void setFieldsText(String text) {
		textArea.setText(text);
	}
	public void setResult(String text) {
		resultField.setText(text);
	}

	private void addLabelTextRows(JLabel[] labels, JComponent[] textFields,
			Container container) {
		GridBagConstraints c = new GridBagConstraints();
		c.anchor = GridBagConstraints.EAST;
		int numLabels = labels.length;

		for (int i = 0; i < numLabels; i++) {
			c.gridwidth = GridBagConstraints.RELATIVE; // next-to-last
			c.fill = GridBagConstraints.NONE; // reset to default
			c.weightx = 0.0; // reset to default
			container.add(labels[i], c);

			c.gridwidth = GridBagConstraints.REMAINDER; // end row
			c.fill = GridBagConstraints.HORIZONTAL;
			c.weightx = 1.0;
			container.add(textFields[i], c);
		}
	}

	private String splitToolTip(String tip) {
		return "<html>"+tip.replaceAll("\n", "<br>")+"</html>";
	}
}
