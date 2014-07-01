/**
 * 
 */
package nodeStatistics;

import java.io.IOException;
import java.text.DecimalFormat;

import netTest.Strings;
import netTest.serial.ConfigMsg;
import netTest.serial.DataMsg;
import netTest.serial.SerializableMessage;

/**
 * @author Stefan Guna
 * 
 */
public class OfflineStatisticsConsumer extends StatisticsConsumer {

	public OfflineStatisticsConsumer() {
		super(Strings.getString("OfflineStatisticsConsumer.GLOBAL_LOG_FILE"));
	}

	public OfflineStatisticsConsumer(String plotFilename) {
		// plain parsing + plottable file
		super(Strings.getString("OfflineStatisticsConsumer.GLOBAL_LOG_FILE"),plotFilename);
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see routeTest.consumer.Consumer#messageReceived(routeTest.serial.DataMsg)
	 */
	public void messageReceived(SerializableMessage msg) {
		if (msg instanceof DataMsg) {
			DataMsg dataMsg = (DataMsg) msg;
			ensureNode(dataMsg.get_routing_data_node_addr(), false).addMessage(
					dataMsg);
		}
	}

	public void printConfiguration(ConfigMsg msg) throws IOException {
		globalLog.write(msg.toString());
	}

	/**
	 * @param id
	 * @throws IOException
	 */
	public void printExperimentId(int id) throws IOException {
		globalLog.write("Experiment id: " + id + "\n");
	}

	protected void printGlobalStats() throws IOException {
		globalLog.write("Msgs" + "\t" + "AckRx" + "\t" + "Beacon" + "\t"
				+ "DuplDropped" + "\t" + "DuplRx" + "\t" + "Lost" + "\t"
				//+ "AckFail" + "\t" + "MsgForw\t" + "DutyCycle\t" + "NbChanges" 
				+ "AckFail" + "\t" + "MsgForw" 
				+ "\t" + "TxQueueFull" + "\n");
		globalLog.write(GlobalStatistics.uniqueMsgReceived + "\\" + GlobalStatistics.msgCount + "\t"
				+ GlobalStatistics.acksReceivedCount + "\t"
				+ GlobalStatistics.beaconsSentCount + "\t"
				+ GlobalStatistics.duplicatesDroppedCount + "\t" + "\t"
				+ GlobalStatistics.duplicatesReceivedCount + "\t"
				+ GlobalStatistics.lostCount + "\t"
				+ GlobalStatistics.acksFailedCount + "\t"
				+ GlobalStatistics.msgForwarded + "\t"
				//+ GlobalStatistics.dcData + "/" + GlobalStatistics.dcIdle + "\t"
				//+ GlobalStatistics.parentChanges + "\t" + "\t"
				+ GlobalStatistics.txQueueFullCount + "\n");
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see nodeStatistics.StatisticsConsumer#printHeader()
	 */
	@Override
	protected void printHeader() throws IOException {
		// TODO Auto-generated method stub

	}

	protected void printNodeHeader() throws IOException {
		globalLog.write("Node" + "\t" + "1°Nb" + "\t" + "Msgs" + "\t"
				+ "AckRx" + "\t" + "Beacon" + "\t" + "DuplDropped" + "\t"
				+ "DuplRx" + "\t" + "Lost" + "\t" + "AckFail" + "\t"
				//+ "NbChanges" + "\t" + "NbCount" + "\t\t"
				+ "NbCount" + "\t\t"
				+ "TxQueueFull" + "\tMsgForwarded\t" + "DC\t" + "WakeUp" + "\t"
				+ "TmpAvg" + "\t" + "HumAvg" + "\n");
	}

	protected void printNodeStats(NodeInfo node) throws IOException {
		NodeStatistics stats = node.getStatistics();
		DecimalFormat decimalFormat = new DecimalFormat("0.#");
		globalLog.write(stats.getNodeId() + "\t" + stats.getLastParent() + "\t"
				+ stats.getUniqueCount() + "\\" + stats.getMsgCount() + "\t" 
				+ +stats.getAcksReceivedCount()
				+ "\t" + stats.getBeaconsSentCount() + "\t"
				+ stats.getDuplicatesDroppedCount() + "\t" + "\t"
				+ stats.getDuplicatesReceivedCount() + "\t"
				+ stats.getLostCount() + "\t" + stats.getAcksFailedCount()
			//	+ "\t" + stats.getParentsChanges() + "\t" + "\t"
				+ "\t" + stats.getParentsCount() + "\t" + "\t"
				+ stats.getTxQueueFullCount() + "\t" + "\t" 
				+ stats.getMsgForwarded() + "\t" + "\t"
				//+ stats.getDcData() + "/" + stats.getDcIdle() + "\n");
				+ stats.getDcIdle() + "\t" + stats.getDcData() + "\t"
				+ decimalFormat.format(stats.getTmpAvg()) + "\t"
				+ decimalFormat.format(stats.getHumAvg()) + "\n");
	}
	
	protected void printNetworkForPlotHeader() throws IOException {
		plotNetwork.write("ID" + "\t" + "DEL" + "\t" + "EXP" + "\t"
					+ "MAX" + "\n");
	}

	protected void printNetworkStatsForPlot(int expId, int activeNodes) throws IOException {
		plotNetwork.write(expId + "\t" + GlobalStatistics.uniqueMsgReceived + "\t"
					+ GlobalStatistics.msgCount + "\t"
					+ activeNodes*60 + "\n"); 
					// 60 is an assumption for the data rate used.
	}

	protected void printNodesForPlotHeader() throws IOException {
		//plotNodes.write(Strings.getString("RouteTest.NUM_NET_NODES"));
		int nodes = Integer.parseInt(Strings.getString("RouteTest.NUM_NET_NODES"));
		int counter = 0;
		plotNodes.write("EXP" + "\t" + "T1" + "\t" + "H1" + "\t" + "DC1");
		while(counter++ < nodes - 2)
			plotNodes.write("\t" + "T" + (counter+1) + "\t" + "H" + (counter+1) + "\t"
					+ "DC" + (counter+1));
		plotNodes.write("\n");
	}

	protected void printNodeStatsForPlot(NodeInfo node) throws IOException {
		NodeStatistics stats = node.getStatistics();
		DecimalFormat decimalFormat = new DecimalFormat("0.#");
		plotNodes.write("\t" + decimalFormat.format(stats.getTmpAvg()) + "\t"
		+ decimalFormat.format(stats.getHumAvg()) + "\t" + stats.getDcIdle());
	}
}
