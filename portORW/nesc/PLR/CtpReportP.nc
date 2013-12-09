 #include <Timer.h>
 #include "PLR.h"
 #include <UserButton.h>

 #ifdef PRINTF_SUPPORT
 #include "printf.h"
 #endif

module CtpReportP {

  provides {
    interface StatsReport;
    interface ResetFlooding;
  }

  uses {
    interface Boot;
    interface Leds;

    interface StdControl as RoutingControl;
    //interface RootControl;

    interface Queue<StatsMsg> as MessageQueue;
    interface Alarm<TMilli,uint16_t> as TimerDequeue;
    
    interface AMSend as SendStats;
    interface Receive as ReceiveStats;

    interface Packet; 
    interface CC2420Packet;
    
    interface AMSend as SendUART;
    interface Packet as SerialPacket;

    interface LowPowerListening;

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
  bool first = FALSE;
  uint16_t ticks;
  uint16_t tot_ticks;

  void enqueueStat(StatsMsg *msg) {

    if (running) {      
      if (TOS_NODE_ID == SINK_NODE_ID) {
        // I'm the sink
        if (call MessageQueue.size() < call MessageQueue.maxSize()) {
          
          /* 	  // TESTING - simulating lost packet */
          /* 	  if (call Random.rand16() % 5 == 0) { */
          /* 	    return; */
          /* 	  } */
          
          call MessageQueue.enqueue(*msg);
        }
      } else {
        if (call MessageQueue.size() < call MessageQueue.maxSize()) {
          
          call Leds.led2Toggle();

          /* call Leds.led2Toggle(); */
          
          /* 	  // TESTING - simulating lost packet */
          /* 	  if (call Random.rand16() % 4 == 0) { */
          /* 	    return; */
          /* 	  } */
          
          call MessageQueue.enqueue(*msg);
        }
      }
    }
  }
  
  event void Boot.booted() {

  }

  command void StatsReport.reset() {

    if (running) {
      running = FALSE;
      call RoutingControl.stop();
      call TimerDequeue.stop();
    }

    while (!call MessageQueue.empty()) {
      call MessageQueue.dequeue();
    }

  }

  command void ResetFlooding.reset(){

    if (running) {
      running = FALSE;
      call RoutingControl.stop();
      call TimerDequeue.stop();
    }

    while (!call MessageQueue.empty()) {
      call MessageQueue.dequeue();
    }
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
        call RoutingControl.start();
        //call RootControl.setRoot();
        call TimerDequeue.start(UART_INTERVAL);
      } else {
        call RoutingControl.start();
        ticks = 1;
        first = TRUE;
        call TimerDequeue.start((uint32_t) (CTP_BOOTSTRAP +
                                            REPORT_DELAY_WINDOW));
      }
    }
    enqueueStat(st_msg);
  }

  task void sendOut () {
    message_t msg;
    StatsMsg stats, *st_msg;
    error_t err;

    if (TOS_NODE_ID == SINK_NODE_ID) {
      call Leds.led0Toggle();
    }    

    if (TOS_NODE_ID == SINK_NODE_ID) {
      
      if (!call MessageQueue.empty()) {
        stats = call MessageQueue.head();
        
        //st_msg = (StatsMsg*)(call SerialPacket.getPayload(&msg, NULL));
        st_msg = (StatsMsg*)(call SerialPacket.getPayload(&msg, sizeof(StatsMsg)));
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
      if (first && ticks < TOS_NODE_ID){
        ticks++;
        call TimerDequeue.start(REPORT_DELAY_WINDOW);
        return;
      } else if (!first && ticks < NR_NODES){
        ticks++;
        call TimerDequeue.start(REPORT_DELAY_WINDOW);
        return;
      }
        
      if (!call MessageQueue.empty()) {
        stats = call MessageQueue.head();

        //st_msg = (StatsMsg*)(call Packet.getPayload(&msg, NULL));
        st_msg = (StatsMsg*)(call Packet.getPayload(&msg,sizeof(StatsMsg)));
        memcpy(st_msg, &stats, sizeof(StatsMsg));

#ifdef PRINTF_SUPPORT
        printf("D%u\n", ((StatsMsg*)(call Packet.getPayload(&msg,
                                                        NULL)))->seqn);
        call PrintfFlush.flush();
#endif

        if (!radioBusy) {
          radioBusy = TRUE;
          call LowPowerListening.setRemoteWakeupInterval(&msg, 0);
          /*       call CC2420Packet.setPower(&statMsg, SIGNALLING_POWER); */
          if ((err = call SendStats.send(AM_BROADCAST_ADDR,&msg, sizeof(StatsMsg))) != SUCCESS) {
            radioBusy = FALSE;
          } 
        }
      } 
      first = FALSE;
      ticks = 1;
      call TimerDequeue.start(REPORT_DELAY_WINDOW);      
    }
  }

  async event void TimerDequeue.fired() {
    post sendOut();
  }
  
  event void SendStats.sendDone(message_t* msg_stats_tx, error_t err) {

    radioBusy = FALSE;
    if (err == SUCCESS) {
      call MessageQueue.dequeue();
      call Leds.led2Toggle();
    }

    call TimerDequeue.start(REPORT_DELAY_WINDOW);      
  }

  event void SendUART.sendDone(message_t* msg, error_t err) {
    
    uartBusy = FALSE;
    if (err == SUCCESS) { 
      call MessageQueue.dequeue();
      call Leds.led1Toggle();
    }

    call TimerDequeue.start(UART_INTERVAL);
  }

  event message_t* ReceiveStats.receive(message_t* msg_stats_rx, void* payload, 
					uint8_t len){
    
    if(TOS_NODE_ID == SINK_NODE_ID) { 
      enqueueStat((StatsMsg *)payload);
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

