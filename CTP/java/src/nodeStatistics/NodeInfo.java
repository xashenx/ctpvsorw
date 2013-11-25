/**
 * 
 */
package nodeStatistics;

import java.util.BitSet;
import java.util.Vector;

import netTest.serial.DataMsg;

/**
 * @author Stefan Guna
 * 
 */
public class NodeInfo {
	/**
	 * Gets the number of parent information stored in the message.
	 * 
	 * @param msg
	 *            The message to look in.
	 * @return The number of parent information in the message.
	 */
	private static int getParentsNo(DataMsg msg) {
		int n = msg.get_routing_data_parents_no();
		if (n > DataMsg.numElements_routing_data_parents_addr())
			n = DataMsg.numElements_routing_data_parents_addr();
		return n;
	}

	/** Number of duplicate packets received by this nodeStatistics. */
	private int duplicates = 0;

	/** A history of messages received. */
	private Vector<DataMsg> history;

	/** The node id. */
	private int id;

	private int lastAckFailed = 0;

	private int lastAckReceived = 0;

	private int lastBeacons = 0;

	private int lastDuplicates = 0;

	private int lastMsgCnt = 0;

	private int parentChanges = 0;

	private int lastForwardedMsg = 0;

	private long lastDcIdle = 0;

	private long lastDcData = 0;

	/**
	 * The last message sent by the nodeStatistics and received. It is not
	 * necessarly the last packet received, but the packet with the biggest
	 * sequence number.
	 */
	private DataMsg lastReceived;

	private int lastTxQueueFull = 0;

	private int lostPackets = 0;

	/** The number of messages with parent overflow. */
	private int parentOverflow = 0;

	/** A history of parents. */
	private BitSet parents;

	private boolean runtime;

	/**
	 * Default constructor.
	 * 
	 * @param id
	 *            The nodeStatistics id.
	 */
	public NodeInfo(int id, boolean runtime) {
		history = new Vector<DataMsg>();
		parents = new BitSet();
		this.runtime = runtime;
		this.id = id;
	}

	/**
	 * Includes a new message in the history.
	 * 
	 * @param msg
	 *            The message to be included.
	 */
	public synchronized void addMessage(DataMsg msg) {
		if (history.size() <= msg.get_routing_data_seq_no())
			history.setSize(msg.get_routing_data_seq_no() + 1);
		/* Mark parent */
		for (int j = 0; j < getParentsNo(msg); j++)
			parents.set(msg.getElement_routing_data_parents_addr(j));

		if ((lastReceived == null || msg.get_routing_data_seq_no() > lastReceived
				.get_routing_data_seq_no())
				&& (!runtime || history.get(msg.get_routing_data_seq_no()) == null)) {
			lastReceived = msg;

			synchronized (GlobalStatistics.class) {
				GlobalStatistics.acksFailedCount += lastReceived
						.get_routing_data_ack_failed()
						- lastAckFailed;
				GlobalStatistics.acksReceivedCount += lastReceived
						.get_routing_data_ack_received()
						- lastAckReceived;
				GlobalStatistics.beaconsSentCount += lastReceived
						.get_routing_data_beacons()
						- lastBeacons;
				GlobalStatistics.duplicatesDroppedCount += lastReceived
						.get_routing_data_dropped_duplicates()
						- lastDuplicates;
				GlobalStatistics.txQueueFullCount += lastReceived
						.get_routing_data_tx_queue_full()
						- lastTxQueueFull;
				GlobalStatistics.msgCount += (lastReceived
						.get_routing_data_seq_no() + 1)
						- lastMsgCnt;
				GlobalStatistics.msgForwarded += lastReceived
						.get_routing_data_forwarded()
						- lastForwardedMsg;
				GlobalStatistics.dcIdle += lastReceived
						.get_routing_data_dcIdle()
						- lastDcIdle;
				GlobalStatistics.dcData += lastReceived
						.get_routing_data_dcData()
						- lastDcData;
			}

			lastAckFailed = lastReceived.get_routing_data_ack_failed();

			lastAckReceived = lastReceived.get_routing_data_ack_received();

			lastBeacons = lastReceived.get_routing_data_beacons();

			lastDuplicates = lastReceived.get_routing_data_dropped_duplicates();

			lastTxQueueFull = lastReceived.get_routing_data_tx_queue_full();

			lastMsgCnt = lastReceived.get_routing_data_seq_no() + 1;

			lastForwardedMsg = lastReceived.get_routing_data_forwarded();

			lastDcIdle = lastReceived.get_routing_data_dcIdle();

			lastDcData = lastReceived.get_routing_data_dcData();

		}

		if (runtime)
			return;

		try {
			if (history.get(msg.get_routing_data_seq_no()) == null)
				history.add(msg.get_routing_data_seq_no(), msg);
			else {
				duplicates++;
				synchronized (GlobalStatistics.class) {
					GlobalStatistics.duplicatesReceivedCount++;
				}
			}
		} catch (ArrayIndexOutOfBoundsException e) {
			history.setSize(msg.get_routing_data_seq_no());
			history.add(msg.get_routing_data_seq_no(), msg);
		}
	}

