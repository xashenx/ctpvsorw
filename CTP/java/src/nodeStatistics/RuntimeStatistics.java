/**
 * 
 */
package nodeStatistics;

/**
 * Statistics that can be computed at runtime. The statistics that cannot be
 * computed at runtime are lost message, out-of-order packets that require
 * parsing the entire history.
 * 
 * @author Stefan Guna
 * @author Fabrizio Zeni
 * 
 */
public class RuntimeStatistics {
	/** Equals the number of retransmissions. */
	private int acksFailedCount;

	private int acksReceivedCount;

	private int beaconsSentCount;

	/** Dropped duplicate packets (not forwarded) */
	private int duplicatesDroppedCount;

	/** Duplicate packets received by the base station. */
	private int duplicatesReceivedCount;

	private int humidity;

	private int lastParent;

	private int msgCount;

	private int nodeId;

	/**
	 * Number of cases when the number of changed parents during an interval
	 * does not fit a message.
	 */
	private int parentOverflowCount;

	private int parentsCount;

	private int temperature;

	/** Dropped packets because of TX queue full. */
	private int txQueueFullCount;
	
	private int msgForwarded;

	private int voltage;

	/**
	 * @param acksFailedCount
	 * @param acksReceivedCount
	 * @param beaconsSentCount
	 * @param duplicatesDroppedCount
	 * @param duplicatesReceivedCount
	 * @param lastParent
	 * @param msgCount
	 * @param nodeId
	 * @param parentOverflowCount
	 * @param parentsCount
	 * @param txQueueFullCount
	 * @param msgForwarded
	 */
	public RuntimeStatistics(int acksFailedCount, int acksReceivedCount,
			int beaconsSentCount, int duplicatesDroppedCount,
			int duplicatesReceivedCount, int lastParent, int msgCount,
			int nodeId, int parentOverflowCount, int parentsCount,
			int txQueueFullCount, int msgForwarded, int temperature, int humidity, int voltage) {
		this.acksFailedCount = acksFailedCount;
		this.acksReceivedCount = acksReceivedCount;
		this.beaconsSentCount = beaconsSentCount;
		this.duplicatesDroppedCount = duplicatesDroppedCount;
		this.duplicatesReceivedCount = duplicatesReceivedCount;
		this.lastParent = lastParent;
		this.msgCount = msgCount;
		this.nodeId = nodeId;
		this.parentOverflowCount = parentOverflowCount;
		this.parentsCount = parentsCount;
		this.txQueueFullCount = txQueueFullCount;
		this.msgForwarded = msgForwarded;
		this.temperature = temperature;
		this.voltage = voltage;
		this.humidity = humidity;
	}

	/**
	 * @return the acksFailedCount
	 */
	public int getAcksFailedCount() {
		return acksFailedCount;
	}

	/**
	 * @return the acksReceivedCount
	 */
	public int getAcksReceivedCount() {
		return acksReceivedCount;
	}

	/**
	 * @return the beaconsSentCount
	 */
	public int getBeaconsSentCount() {
		return beaconsSentCount;
	}

	/**
	 * The number of messages dropped by this node. It includes duplicate
	 * messages not forwarded and messages due to TX queue full.
	 * 
	 * @return Total number of dropped messages.
	 */
	public int getDroppedCount() {
		return duplicatesDroppedCount + txQueueFullCount;
	}

	/**
	 * @return the duplicatesDroppedCount
	 */
	public int getDuplicatesDroppedCount() {
		return duplicatesDroppedCount;
	}

	/**
	 * @return the duplicatesReceivedCount
	 */
	public int getDuplicatesReceivedCount() {
		return duplicatesReceivedCount;
	}

	/**
	 * @return the humidity
	 */
	public int getHumidity() {
		return humidity;
	}

	/**
	 * @return the lastParent
	 */
	public int getLastParent() {
		return lastParent;
	}

	/**
	 * @return the msgCount
	 */
	public int getMsgCount() {
		return msgCount;
	}

	/**
	 * @return the nodeId
	 */
	public int getNodeId() {
		return nodeId;
	}

	/**
	 * @return the parentsCount
	 */
	public int getParentsCount() {
		return parentsCount;
	}

	/**
	 * @return the temperature
	 */
	public int getTemperature() {
		return temperature;
	}

	/**
	 * @return the txQueueFullCount
	 */
	public int getTxQueueFullCount() {
		return txQueueFullCount;
	}

	/**
	 * @return the msgForwarded
	 */
	public int getMsgForwardedCount() {
		return msgForwarded;
	}

	/**
	 * @return the voltage
	 */
	public int getVoltage() {
		return voltage;
	}

}
