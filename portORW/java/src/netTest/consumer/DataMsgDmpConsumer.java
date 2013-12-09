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
import java.text.SimpleDateFormat;
import java.util.Date;

import netTest.Strings;
import netTest.serial.ConfigMsg;
import netTest.serial.DataMsg;
import netTest.serial.SerializableMessage;

/**
 * A consumer that logs everything to a file.
 * 
 * @author Stefan Guna
 * 
 */
public class DataMsgDmpConsumer implements Consumer {
	private BufferedWriter log;

	private ObjectOutputStream objStream;

	public DataMsgDmpConsumer(int i, ConfigMsg configMsg) {
		openFiles(i);
		try {
			objStream.writeInt(i);
			objStream.writeObject(configMsg);
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see routeTest.consumer.Consumer#messageReceived(routeTest.serial.DataMsg)
	 */
	public void messageReceived(SerializableMessage msg) {
		if (msg instanceof DataMsg) {
			try {
				objStream.writeObject(msg);
				if (Strings.getString("MsgDmpConsumer.TEXT") == "true") {
					log.write(msg.toString());
					log.flush();
				}
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		} else {
			throw new RuntimeException("Got wrong message type: " + msg);
		}
	}

	private void openFiles(int i) {
		Date now = new Date();
		File dir = new File(Strings.getString("LOG_DIR"));
		dir.mkdir();
		SimpleDateFormat dateFormat = new SimpleDateFormat("yyyyMMddHHmmssSS");

		String binFilename = Strings.getString("LOG_DIR") + File.separator
				+ Strings.getString("MsgDmpConsumer.LOG_PREFIX") + "-" + i
				+ "-" + dateFormat.format(now)
				+ Strings.getString("MsgDmpConsumer.BIN_SUFFIX");

		String logFilename = Strings.getString("LOG_DIR") + File.separator
				+ Strings.getString("MsgDmpConsumer.LOG_PREFIX")
				+ dateFormat.format(now)
				+ Strings.getString("MsgDmpConsumer.LOG_SUFFIX");
		try {
			System.out.println("dumping binary messages in " + binFilename);
			objStream = new ObjectOutputStream(
					new FileOutputStream(binFilename));

			if (Strings.getString("MsgDmpConsumer.TEXT") != "true")
				return;

			log = new BufferedWriter(new FileWriter(logFilename, true));
			System.out.println("dumping readable messages in " + logFilename);
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

}
