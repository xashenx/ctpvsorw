/**
 * 
 */
package netTest;

import java.io.EOFException;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.ObjectInputStream;

import netTest.serial.ConfigMsg;
import netTest.serial.DataMsg;
import nodeStatistics.OfflineStatisticsConsumer;

/**
 * @author Stefan Guna
 * 
 */
public class HistoryProcessor {

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		if (args.length != 1) {
			System.err.println("Usage: java HistoryProcessor [file name]");
			return;
		}
		try {
			OfflineStatisticsConsumer statConsumer = new OfflineStatisticsConsumer();
			ObjectInputStream in = new ObjectInputStream(new FileInputStream(
					args[0]));
			DataMsg msg;
			int id = in.readInt();
			ConfigMsg configMsg = (ConfigMsg) in.readObject();
			statConsumer.printExperimentId(id);
			statConsumer.printConfiguration(configMsg);
			try {
				while ((msg = (DataMsg) in.readObject()) != null)
					statConsumer.messageReceived(msg);
			} catch (EOFException e) {

				statConsumer.printStats();
			} finally {
				in.close();
			}

		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (ClassNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

	}

}
