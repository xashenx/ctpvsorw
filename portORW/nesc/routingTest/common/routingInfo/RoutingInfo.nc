interface RoutingInfo {
  
  /* Clears the recorded statistics */
  command void clearStats();

  /* Gets the current parent in the collecting tree */
  command uint16_t getParent();

  /* Gets the cost of the path to the root of the tree */
  command uint16_t getParentEtx();

  /* Signals a change of the parent */
  event void parentChanged();

  /* Signals the lost of the parent */
  event void parentLost();

  /* Gets the number of ack messages received */
  command uint16_t getNumAckReceived();

  /* Gets the number of ack receptions failed */
  command uint16_t getNumAckFailed();

  /* Gets the number of beacons sent */
  command uint16_t getNumBeaconSent();

  /* Gets the number of queue overflows */
  command uint16_t getNumQueueFull();

  /* Gets the number of dropped duplicated messages */
  command uint16_t getNumDroppedDuplicates();

  /* Gets the number of message that the node should forward */
  command uint16_t getNumForwardedMessages();
}
