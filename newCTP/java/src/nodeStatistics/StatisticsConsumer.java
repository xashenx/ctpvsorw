/**
 * 
 */
package nodeStatistics;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Set;
import java.util.Map.Entry;

import netTest.Strings;
import netTest.consumer.Consumer;
import netTest.serial.SerializableMessage;


/**
 * @author Stefan Guna
 * 
 */
public abstract class StatisticsConsumer implements Consumer {
	protected BufferedWriter globalLog;

	protected HashMap<Integer, NodeInfo> nodes;

	protected StatisticsConsumer(String logFilename) {
		nodes = new HashMap<Integer, NodeInfo>();
		openFiles(logFilename);
	}

	protected synchronized NodeInfo ensureNode(int index, boolean runtime) {
		if (nodes.get(index) == null) {
			NodeInfo result = new NodeInfo(index, runtime);
			nodes.put(index, result);
			return result;
		} else
			return nodes.get(index);
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see routeTest.consumer.Consumer#messageReceived(routeTest.serial.DataMsg)
	 */
	public void messageReceived(SerializableMessage msg) {
		// TODO Auto-generated method stub

	}

	private void openFiles(String logFilename) {
		File dir = new File(Strings.getString("LOG_DIR"));
		dir.mkdir();

		try {
			globalLog = new BufferedWriter(new FileWriter(Strings
					.getString("LOG_DIR")
					+ File.separator + logFilename, true));
			System.out.println("write statistics in "
					+ Strings.getString("LOG_DIR") + File.separator
					+ logFilename);
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

	}

	protected abstract void printGlobalStats() throws IOException;

	protected abstract void printHeader() throws IOException;

	protected abstract void printNodeHeader() throws IOException;

	protected abstract void printNodeStats(NodeInfo node) throws IOException;

	public void printStats() {
		try {
			printHeader();
			printNodeHeader();
			Set<Entry<Integer, NodeInfo>> entries = nodes.entrySet();
			for (Iterator<Entry<Integer, NodeInfo>> i = entries.iterator(); i
					.hasNext();) {
				Entry<Integer, NodeInfo> entry = i.next();
				printNodeStats(entry.getValue());
			}
			globalLog.write("----------------------------------------\n");
			printGlobalStats();
			printSystemErrors();
			globalLog.write("\n");
			globalLog.flush();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

	private void printSystemErrors() throws IOException {
		globalLog.write("Parent overflow cnt" + "\t" + "Parent overflow max"
				+ "\n");

		globalLog.write(GlobalStatistics.parentOverflowCount + "\t\t\t"
				+ GlobalStatistics.maxParentOverflow + "\n");
	}
}
