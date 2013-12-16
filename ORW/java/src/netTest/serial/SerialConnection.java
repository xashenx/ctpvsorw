/**
 * 
 */
package netTest.serial;

import java.util.ArrayList;
import java.util.Collections;
import java.util.ConcurrentModificationException;
import java.util.Iterator;
import java.util.List;

import net.tinyos.message.Message;
import net.tinyos.message.MessageListener;
import net.tinyos.message.MoteIF;
import netTest.consumer.Consumer;

/**
 * Connection to the serial port.
 * 
 * @author Stefan Guna
 * 
 */
public class SerialConnection extends Thread implements MessageListener {

	private List<Consumer> consumerList;

	// private BitSet history;

	private long messageCount = 0, maxSeqNo = -1;

	private Long reboot = new Long((long) (Math.pow(2, 32) - 1));

	@SuppressWarnings("unused")
	private MoteIF node;

	public SerialConnection(MoteIF node) {
		this.node = node;
		// history = new BitSet();
		consumerList = Collections.synchronizedList(new ArrayList<Consumer>());
		node.registerListener(new ResultMsg(), this);
		node.registerListener(new StatsMsg(), this);
		this.start();
	}

	/**
	 * Adds a new consumer
	 * 
	 * @param consumer
	 *            The consumer to be added.
	 */
	public void addConsumer(Consumer consumer) {
		consumerList.add(consumer);
	}

	/**
	 * @return the maxSeqNo
	 */
	public long getMaxSeqNo() {
		return maxSeqNo;
	}

	/**
	 * @return the messageCount
	 */
	public long getMessageCount() {
		return messageCount;
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see net.tinyos.message.MessageListener#messageReceived(int,
	 * net.tinyos.message.Message)
	 */
	public void messageReceived(int to, Message msg) {
		System.out.println(msg);
		if (!(msg instanceof ResultMsg) && !(msg instanceof StatsMsg)) {
			System.err.println("Invalid message received.");
			return;
		}
		if (msg instanceof ResultMsg) {
			ResultMsg resultMsg = (ResultMsg) msg;
			// if (history.get(resultMsg.get_seq_no()) == false) {
			// history.set(resultMsg.get_seq_no());
			// System.out.println(resultMsg.get_rep_seq_no());
			if (reboot.equals(resultMsg.get_rep_seq_no())) {
				System.out.println("\nRoot rebooted!!!");
			}
			if (resultMsg.get_rep_seq_no() > maxSeqNo) {
				maxSeqNo = resultMsg.get_rep_seq_no();
				messageCount++;
				// System.out.print("\t" + messageCount);
			}
			// System.out.println("");
			// } else
			// return;

			// offset is hardcoded
			DataMsg dataMsg = new DataMsg(msg, ResultMsg.size_rep_seq_no());
			msg = dataMsg;
		}

		try {
			for (Iterator<Consumer> it = consumerList.iterator(); it.hasNext();) {
				Consumer consumer = it.next();
				consumer.messageReceived((SerializableMessage) msg);
			}
		} catch (ConcurrentModificationException e) {
			System.err
					.println("The consumer list changed while receiving a message. The message might be lost for some consumers.");

		}
	}

	/**
	 * Removes a consumer from the list.
	 * 
	 * @param consumer
	 *            The consumer to be removed.
	 */
	public void removeConsumer(Consumer consumer) {
		consumerList.remove(consumer);
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see java.lang.Thread#run()
	 */
	public void run() {
		System.out.println("running...");
		while (true) {

		}
	}
}
