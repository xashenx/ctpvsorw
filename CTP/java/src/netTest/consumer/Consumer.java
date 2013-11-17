/**
 * 
 */
package netTest.consumer;

import netTest.serial.SerializableMessage;

/**
 * The interface of objects that consume received messages.
 * 
 * @author Stefan Guna
 * 
 */
public interface Consumer {
	/**
	 * New message received notification.
	 * 
	 * @param msg
	 *            The received message.
	 */
	public void messageReceived(SerializableMessage msg);
}
