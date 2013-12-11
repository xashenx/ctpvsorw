 #include <Timer.h>
 #include "PLR.h"
 #include <UserButton.h>

 #ifdef PRINTF_SUPPORT
 #include "printf.h"
 #endif

module FloodingReportP {

  provides {
    interface StatsReport;
    interface ResetFlooding;
  }

  uses {
    interface Boot;
    interface Leds;
    
    interface Alarm<TMilli,uint16_t> as TimerDequeue;
//    interface Timer<TMilli> as TimerDequeue; 

    interface AMSend as SendStats;
    interface Receive as ReceiveStats;

    interface Packet; 
    interface CC2420Packet;
    
    interface Queue<StatsMsg> as MessageQueue; 
    interface AMSend as SendUART;

    interface LowPowerListening;

    interface Random;

#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation { 

  // Comm flags
  bool radioBusy = FALSE;
  bool uartBusy = FALSE;
  bool running = FALSE;

  // Keeping track of duplicate messages
  int last_msg_stats[NR_NODES];
  int last_msg_stats_retx[NR_NODES];
 
  void enqueueStat(StatsMsg *msg) {

    /*StatsMsg* stats_msg = (StatsMsg*) 
      call Packet.getPayload(&msg,sizeof(StatsMsg));*/

    if (running) {      
      if (TOS_NODE_ID == SINK_NODE_ID) {
	// I'm the sink
	if (msg->seqn > last_msg_stats[msg->nodeid]
	    && call MessageQueue.size() < call MessageQueue.maxSize()) {

/* 	  // TESTING - simulating lost packet */
/* 	  if (call Random.rand16() % 5 == 0) { */
/* 	    return; */
/* 	  } */

	  last_msg_stats[msg->nodeid]=msg->seqn;
	  call MessageQueue.enqueue(*msg);
	}
      } else {
	if (call MessageQueue.size() < call MessageQueue.maxSize() 
	    && (msg->seqn > last_msg_stats[msg->nodeid]
		|| (msg->seqn==last_msg_stats[msg->nodeid]  
		    && last_msg_stats_retx[msg->nodeid] 
		    < msg->rx_lqi[msg->nodeid]))) {
	  
	  call Leds.led2Toggle();

/* 	  // TESTING - simulating lost packet */
/* 	  if (call Random.rand16() % 4 == 0) { */
/* 	    return; */
/* 	  } */
	  
	  last_msg_stats[msg->nodeid]=msg->seqn;
	  last_msg_stats_retx[msg->nodeid]=
	    msg->rx_lqi[msg->nodeid];
	  call MessageQueue.enqueue(*msg);
	}
      }
    }
  }
  
  event void Boot.booted() {

    int i;

    for(i=0; i<NR_NODES; i++) {
	last_msg_stats[i]=0;
	last_msg_stats_retx[i]=0;
      }

#ifdef ROUTING_NODE
    running = TRUE;
    call TimerDequeue.start(REPORT_DELAY_WINDOW);
#endif

  }

  command void StatsReport.reset() {

#ifndef ROUTING_NODE
    if (running) {
      running = FALSE;
      call TimerDequeue.stop();
    }

    while (!call MessageQueue.empty()) {
      call MessageQueue.dequeue();
    }
#endif

  }

  command void ResetFlooding.reset(){

#ifndef ROUTING_NODE
    if (running) {
      running = FALSE;
      call TimerDequeue.stop();
    }

    while (!call MessageQueue.empty()) {
      call MessageQueue.dequeue();
    }
#endif

  }

  command void StatsReport.report(StatsMsg *st_msg) {
#ifdef PRINTF_SUPPORT
    printf("E%u\n", st_msg->seqn);
    call PrintfFlush.flush();
#endif

    if (!running) {
      call Leds.led0Off();
      call Leds.led1Off();
      call Leds.led2Off();
      running = TRUE;
      if (TOS_NODE_ID == SINK_NODE_ID) {
        call TimerDequeue.start(UART_INTERVAL);
      } else {
	call TimerDequeue.start(REPORT_DELAY_WINDOW*TOS_NODE_ID);
      }
    }
    enqueueStat(st_msg);
  }

  task void sendOut () {
    message_t msg;
    StatsMsg stats, *st_msg;

    if (TOS_NODE_ID == SINK_NODE_ID) {
      call Leds.led0Toggle();
    }
        
    if (TOS_NODE_ID == SINK_NODE_ID) {
      
      if (!call MessageQueue.empty()) {
	
	stats = call MessageQueue.head();
        st_msg = (StatsMsg*)(call Packet.getPayload(&msg,sizeof(StatsMsg)));
        memcpy(st_msg, &stats, sizeof(StatsMsg));

	atomic {
	  if(!uartBusy) {
	    uartBusy = TRUE;
	    if (call SendUART.send(0xffff, 
				   &msg, 
				   sizeof(StatsMsg)) != SUCCESS) {
	      uartBusy = FALSE;
	    } 
	  }
	} 
      }
      /* 	  call TimerDequeue.startOneShot(UART_INTERVAL); */
      call TimerDequeue.start(UART_INTERVAL);     
    } else {

      if (!call MessageQueue.empty()) {

	stats = call MessageQueue.head();	
	st_msg = (StatsMsg*)(call Packet.getPayload(&msg,sizeof(StatsMsg)));
        memcpy(st_msg, &stats, sizeof(StatsMsg));
	if (!radioBusy) {
	  radioBusy = TRUE;
	  call LowPowerListening.setRemoteWakeupInterval(&msg, 0);
	  /*       call CC2420Packet.setPower(&statMsg, SIGNALLING_POWER); */
	  call Leds.led1Toggle();
	  if (call SendStats.send(AM_BROADCAST_ADDR,  
				  &msg, sizeof(StatsMsg)) != SUCCESS) {
	    radioBusy = FALSE;
	  } 
	}
      } 

#ifdef ROUTING_NODE
      call TimerDequeue.start(call Random.rand16() % REPORT_DELAY_WINDOW);
#else
      call TimerDequeue.start(REPORT_DELAY_WINDOW*NR_NODES);      
#endif
    }
  }

  async event void TimerDequeue.fired() {
    post sendOut();
  }
  
  event void SendStats.sendDone(message_t* msg_stats_tx, error_t err) {

    radioBusy = FALSE;
    if (err == SUCCESS) { 
      call MessageQueue.dequeue();
    }

#ifdef ROUTING_NODE
    call TimerDequeue.start(call Random.rand16() % REPORT_DELAY_WINDOW);
#else
    call TimerDequeue.start(REPORT_DELAY_WINDOW*NR_NODES);      
#endif
  }

  event void SendUART.sendDone(message_t* msg, error_t err) {
    
    uartBusy = FALSE;
    if (err == SUCCESS) { 
      call MessageQueue.dequeue();
    }

    call TimerDequeue.start(UART_INTERVAL);
  }

  message_t forwardStats;
  event message_t* ReceiveStats.receive(message_t* msg_stats_rx, void* payload, 
					uint8_t len){

    StatsMsg* forward_stats_msg;
    StatsMsg* stats_msg = (StatsMsg*)payload;
    stats_msg->rx_rssi[stats_msg->nodeid] = 
      stats_msg->rx_rssi[stats_msg->nodeid]+1; 

  
/*     call Leds.led2Toggle(); */
    
    if(TOS_NODE_ID == SINK_NODE_ID) { 
      enqueueStat((StatsMsg *)payload);
    } else 

#ifndef ROUTING_NODE
      if(stats_msg->nodeid > TOS_NODE_ID) 
#endif
	{
	  forward_stats_msg = (StatsMsg*)
	    call Packet.getPayload(&forwardStats,sizeof(StatsMsg));
	  memcpy(forward_stats_msg, stats_msg, sizeof(StatsMsg));
	  enqueueStat(stats_msg);
	}
    
    return msg_stats_rx;
  }

#ifdef PRINTF_SUPPORT
  event void PrintfControl.startDone(error_t error) {
  }

  event void PrintfControl.stopDone(error_t error) {
  }

  event void PrintfFlush.flushDone(error_t error) {
  }
#endif
}

