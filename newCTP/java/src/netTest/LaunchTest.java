/**
 * 
 */
package netTest;

import java.io.IOException;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;

import net.tinyos.message.MoteIF;
import net.tinyos.packet.BuildSource;
import net.tinyos.packet.PhoenixSource;
import net.tinyos.util.PrintStreamMessenger;
import netTest.consumer.DataMsgDmpConsumer;
import netTest.consumer.StatsMsgDmpConsumer;
import netTest.serial.ConfigMsg;
import netTest.serial.SerialConnection;
import netTest.serial.StartMsg;
import nodeStatistics.OnlineStatisticsConsumer;

/**
 * @author Stefan Guna
 * 
 */
public class LaunchTest {

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		String source = Strings.getString("RouteTest.DATA_SOURCE"); //$NON-NLS-1$
		PhoenixSource phoenix;
		int numberPackets;
		int expIdentifier;
		int deltaTime;
		short testChannel;
		short expType = Constants.PURE_PLR;
		int lplCheckInterval = 0;

		if (args.length >= 5
				&& (args[0].equals("PURE_PLR") || args[0].equals("MAC_PLR") || args[0]
						.equals("LPL_PLR"))) {
			if (args[0].equals("PURE_PLR")) {
				expType = Constants.PURE_PLR;
			} else if (args[0].equals("MAC_PLR")) {
				expType = Constants.MAC_PLR;
			} else if (args[0].equals("LPL_PLR")) {
				expType = Constants.LPL_PLR;
			}
			expIdentifier = Integer.valueOf(args[1]).intValue();
			numberPackets = Integer.valueOf(args[2]).intValue();
			testChannel = Short.valueOf(args[3]).shortValue();
			deltaTime = Integer.valueOf(args[4]).intValue();
			if (expType == Constants.LPL_PLR) {
				if (args.length != 6) {
					printUsageAndExit();
				} else {
					lplCheckInterval = Integer.valueOf(args[5]).intValue();
				}
			} else {
				if (args.length != 5) {
					printUsageAndExit();
				}
				lplCheckInterval = 0;
			}
			if (!checkParameters(expType, deltaTime, Constants.PAYLOAD_LENGTH)) {
				System.exit(-1);
			}
			System.out.println("Opening connection...");
			StartMsg start = new StartMsg();
			phoenix = BuildSource.makePhoenix(source, PrintStreamMessenger.err);
			MoteIF mote = new MoteIF(phoenix);
			// Send start message
			start.set_type(expType);
			start.set_seqn(expIdentifier);
			start.set_nPackets(numberPackets);
			start.set_interval(deltaTime);
			start.set_channel(testChannel);
			start.set_lplCheckInterval(lplCheckInterval);
			// start.set_power(PLR.power);
			try {
				mote.send(MoteIF.TOS_BCAST_ADDR, start);
			} catch (IOException e1) {
				e1.printStackTrace();
				return;
			}
			SerialConnection serialConnection = new SerialConnection(mote);
			serialConnection.addConsumer(new StatsMsgDmpConsumer(source,
					expIdentifier, numberPackets, testChannel, deltaTime,
					expType, lplCheckInterval));
			long time = (numberPackets * deltaTime)
					+ ((Constants.MAX_STATS_RETX + 2)
							* ((int) Math.ceil((double) Constants.NR_NODES
									/ Constants.RX_SIZE)) * Constants.REPORT_RETRY_INTERVAL); // The
			// last
			// node
			// starts
			// after
			// FLOODING_TIMER

			sleep(time);
			System.exit(0);
		} else if (args.length >= 5 && args[0].equals("ROUTING")) {
			ConfigMsg configMsg = new ConfigMsg();
			configMsg.set_seq_no(Integer.parseInt(args[1]));
			configMsg.set_app_period(Integer.parseInt(args[2]));
			configMsg.set_wait_period(Integer.parseInt(Strings
					.getString("RouteTest.WAIT_PERIOD")));
			configMsg.set_routing_boot_period(Integer.parseInt(Strings
					.getString("RouteTest.ROUTING_BOOT_PERIOD")));
			configMsg.set_run_period(Integer.parseInt(args[3]));
			configMsg.set_stop_period(Integer.parseInt(Strings
					.getString("RouteTest.STOP_PERIOD")));
			configMsg.set_power(Short.parseShort(args[4]));

			if (args.length == 6 && args[5].equals("DESYNCH_APP"))
				configMsg.set_randomize_start((byte) 1);
			else if (args.length == 5)
				configMsg.set_randomize_start((byte) 0);
			else
				printUsageAndExit();

			System.out.println(configMsg);

			long time = (Integer.parseInt(Strings
					.getString("RouteTest.WAIT_PERIOD"))
					+ Integer.parseInt(Strings
							.getString("RouteTest.ROUTING_BOOT_PERIOD"))
					+ Integer.parseInt(args[3]) + Integer.parseInt(Strings
					.getString("RouteTest.STOP_PERIOD"))) * 1000;
			time = (long) ((double) time * Double.parseDouble(Strings
					.getString("RouteTest.EXTRA_TIMEOUT")));

			if (Integer.parseInt(Strings
					.getString("RouteTest.NUM_BRIDGE_NODES")) > 0) {
				time += Integer.parseInt(args[3])
						* Integer.parseInt(Strings
								.getString("RouteTest.NUM_NET_NODES"))
						/ Integer.parseInt(args[2])
						* (200 + 10 * Integer.parseInt(Strings
								.getString("RouteTest.NUM_BRIDGE_NODES")));
			}

			if (source == null)
				phoenix = BuildSource.makePhoenix(PrintStreamMessenger.err);
			else
				phoenix = BuildSource.makePhoenix(source,
						PrintStreamMessenger.err);
			MoteIF mote = new MoteIF(phoenix);
			try {
				mote.send(MoteIF.TOS_BCAST_ADDR, configMsg);
			} catch (IOException e) {
				e.printStackTrace();
				return;
			}
			SerialConnection serialConnection = new SerialConnection(mote);
			serialConnection.addConsumer(new DataMsgDmpConsumer(Integer
					.parseInt(args[1]), configMsg));
			serialConnection.addConsumer(new OnlineStatisticsConsumer());
			sleep(time);
			System.out.println("Unique messages received: "
					+ serialConnection.getMessageCount());
			System.out.println("Expected messages: "
					+ serialConnection.getMaxSeqNo());
			System.out.println("Ideal count: "
					+ Integer.parseInt(args[3])
					/ Integer.parseInt(args[2])
					* Integer.parseInt(Strings
							.getString("RouteTest.NUM_NET_NODES")));
			System.exit(0);
		} else {
			printUsageAndExit();
		}
	}

	/**
	 * @param time
	 */
	private static void sleep(long time) {
		DateFormat m_dateFormat = new SimpleDateFormat("dd-MM-yyyy");
		DateFormat m_timeFormat = new SimpleDateFormat("HH:mm:ss");
		Date m_today = new Date();
		String nowDate = m_dateFormat.format(m_today);
		String nowTime = m_timeFormat.format(m_today);

		long min = time / 60000;
		long sec = (time - min * 60000) / 1000;
		System.out.println("Starting at " + nowTime + " " + nowDate);

		System.out.println("Time remaining: " + min + " minutes and " + sec
				+ " seconds");

		System.out.println("Sleeping for " + time + " ms");
		try {
			Thread.sleep(time);
		} catch (Exception e) {
			System.out.println(e);
			System.exit(1);
		}
	}

	private static void printUsageAndExit() {
		System.err
				.println("Usage\n"
						+ "PLR test:\n"
						+ "java netTest.LaunchTest [ PURE_PLR | MAC_PLR | LPL_PLR ] [experiment id] "
						+ "[number of packets] [test channel] [delta time] {LPL check interval}\n"
						+ "Routing test:\n"
						+ "java netTest.LaunchTest ROUTING [experiment id] [app period] "
						+ "[run period] [power] {DESYNCH_APP}");
		System.exit(-1);
	}

	private static boolean checkParameters(short expType, int deltaTime,
			byte payloadLength) {
		switch (expType) {
		case Constants.PURE_PLR:
			if (deltaTime / Constants.NR_NODES < Constants.MIN_SEND_PACKET_TIME) {
				System.err
						.println("Parameter error: Message inter-time is too small!");
				return false;
			}
		case Constants.MAC_PLR:
			break;
		case Constants.LPL_PLR:
			break;
		}
		return true;
	}
}
