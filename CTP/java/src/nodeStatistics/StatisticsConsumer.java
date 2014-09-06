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
	protected BufferedWriter plotNetwork;
	protected boolean netFileExists = false;
	protected BufferedWriter plotNodes;
	protected boolean nodesFileExists = false;

	protected HashMap<Integer, NodeInfo> nodes;

	protected StatisticsConsumer(String logFilename) {
		nodes = new HashMap<Integer, NodeInfo>();
		openFiles(logFilename,0);
	}

	protected StatisticsConsumer(String logFilename, String expDescriptor) {
		nodes = new HashMap<Integer, NodeInfo>();
		openFiles(logFilename,0);
		openFiles(expDescriptor,1);
		openFiles(expDescriptor,2);
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

	private void openFiles(String logFilename, int fileType) {
		File dir = new File(Strings.getString("LOG_DIR"));
		dir.mkdir();

		try {
			if (fileType == 0)  { // globalLog
				globalLog = new BufferedWriter(new FileWriter(Strings
						.getString("LOG_DIR")
						+ File.separator + logFilename, true));
				System.out.println("write statistics in "
						+ Strings.getString("LOG_DIR") + File.separator
						+ logFilename);
			} else if(fileType == 1){ // plotNetwork
				String path = Strings.getString("LOG_DIR")
						+ File.separator + logFilename
						+ "-network";
				File file = new File(path);
				if(file.exists())
					netFileExists = true;
				plotNetwork = new BufferedWriter(new FileWriter(path, true));
			} else { // plotNodes
				String path = Strings.getString("LOG_DIR")
						+ File.separator + logFilename
						+ "-nodes";
				File file = new File(path);
				if(file.exists())
					nodesFileExists = true;
				plotNodes = new BufferedWriter(new FileWriter(path, true));
			}
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

	protected abstract void printGlobalStats() throws IOException;

	protected abstract void printHeader() throws IOException;

	protected abstract void printNodeHeader() throws IOException;

	protected abstract void printNodeStats(NodeInfo node) throws IOException;
	
	protected abstract void printNetworkForPlotHeader() throws IOException;

	protected abstract void printNetworkStatsForPlot(int expId, int activeNodes) throws IOException;

	protected abstract void printNodesForPlotHeader() throws IOException;

	protected abstract void printNodeStatsForPlot(NodeInfo node) throws IOException;
	
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

	public void printPlottable(int id) {
		try {
			Set<Entry<Integer, NodeInfo>> entries = nodes.entrySet();
			int nextNodeId;
			int counter = 0;
			int nodes = Integer.parseInt(Strings.getString("RouteTest.NUM_NET_NODES"));
			
			if(!nodesFileExists)
				printNodesForPlotHeader();
			if(!netFileExists)
				printNetworkForPlotHeader();
			plotNodes.write("" + id);
			for (Iterator<Entry<Integer, NodeInfo>> i = entries.iterator(); i
					.hasNext();) {
				Entry<Integer, NodeInfo> entry = i.next();
				nextNodeId = entry.getValue().getStatistics().getNodeId();
				while(nextNodeId > counter++)
					plotNodes.write("\t" + 0 + "\t" + 0 + "\t" + 0 + "\t" + 0);
				if(nextNodeId != 0)
					printNodeStatsForPlot(entry.getValue());	
			}
			while(counter++ < nodes)
					plotNodes.write("\t" + 0 + "\t" + 0 + "\t" + 0 + "\t" + 0);
			plotNodes.write("\n");
			plotNodes.flush();
			printNetworkStatsForPlot(id, entries.size());
			plotNetwork.flush();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
}