	/**
	 * Access to runtime statistics
	 * 
	 * @return Runtime Statistics
	 */
	public RuntimeStatistics getRuntimeStatistics() {
		return new RuntimeStatistics(
				lastReceived.get_routing_data_ack_failed(),
				lastReceived.get_routing_data_ack_received(),
				lastReceived.get_routing_data_beacons(),
				lastReceived.get_routing_data_dropped_duplicates(), duplicates,
				lastParent(), lastReceived.get_routing_data_seq_no() + 1, id,
				parentOverflow, parents.cardinality(),
				lastReceived.get_routing_data_tx_queue_full(),
				lastReceived.get_routing_data_forwarded(),
				lastReceived.get_routing_data_dcIdle(),
				lastReceived.get_routing_data_dcData(),
				lastReceived.get_temperature(), lastReceived.get_humidity(),
				lastReceived.get_voltage());

	}

	private NodeStatistics offlineStats = null;

	/**
	 * Access to node statics.
	 * 
	 * @return Node statics.
	 */
	public NodeStatistics getStatistics() {
		if (offlineStats != null)
			return offlineStats;
		updateLostPackets();
		updateParentChanges();
		GlobalStatistics.parentChanges += parentChanges;
		GlobalStatistics.lostCount += lostPackets;
		offlineStats = new NodeStatistics(lastReceived.get_routing_data_ack_failed(),
				lastReceived.get_routing_data_ack_received(),
				lastReceived.get_routing_data_beacons(),
				lastReceived.get_routing_data_dropped_duplicates(),
				duplicates, lastParent(), lostPackets, 
				lastReceived.get_routing_data_seq_no() + 1, id, parentOverflow,
				parentChanges, parents.cardinality(),
				lastReceived.get_routing_data_tx_queue_full(),
				lastReceived.get_routing_data_forwarded(),
				lastReceived.get_routing_data_dcIdle(),
				lastReceived.get_routing_data_dcData());
		return offlineStats;
	}

	/**
	 * Computes the last parent.
	 * 
	 * @return The last parent of this node.
	 */
	private int lastParent() {
		int m = lastReceived.get_routing_data_parents_no();
		if (m == 0)
			return -1;
		if (m > DataMsg.numElements_routing_data_parents_addr()) {
			m = DataMsg.numElements_routing_data_parents_addr();
			parentOverflow++;

		}
		return lastReceived.getElement_routing_data_parents_addr(m - 1);
	}

	/**
	 * Computes the number of lost packets as the number of packets sent by this
	 * node that did not reach the base station.
	 */
	private void updateLostPackets() {
		lostPackets = 0;
		for (int i = 0; i < lastReceived.get_routing_data_seq_no(); i++)
			if (history.get(i) == null)
				lostPackets++;
	}

	/**
	 * Returns the number of parents this nodeStatistics changed.
	 * 
	 */
	private void updateParentChanges() {
		int lastParentId = -1;
		parentChanges = 0;
		for (int i = 0; i < history.size(); i++) {
			DataMsg msg = history.get(i);
			if (msg == null)
				continue;
			int m = msg.get_routing_data_parents_no();
			if (m > DataMsg.numElements_routing_data_parents_addr())
				m = DataMsg.numElements_routing_data_parents_addr();
			for (int j = 0; j < m; j++) {
				if (lastParentId == -1) {
					lastParentId = msg.getElement_routing_data_parents_addr(j);
					continue;
				}
				if (lastParentId != msg.getElement_routing_data_parents_addr(j)) {
					parentChanges++;
					lastParentId = msg.getElement_routing_data_parents_addr(j);
				}
			}
		}
	}
}
