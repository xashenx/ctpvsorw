/**
 * 
 */
package nodeStatistics;

import java.io.IOException;

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
				+ "AckFail" + "\t" + "ParentChanges" + "\t" + "TxQueueFull"
				+ "\n");
		globalLog.write(GlobalStatistics.msgCount + "\t"
				+ GlobalStatistics.acksReceivedCount + "\t"
				+ GlobalStatistics.beaconsSentCount + "\t"
				+ GlobalStatistics.duplicatesDroppedCount + "\t" + "\t"
				+ GlobalStatistics.duplicatesReceivedCount + "\t"
				+ GlobalStatistics.lostCount + "\t"
				+ GlobalStatistics.acksFailedCount + "\t"
				+ GlobalStatistics.parentChanges + "\t" + "\t"
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
		globalLog.write("Node" + "\t" + "Parent" + "\t" + "Msgs" + "\t"
				+ "AckRx" + "\t" + "Beacon" + "\t" + "DuplDropped" + "\t"
				+ "DuplRx" + "\t" + "Lost" + "\t" + "AckFail" + "\t"
				+ "ParentChanges" + "\t" + "ParentsCount" + "\t"
				+ "TxQueueFull" + "\n");
	}

	protected void printNodeStats(NodeInfo node) throws IOException {
		NodeStatistics stats = node.getStatistics();
		globalLog.write(stats.getNodeId() + "\t" + stats.getLastParent() + "\t"
				+ stats.getMsgCount() + "\t" + +stats.getAcksReceivedCount()
				+ "\t" + stats.getBeaconsSentCount() + "\t"
				+ stats.getDuplicatesDroppedCount() + "\t" + "\t"
				+ stats.getDuplicatesReceivedCount() + "\t"
				+ stats.getLostCount() + "\t" + stats.getAcksFailedCount()
				+ "\t" + stats.getParentsChanges() + "\t" + "\t"
				+ stats.getParentsCount() + "\t" + "\t"
				+ stats.getTxQueueFullCount() + "\n");
	}

}
