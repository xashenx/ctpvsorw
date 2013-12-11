/**
 * 
 */
package netTest.consumer;

import netTest.serial.SerializableMessage;

/**
 * A consumer that prints received messages to stdout.
 * 
 * @author Stefan Guna
 * 
 */
public class PrintConsumer implements Consumer {

	/*
	 * (non-Javadoc)
	 * 
	 * @see routeTest.consumer.Consumer#messageReceived(routeTest.serial.DataMsg)
	 */
	public void messageReceived(SerializableMessage msg) {

		System.out.println(msg.toString());
	}
}
