/**
 * 
 */
package nodeStatistics;

import java.io.IOException;
import java.text.DecimalFormat;

import netTest.Strings;
import netTest.serial.DataMsg;
import netTest.serial.SerializableMessage;

/**
 * @author Stefan Guna
 * @author Fabrizio Zeni
 * 
 */
public class OnlineStatisticsConsumer extends StatisticsConsumer {

	public OnlineStatisticsConsumer() {
		super(Strings.getString("OnlineStatisticsConsumer.GLOBAL_LOG_FILE"));
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see netTest.consumer.Consumer#messageReceived(routeTest.serial.DataMsg)
	 */
	public void messageReceived(SerializableMessage msg) {
		if (msg instanceof DataMsg) {
			DataMsg dataMsg = (DataMsg) msg;
			ensureNode(dataMsg.get_routing_data_node_addr(), true).addMessage(
					dataMsg);
			printStats();
		}
	}

	protected void printGlobalStats() throws IOException {
		globalLog.write("Msgs" + "\t" + "ACKRx" + "\t" + "Beacon" + "\t"
				+ "DuplDropped" + "\t" + "AckFail" + "\t" 
				+ "Forwarded" + "\t" + "DutyCycle(D/I)" + "\t" + "TxQueueFull"
				+ "\n");
		globalLog.write(GlobalStatistics.msgCount + "\t"
				+ GlobalStatistics.acksReceivedCount + "\t"
				+ GlobalStatistics.beaconsSentCount + "\t"
				+ GlobalStatistics.duplicatesDroppedCount + "\t" + "\t"
				+ GlobalStatistics.acksFailedCount + "\t"
				+ GlobalStatistics.msgForwarded + "\t"
				+ GlobalStatistics.dcData + "/" + GlobalStatistics.msgForwarded + "\t"
				+ GlobalStatistics.txQueueFullCount + "\n");
	}

	protected void printHeader() throws IOException {
		globalLog.write("\33[2J");
		globalLog.write("\33[H");
	}

	protected void printNodeHeader() throws IOException {
		globalLog.write("Node" + "\t" + "Parent" + "\t" + "Msgs" + "\t"
				+ "AckRx" + "\t" + "Beacon" + "\t" + "DuplDropped" + "\t"
				+ "AckFail" + "\t" + "ParentsCount" + "\t" + "TxQueueFull"
				+ "\tMsgForw\t" + "DC(D/I)\t" + "Temp" + "\t" + "Hum" + "\t" + "Voltage" + "\n");
	}

	protected void printNodeStats(NodeInfo node) throws IOException {
		RuntimeStatistics stats = node.getRuntimeStatistics();
		double temperature = (double) (-39.6 + 0.01 * stats.getTemperature());
		double humidity = (double) (-4.0 + 0.0405 * stats.getHumidity() - 0.0000028 * (stats
				.getHumidity() * stats.getHumidity()));
		double voltage = (double) (stats.getVoltage() / 4096. * 3.);
		DecimalFormat decimalFormat = new DecimalFormat("0.##");

		globalLog.write(stats.getNodeId() + "\t" + stats.getLastParent() + "\t"
				+ stats.getMsgCount() + "\t" + stats.getAcksReceivedCount()
				+ "\t" + stats.getBeaconsSentCount() + "\t"
				+ stats.getDuplicatesDroppedCount() + "\t" + "\t"
				+ stats.getAcksFailedCount() + "\t" + stats.getParentsCount()
				+ "\t" + "\t" + stats.getTxQueueFullCount() + "\t" + "\t"
				+ "\t" + "\t" + stats.getMsgForwardedCount() + "\t" + "\t"
				+ "\t" + "\t" + stats.getDcData() + "/" + stats.getDcIdle() + "\t" + "\t"
				+ decimalFormat.format(temperature) + "\t"
				+ decimalFormat.format(humidity) + "\t"
				+ decimalFormat.format(voltage) + "\n");
	}

	@Override
	protected void printNetworkForPlotHeader() throws IOException {}

	@Override
	protected void printNetworkStatsForPlot(int expId, int activeNodes) throws IOException {}

	@Override
	protected void printNodesForPlotHeader() throws IOException {}

	@Override
	protected void printNodeStatsForPlot(NodeInfo node) throws IOException {}
}
