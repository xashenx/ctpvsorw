/**
 * 
 */
package netTest.consumer;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileOutputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.ObjectOutputStream;
import java.io.PrintWriter;
import java.text.DateFormat;
import java.text.NumberFormat;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.Hashtable;
import java.util.Locale;
import java.util.Vector;

import net.tinyos.message.Message;
import netTest.Constants;
import netTest.Strings;
import netTest.serial.DataMsg;
import netTest.serial.SerializableMessage;
import netTest.serial.StatsMsg;

/**
 * A consumer that logs everything to a file.
 * 
 * @author Stefan Guna
 * 
 */
public class StatsMsgDmpConsumer implements Consumer {
	private BufferedWriter log;

	private ObjectOutputStream objStream;

	private int numberPackets;
	private int expIdentifier;
	private int deltaTime;
	private short testChannel;
	private short expType;
	private int lplCheckInterval;
	// static short power;
	private String source = null;

	private int num_of_stat_per_msg = Constants.RX_SIZE;
	private int num_of_stat_msgs = (int) Math.ceil((double) Constants.NR_NODES
			/ Constants.RX_SIZE);

	Vector[] msgs = new Vector[Constants.NR_NODES];
	int stats;

	public StatsMsgDmpConsumer(String source, int expIdentifier,
			int numberPackets, short testChannel, int deltaTime, short expType,
			int lplCheckInterval) {
		if (num_of_stat_msgs == 0)
			num_of_stat_msgs = 1;
		this.numberPackets = numberPackets;
		this.expIdentifier = expIdentifier;
		this.deltaTime = deltaTime;
		this.testChannel = testChannel;
		this.expType = expType;
		this.lplCheckInterval = lplCheckInterval;
		try {
			for (int i = 0; i < Constants.NR_NODES; i++) {
				msgs[i] = new Vector<Integer>();
			}
			// Displaying info
			System.out.println("Source: " + source);
			System.out.println("Experiment ID: " + expIdentifier);
			System.out.println("Number of packets to transmit: "
					+ numberPackets);
			System.out.println("Radio channel: " + testChannel);
			// System.out.println("Radio power: " + PLR.power);
			System.out.println("Delta Time [ms]: " + deltaTime);
			if (expType == Constants.PURE_PLR) {
				System.out.println("Pure PLR Experiment");
			} else if (expType == Constants.MAC_PLR) {
				System.out.println("MAC PLR Experiment");
			} else {
				System.out.println("LPL PLR Experiment with "
						+ lplCheckInterval + " ms check interval");
			}
			System.out.println("Number of stats per msg: "
					+ num_of_stat_per_msg);

			System.out.println("Number of stats msgs: " + num_of_stat_msgs);

			// Dumping out...
			NumberFormat nf = NumberFormat.getInstance(Locale.ENGLISH);
			NumberFormat nf1 = NumberFormat.getInstance(Locale.ENGLISH);
			nf.setMinimumIntegerDigits(2);
			nf1.setMaximumFractionDigits(3);
			nf1.setMinimumFractionDigits(3);

			Calendar calendar = new GregorianCalendar();
			int day = calendar.get(Calendar.DAY_OF_MONTH);
			int month = calendar.get(Calendar.MONTH);
			int year = calendar.get(Calendar.YEAR);
			month++;

			File dir = new File(Strings.getString("LOG_DIR"));
			dir.mkdir();

			BufferedWriter filebuf = new BufferedWriter(new FileWriter(Strings
					.getString("LOG_DIR")
					+ File.separator
					+ "TC-"
					+ expIdentifier
					+ ".DATE-"
					+ nf.format(day)
					+ "-"
					+ nf.format(month)
					+ "-"
					+ year
					+ ".log", true));
			PrintWriter printout = new PrintWriter(filebuf);

			// Printing info
			printout.println("Source: " + source);
			printout.println("Experiment ID: " + expIdentifier);
			printout.println("Number of packets to transmit: " + numberPackets);
			printout.println("Radio channel: " + testChannel);
			// printout.println("Radio power: " + PLR.power);
			printout.println("Delta Time [ms]: " + deltaTime);
			if (expType == Constants.PURE_PLR) {
				printout.println("Pure PLR Experiment");
			} else if (expType == Constants.MAC_PLR) {
				printout.println("MAC PLR Experiment");
			} else {
				printout.println("LPL PLR Experiment with " + lplCheckInterval
						+ " ms check interval");
			}

			printout.flush();
			printout.close();

		} catch (Exception e) {
			System.out.println(e);
			System.exit(1);
		}
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see
	 * routeTest.consumer.Consumer#messageReceived(routeTest.serial.DataMsg)
	 */
	public void messageReceived(SerializableMessage msg) {
		if (msg instanceof StatsMsg) {
			statsReceived(msg);
		} else {
			throw new RuntimeException("Got wrong message type: " + msg);
		}
	}

	private void statsReceived(Message orig_msg) {
		try {
			int RSSI, LQI, bad_packet = 0, sender;

			Calendar calendar = new GregorianCalendar();
			int hour = calendar.get(Calendar.HOUR);
			int minutes = calendar.get(Calendar.MINUTE);
			int seconds = calendar.get(Calendar.SECOND);
			if (calendar.get(Calendar.AM_PM) != 0) {
				hour = hour + 12;
			}
			int day = calendar.get(Calendar.DAY_OF_MONTH);
			int month = calendar.get(Calendar.MONTH);
			int year = calendar.get(Calendar.YEAR);
			month = month + 1;

			NumberFormat nf = NumberFormat.getInstance(Locale.ENGLISH);
			NumberFormat nf1 = NumberFormat.getInstance(Locale.ENGLISH);
			nf.setMinimumIntegerDigits(2);
			nf1.setMaximumFractionDigits(3);
			nf1.setMinimumFractionDigits(3);

			// Extract data from packet
			StatsMsg d_msg = (StatsMsg) orig_msg;

			int[] d_rx_packets = new int[num_of_stat_per_msg];
			short[] d_rx_lqi = new short[num_of_stat_per_msg];
			short[] d_rx_rssi = new short[num_of_stat_per_msg];

			d_rx_packets = d_msg.get_rx_packets();
			sender = d_msg.get_nodeid();

			System.out.println("RECEIVED from " + sender + " seqN "
					+ d_msg.get_seqn());

			if (sender < Constants.NR_NODES
					&& !msgs[sender].contains(d_msg.get_seqn())) {
				for (int i = 0; i < num_of_stat_per_msg
						&& d_msg.get_seqn() * num_of_stat_per_msg + i < Constants.NR_NODES; i++) {
					if (d_rx_packets[i] > numberPackets)
						bad_packet = 1;
				}
				if (bad_packet != 1) {

					msgs[sender].add(d_msg.get_seqn());

					// Dumping out...
					File dir = new File(Strings.getString("LOG_DIR"));
					dir.mkdir();

					BufferedWriter filebuf = new BufferedWriter(new FileWriter(
							Strings.getString("LOG_DIR") + File.separator
									+ "TC-" + d_msg.get_experimentId()
									+ ".DATE-" + nf.format(day) + "-"
									+ nf.format(month) + "-" + year + ".log",
							true));

					PrintWriter printout = new PrintWriter(filebuf);

					d_rx_lqi = d_msg.get_rx_lqi();
					d_rx_rssi = d_msg.get_rx_rssi();

					float batteryInit = (float) (d_msg.get_initBattery() / 4096.0 * 3.0);
					float batteryEnd = (float) (d_msg.get_endBattery() / 4096.0 * 3.0);
					double temperature = (double) (-39.60 + 0.01 * d_msg
							.get_avgTemperature());
					double humidity = (double) (-4.0 + 0.0405
							* d_msg.get_avgHumidity() - 0.0000028 * (d_msg
							.get_avgHumidity() * d_msg.get_avgHumidity()));

					System.out
							.print("Received Statistics from Node: " + sender);
					if (sender - d_msg.get_seqn() * num_of_stat_per_msg < num_of_stat_per_msg
							&& sender - d_msg.get_seqn() * num_of_stat_per_msg >= 0) {
						System.out.print(" Nr Hop:"
								+ d_rx_rssi[sender - d_msg.get_seqn()
										* num_of_stat_per_msg]
								+ " Seq N:"
								+ d_msg.get_seqn()
								+ " Stats Retx:"
								+ d_rx_lqi[sender - d_msg.get_seqn()
										* num_of_stat_per_msg]);
					} else {
						System.out.print(" Seq N:" + d_msg.get_seqn());
					}

					System.out.println(" (Experiment ID: " + d_msg.get_seqn()
							+ " got from node " + d_msg.get_expSender() + " - "
							+ nf.format(hour) + ":" + nf.format(minutes) + ":"
							+ nf.format(seconds) + " @ " + nf.format(day) + "-"
							+ nf.format(month) + "-" + year + ")");

					System.out.print("Node: " + sender
							+ " Support Data: Avg Temperature:" + temperature
							+ " Avg Humidity:" + humidity + " Init Battery:"
							+ batteryInit + " End Battery:" + batteryEnd);

					if (sender - d_msg.get_seqn() * num_of_stat_per_msg < num_of_stat_per_msg
							&& sender - d_msg.get_seqn() * num_of_stat_per_msg >= 0) {
						System.out.println(" Radio Activations:"
								+ d_rx_packets[sender - d_msg.get_seqn()
										* num_of_stat_per_msg]);
					} else {
						System.out.println();
					}

					System.out.println("Ref ID\tRcv\tRSSI[dBm]\tLQI");

					printout.print("Received Statistics from Node: " + sender);

					if (sender - d_msg.get_seqn() * num_of_stat_per_msg < num_of_stat_per_msg
							&& sender - d_msg.get_seqn() * num_of_stat_per_msg >= 0) {
						printout.print(" Nr Hop:"
								+ d_rx_rssi[sender - d_msg.get_seqn()
										* num_of_stat_per_msg]
								+ " Seq N:"
								+ d_msg.get_seqn()
								+ " Stats Retx:"
								+ d_rx_lqi[sender - d_msg.get_seqn()
										* num_of_stat_per_msg]);
					} else {
						printout.print(" Seq N:" + d_msg.get_seqn());
					}

					printout.print(" (Experiment ID: " + d_msg.get_seqn()
							+ " got from node " + d_msg.get_expSender() + " - "
							+ nf.format(hour) + ":" + nf.format(minutes) + ":"
							+ nf.format(seconds) + " @ " + nf.format(day) + "-"
							+ nf.format(month) + "-" + year + ")");
					printout.print("Node: " + sender
							+ " Support Data: Avg Temperature:" + temperature
							+ " Avg Humidity:" + humidity + " Init Battery:"
							+ batteryInit + " End Battery:" + batteryEnd);

					if (sender - d_msg.get_seqn() * num_of_stat_per_msg < num_of_stat_per_msg
							&& sender - d_msg.get_seqn() * num_of_stat_per_msg >= 0) {
						printout.println(" Radio Activations:"
								+ d_rx_packets[sender - d_msg.get_seqn()
										* num_of_stat_per_msg]);
					} else {
						printout.println();
					}

					printout.println("Ref ID\tRcv\tRSSI[dBm]\tLQI");

					for (int i = 0; i < num_of_stat_per_msg
							&& d_msg.get_seqn() * num_of_stat_per_msg + i < Constants.NR_NODES; i++) {
						RSSI = d_rx_rssi[i];
						LQI = d_rx_lqi[i];
						RSSI = -RSSI;
						if (d_msg.get_seqn() * num_of_stat_per_msg + i != sender) {
							System.out.println((int) (d_msg.get_seqn()
									* num_of_stat_per_msg + i)
									+ "\t"
									+ d_rx_packets[i]
									+ "\t"
									+ RSSI
									+ "\t" + LQI);
							printout.println((int) (d_msg.get_seqn()
									* num_of_stat_per_msg + i)
									+ "\t"
									+ d_rx_packets[i]
									+ "\t"
									+ RSSI
									+ "\t" + LQI);

						}
					}
					// Prints out who's remaining
					System.out.print("Waiting for: \n");
					printout.println("Waiting for: \n");
					for (int i = 0; i < Constants.NR_NODES; i++) {
						System.out.print("Node " + i + " <");
						printout.print("Node " + i + " <");
						for (int j = 0; j < this.num_of_stat_msgs; j++) {
							if (!msgs[i].contains(j)) {
								System.out.print(" " + j);
								printout.print(" " + j);
							}
						}
						System.out.print(" >\n");
						printout.print(" >\n");
					}
					System.out.println();
					printout.println("\n");
					printout.flush();
					printout.close();
					stats = stats + 1;
				}
			}

			if (stats >= Constants.NR_NODES * this.num_of_stat_msgs) {
				System.exit(0);
			}
		} catch (Exception e) {
			System.err.println(">>>>" + e.getMessage());
			e.printStackTrace();
		}
	}
}