 #include "opp.h"
 #include "oppDebug.h"

// #ifdef PRINTF_SUPPORT
 #ifdef PRINTF
 #include "printf.h"
 #endif

module RoutingInfoP {
  uses {
    interface Boot;
    interface Leds;
    //interface CollectionPacket;
    //interface CtpInfo;
    interface AMPacket;

#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }

  provides {
    interface RoutingInfo;
    interface OppDebug;
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

  command error_t OppDebug.logEvent(uint8_t type) {
  #ifdef PRINTF
	printf("logEvent (%u): ",type);
  #endif
    //if (type == NET_C_FE_SEND_QUEUE_FULL){
    if (type == NET_C_FE_MSG_POOL_EMPTY){
    	#ifdef PRINTF
		printf("queue full");
	#endif
      num_tx_queue_full++;    
    //} else if (type == NET_C_FE_DUPLICATE_CACHE_AT_SEND){
    } else if (type == NET_LL_DUPLICATE){
    	#ifdef PRINTF
		printf("duplicate");
	#endif
      num_dropped_duplicates++;
    } else if (type == NET_C_FE_DUPLICATE_CACHE){
    	#ifdef PRINTF
		printf("duplicate2");
	#endif
      num_dropped_duplicates++;
    } else if (type == NET_C_FE_DUPLICATE_QUEUE){
    	#ifdef PRINTF
		printf("duplicate3");
	#endif
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
    #ifdef PRINTF
	printf("\n");
	printfflush();
    #endif
    return SUCCESS;
  }
 
  command error_t OppDebug.logEventSimple(uint8_t type, uint16_t arg) {
    return SUCCESS;
  }
  
  command error_t OppDebug.logEventDbg(uint8_t type, uint16_t arg1, uint16_t arg2, uint16_t arg3) {
    return SUCCESS;
  }
  
  command error_t OppDebug.logEventMsg(uint8_t type, uint16_t msg, am_addr_t origin, am_addr_t node) {
  if (type)
    	#ifdef PRINTF
		printf("logEventMsg(%u)(%u)(%u)(%u): ",type,
				msg,origin,node);
	#endif
    if (type == NET_C_FE_SENT_MSG){

		if(origin != TOS_NODE_ID){
			num_forwarded_messages++;
	      	#ifdef PRINTF
			printf("forward message(+fwd)");
		#endif
		}
 	      	#ifdef PRINTF
		else
			printf("sent msg (+ack)");
		#endif
		num_ack_received++;
    } else if (type == NET_APP_SENT){
     	#ifdef PRINTF
		printf("data application generated");
	#endif   	
    } else if (type == NET_C_FE_FWD_MSG){
    	#ifdef PRINTF
		printf("fwd msg(+ack)");
	#endif
      num_ack_received++;
    } else if (type == NET_C_FE_SENDDONE_WAITACK){
    	#ifdef PRINTF
		printf("wait ack (+failack)");
	#endif
      num_ack_failed++;
    } else if (type == NET_C_FE_SENDDONE_FAIL_ACK_SEND){
    	#ifdef PRINTF
		printf("fail ack send");
	#endif
      num_ack_failed++;
    } else if (type == NET_C_FE_SENDDONE_FAIL_ACK_FWD){
    	#ifdef PRINTF
		printf("fail ack fwd(+ackfail)");
	#endif
      num_ack_failed++;
    } else if (type == NET_C_FE_RCV_MSG){
    	if(TOS_NODE_ID==SINK_ID){
    	/*if(TOS_NODE_ID!=0){
	      num_forwarded_messages++;
      	#ifdef PRINTF
		printf("forward message(+fwd)");
	#endif
	}else{*/
      	#ifdef PRINTF
		printf("received message from %u origin %u",node,origin);
	#endif
	}
    }else if (type == NET_LL_DUPLICATE && msg == 23){
	//num_dropped_duplicates++;
      	#ifdef PRINTF
		printf("LL DUPLICATE (+LLdrop)");
	#endif
    } else if (type == NET_C_FE_DUPLICATE_CACHE){
	num_dropped_duplicates++;
      	#ifdef PRINTF
		printf("NET DUPLICATE (+drop)");
	#endif
    }
    	#ifdef PRINTF
		printf("\n");
		printfflush();
	#endif
    //Useless signaled events
    //NET_C_FE_LOOP_DETECTED
    //NET_C_FE_RCV_MSG
    //NET_C_FE_SENDDONE_FAIL
    return SUCCESS;
  }
  
  command error_t OppDebug.logEventRoute(uint8_t type, 
                                                am_addr_t parent, 
                                                uint8_t hopcount, 
                                                uint16_t metric) {
    	#ifdef PRINTF
		printf("logEventRoute %u\n",type);
		printfflush();
	#endif
    if (type == NET_C_TREE_NEW_PARENT){
      //if (parent == INVALID_ADDR){
      //TODO CHANGE THIS!
      if (parent == TOS_NODE_ID){
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
    //err = call CtpInfo.getParent(&parent);
    err = SUCCESS;
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
    //err = call CtpInfo.getEtx(&etx);
    err = SUCCESS;
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
