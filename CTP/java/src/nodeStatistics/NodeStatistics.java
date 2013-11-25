/**
 * 
 */
package nodeStatistics;

/**
 * A summary with node statistics.
 * 
 * @author Stefan Guna
 * @author Fabrizio Zeni
 * 
 */
public class NodeStatistics {

	/** Equals the number of retransmissions. */
	private int acksFailedCount;

	private int acksReceivedCount;

	private int beaconsSentCount;

	/** Dropped duplicate packets (not forwarded) */
	private int duplicatesDroppedCount;

	/** Duplicate packets received by the base station. */
	private int duplicatesReceivedCount;

	private int lastParent;

	private int lostCount;

	private int msgCount;

	private int nodeId;

	/**
	 * Number of cases when the number of changed parents during an interval
	 * does not fit a message.
	 */
	private int parentOverflowCount;

	private int parentsChanges;

	private int parentsCount;

	/** Dropped packets because of TX queue full. */
	private int txQueueFullCount;

	/** Messages that the node should forward */
	private int msgForwarded;

	/** Time spent listening during duty cycles*/
	private long dcIdle;
	
	/** Time spent transmitting during duty cycles*/
	private long dcData;

	/**
	 * @param acksFailedCount
	 * @param acksReceivedCount
	 * @param beaconsSentCount
	 * @param duplicatesDroppedCount
	 * @param duplicatesReceivedCount
	 * @param lastParent
	 * @param lostCount
	 * @param msgCount
	 * @param nodeId
	 * @param outOfOrderCount
	 * @param parentOverflowCount
	 * @param parentsChanges
	 * @param parentsCount
	 * @param txQueueFullCount
	 * @param msgForwarded
	 * @param dcIdle
	 * @param dcData
	 */
	public NodeStatistics(int acksFailedCount, int acksReceivedCount,
			int beaconsSentCount, int duplicatesDroppedCount,
			int duplicatesReceivedCount, int lastParent, int lostCount,
			int msgCount, int nodeId, int parentOverflowCount,
			int parentsChanges, int parentsCount, int txQueueFullCount,
			int msgForwarded, long dcIdle, long dcData) {
		this.acksFailedCount = acksFailedCount;
		this.acksReceivedCount = acksReceivedCount;
		this.beaconsSentCount = beaconsSentCount;
		this.duplicatesDroppedCount = duplicatesDroppedCount;
		this.duplicatesReceivedCount = duplicatesReceivedCount;
		this.lastParent = lastParent;
		this.lostCount = lostCount;
		this.msgCount = msgCount;
		this.nodeId = nodeId;
		this.parentOverflowCount = parentOverflowCount;
		this.parentsChanges = parentsChanges;
		this.parentsCount = parentsCount;
		this.txQueueFullCount = txQueueFullCount;
		this.msgForwarded = msgForwarded;
		this.dcIdle = dcIdle;
		this.dcData = dcData;
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
	 * @return the lastParent
	 */
	public int getLastParent() {
		return lastParent;
	}

	/**
	 * @return the lostCount
	 */
	public int getLostCount() {
		return lostCount;
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
	 * @return the parentsChanges
	 */
	public int getParentsChanges() {
		return parentsChanges;
	}

	/**
	 * @return the parentsCount
	 */
	public int getParentsCount() {
		return parentsCount;
	}

	/**
	 * @return the txQueueFullCount
	 */
	public int getTxQueueFullCount() {
		return txQueueFullCount;
	}

	/**
	 *  @return the msgForwarded
	 */
	public int getMsgForwarded(){
		return msgForwarded;
	}

	/**
	 *  @return the dcIdle
	 */
	public long getDcIdle(){
		return dcIdle;
	}

	/**
	 *  @return the dcData
	 */
	public long getDcData(){
		return dcData;
	}
}
