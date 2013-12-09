/**
 * 
 */
package netTest.serial;

import java.io.Externalizable;
import java.io.IOException;
import java.io.ObjectInput;
import java.io.ObjectOutput;

import net.tinyos.message.Message;

/**
 * @author Stefan Guna
 * 
 */
public class SerializableMessage extends Message implements Externalizable {

	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;

	/**
	 * 
	 */
	public SerializableMessage() {
		// TODO Auto-generated constructor stub
	}

	/**
	 * @param arg0
	 */
	public SerializableMessage(byte[] arg0) {
		super(arg0);
		// TODO Auto-generated constructor stub
	}

	/**
	 * @param arg0
	 * @param arg1
	 */
	public SerializableMessage(byte[] arg0, int arg1) {
		super(arg0, arg1);
		// TODO Auto-generated constructor stub
	}

	/**
	 * @param arg0
	 * @param arg1
	 * @param arg2
	 */
	public SerializableMessage(byte[] arg0, int arg1, int arg2) {
		super(arg0, arg1, arg2);
		// TODO Auto-generated constructor stub
	}

	/**
	 * @param arg0
	 */
	public SerializableMessage(int arg0) {
		super(arg0);
		// TODO Auto-generated constructor stub
	}

	/**
	 * @param arg0
	 * @param arg1
	 */
	public SerializableMessage(int arg0, int arg1) {
		super(arg0, arg1);
		// TODO Auto-generated constructor stub
	}

	/**
	 * @param arg0
	 * @param arg1
	 * @param arg2
	 */
	public SerializableMessage(Message arg0, int arg1, int arg2) {
		super(arg0, arg1, arg2);
		// TODO Auto-generated constructor stub
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see java.io.Externalizable#readExternal(java.io.ObjectInput)
	 */
	public void readExternal(ObjectInput in) throws IOException,
			ClassNotFoundException {
		int base_offset, data_length, data_size;
		super.am_type = in.readInt();
		base_offset = in.readInt();
		data_length = in.readInt();
		data_size = in.readInt();
		byte data[] = new byte[data_size];
		in.readFully(data);
		super.init(data, base_offset, data_length);
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see java.io.Externalizable#writeExternal(java.io.ObjectOutput)
	 */
	public void writeExternal(ObjectOutput out) throws IOException {
		out.writeInt(super.am_type);
		out.writeInt(super.base_offset);
		out.writeInt(super.data_length);
		out.writeInt(super.dataGet().length);
		out.write(super.dataGet());
	}

}
