 #include "Ctp.h"

 #ifdef PRINTF_SUPPORT
 #include "printf.h"
 #endif

module RoutingInfoP {
  uses {
    interface Boot;
    interface Leds;
    interface CollectionPacket;
    interface CtpInfo;
    interface AMPacket;

#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }

  provides {
    interface RoutingInfo;
    interface CollectionDebug;
  }
}

implementation {
  
  uint16_t current_parent;
  uint16_t current_parent_etx;
  uint16_t num_ack_received;
  uint16_t num_ack_failed;
  uint16_t num_beacon_sent;
  uint16_t num_tx_queue_full;
  uint16_t num_dropped_duplicates;
  uint16_t num_forwarded_messages;

  event void Boot.booted() {
    current_parent = TOS_NODE_ID;
    current_parent_etx = 0xFFFF;
    num_ack_received = 0;
    num_ack_failed = 0;
    num_beacon_sent = 0;
    num_tx_queue_full = 0;
    num_dropped_duplicates = 0;
    num_forwarded_messages = 0;
#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

  command error_t CollectionDebug.logEvent(uint8_t type) {
    if (type == NET_C_FE_SEND_QUEUE_FULL){
      num_tx_queue_full++;    
    } else if (type == NET_C_FE_DUPLICATE_CACHE_AT_SEND){
      num_dropped_duplicates++;
    } else if (type == NET_C_FE_DUPLICATE_CACHE){
      num_dropped_duplicates++;
    } else if (type == NET_C_FE_DUPLICATE_QUEUE){
      num_dropped_duplicates++;
    }
    //Useless signaled events
    //NET_C_FE_MSG_POOL_EMPTY
    //NET_C_FE_QENTRY_POOL_EMPTY
    //NET_C_FE_GET_MSGPOOL_ERR
    //NET_C_FE_GET_QEPOOL_ERR
    //NET_C_FE_PUT_MSGPOOL_ERR
    //NET_C_FE_PUT_QEPOOL_ERR
    //NET_C_FE_NO_ROUTE
    //NET_C_FE_CONGESTION_BEGIN
    //NET_C_FE_CONGESTION_END
    //NET_C_FE_SEND_BUSY
    //NET_C_FE_SENDQUEUE_EMPTY
    //NET_C_FE_BAD_SENDDONE
    //NET_C_FE_SUBSEND_OFF
    //NET_C_FE_SUBSEND_BUSY
    //NET_C_FE_SUBSEND_SIZE
    return SUCCESS;
  }
 
  command error_t CollectionDebug.logEventSimple(uint8_t type, uint16_t arg) {
    return SUCCESS;
  }
  
  command error_t CollectionDebug.logEventDbg(uint8_t type, uint16_t arg1, uint16_t arg2, uint16_t arg3) {
    return SUCCESS;
  }
  
  command error_t CollectionDebug.logEventMsg(uint8_t type, uint16_t msg, am_addr_t origin, am_addr_t node) {
    if (type == NET_C_FE_SENT_MSG){
      num_ack_received++;
    } else if (type == NET_C_FE_FWD_MSG){
      num_ack_received++;
    } else if (type == NET_C_FE_SENDDONE_WAITACK){
      num_ack_failed++;
    } else if (type == NET_C_FE_SENDDONE_FAIL_ACK_SEND){
      num_ack_failed++;
    } else if (type == NET_C_FE_SENDDONE_FAIL_ACK_FWD){
      num_ack_failed++;
    } else if (type == NET_C_FE_RCV_MSG && !(TOS_NODE_ID == 0)){
      num_forwarded_messages++;
    }
    //Useless signaled events
    //NET_C_FE_LOOP_DETECTED
    //NET_C_FE_RCV_MSG
    //NET_C_FE_SENDDONE_FAIL
    return SUCCESS;
  }
  
  command error_t CollectionDebug.logEventRoute(uint8_t type, 
                                                am_addr_t parent, 
                                                uint8_t hopcount, 
                                                uint16_t metric) {
    if (type == NET_C_TREE_NEW_PARENT){
      if (parent == INVALID_ADDR){
        current_parent = TOS_NODE_ID;
        current_parent_etx = 0;
        signal RoutingInfo.parentLost();
      }
      if (parent != current_parent){
        current_parent = parent;
        current_parent_etx = metric;
        signal RoutingInfo.parentChanged();
      }

    } else if (type == NET_C_TREE_SENT_BEACON){
      num_beacon_sent++;
    }

    return SUCCESS;
  }

  command void RoutingInfo.clearStats(){
    current_parent = TOS_NODE_ID;
    current_parent_etx = 0xFFFF;
    num_ack_received = 0;
    num_ack_failed = 0;
    num_beacon_sent = 0;
    num_tx_queue_full = 0;
    num_dropped_duplicates = 0;
    num_forwarded_messages = 0;
  }
  
  command uint16_t RoutingInfo.getParent(){
    uint16_t parent;
    error_t err;
    err = call CtpInfo.getParent(&parent);
    current_parent = parent;
    if (err == FAIL){
      current_parent = TOS_NODE_ID;
      current_parent_etx = 0;
    }
    return current_parent;
  }

  command uint16_t RoutingInfo.getParentEtx(){
    uint16_t etx;
    error_t err;
    err = call CtpInfo.getEtx(&etx);
    current_parent_etx = 0;
    if (err == SUCCESS){
      current_parent_etx = etx;
    }
    return current_parent_etx;
  }

  command uint16_t RoutingInfo.getNumAckReceived(){
    return num_ack_received;
  }

  command uint16_t RoutingInfo.getNumAckFailed(){
    return num_ack_failed;
  }

  command uint16_t RoutingInfo.getNumBeaconSent(){
    return num_beacon_sent;
  }

  command uint16_t RoutingInfo.getNumQueueFull(){
    return num_tx_queue_full;
  }

  command uint16_t RoutingInfo.getNumDroppedDuplicates(){
    return num_dropped_duplicates;
  }

  command uint16_t RoutingInfo.getNumForwardedMessages(){
    return num_forwarded_messages;
  }
  
#ifdef PRINTF_SUPPORT
  event void PrintfControl.startDone(error_t error) {}

  event void PrintfControl.stopDone(error_t error) {}

  event void PrintfFlush.flushDone(error_t error) {}
#endif

}
