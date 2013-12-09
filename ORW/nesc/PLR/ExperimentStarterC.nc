 #include <Timer.h>
 #include "PLR.h"
 #include <UserButton.h>

 #ifdef PRINTF_SUPPORT
 #include "printf.h"
 #endif

module ExperimentStarterC {

  uses {
    interface Boot;
    interface Leds;
    
    interface AMSend as SendStart;
    interface Receive as ReceiveStart;

    interface Packet; 
    interface CC2420Packet;
    
    interface Receive as ReceiveUART;

    interface Experiment as ExperimentPLR;
    interface Experiment as ExperimentMAC_PLR;
    
    interface SplitControl as AMControl;
    interface SplitControl as SerialAMControl;

    interface LowPowerListening;
    interface Random;

#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

#ifdef ROUTING_NODE
#warning "ATTENTION: You re building a bridge node!"
#endif

implementation {
 
  // Comm flags
  bool radioBusy = FALSE;

  // Keeping track of duplicate messages
  int lastmsgstart = 0;

  event void Boot.booted() {
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      call LowPowerListening.setLocalWakeupInterval(0);
      if (TOS_NODE_ID == SINK_NODE_ID) {
	call SerialAMControl.start();
      }
    } else {
      call AMControl.start();
    }
  }

  event void SerialAMControl.startDone(error_t err) {
    if (err != SUCCESS) {
      call SerialAMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
  }

  event void SerialAMControl.stopDone(error_t err) {
  }

  event void SendStart.sendDone(message_t* msg, error_t err) {
    radioBusy = FALSE;
  }

  // Starts up a new experiment
  message_t startMsgForward;
  void startExperiment(StartMsg* btrpkt) {

    StartMsg* btrpktForward = (StartMsg*) 
      call Packet.getPayload(&startMsgForward, sizeof(StartMsg));
      //call Packet.getPayload(&startMsgForward, NULL);

    // It's a new start message
    if(lastmsgstart < btrpkt->seqn) {
      
      lastmsgstart = btrpkt->seqn;

      // Starts the experiment according to the required params
#ifndef ROUTING_NODE
      if (btrpkt->type == PURE_PLR) {
	call ExperimentPLR.start(btrpkt->seqn,
				 btrpkt->nPackets,
				 btrpkt->interval,
				 btrpkt->channel,
				 btrpkt->expSender,
				 0);
      } else if (btrpkt->type == MAC_PLR) {
	call ExperimentMAC_PLR.start(btrpkt->seqn,
				     btrpkt->nPackets,
				     btrpkt->interval,
				     btrpkt->channel,
				     btrpkt->expSender,
				     0);
      } else if (btrpkt->type == LPL_PLR) {
	call ExperimentMAC_PLR.start(btrpkt->seqn,
				     btrpkt->nPackets,
				     btrpkt->interval,
				     btrpkt->channel,
				     btrpkt->expSender,
				     btrpkt->lplCheckInterval);
      }
#endif
      
      // Repropagates
      memcpy(btrpktForward, btrpkt, sizeof(StartMsg));
      btrpktForward->expSender = TOS_NODE_ID;
      call LowPowerListening.setRemoteWakeupInterval(&startMsgForward, 0);
      radioBusy = TRUE;
	  
/*       call CC2420Packet.setPower(&startMsgForward, SIGNALLING_POWER); */
      if(call SendStart.send(AM_BROADCAST_ADDR, 
			     &startMsgForward, sizeof(StartMsg)) != SUCCESS) {
	radioBusy = FALSE;
      }
    }
  }

  // Received start message form UART 
  event message_t* ReceiveUART.receive(message_t* msg_uart_rx, 
				       void* payload, uint8_t len){
    StartMsg* startUart = (StartMsg*) payload;
    startUart->expSender = TOS_NODE_ID;
    startExperiment(startUart);
    return msg_uart_rx;
  }

  // Received start message from radio: start experiment 
  // and repropagate over radio   
  event message_t* ReceiveStart.receive(message_t* msg_start_rx, 
					void* payload, uint8_t len){
    startExperiment((StartMsg*)payload);
    return msg_start_rx;
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
