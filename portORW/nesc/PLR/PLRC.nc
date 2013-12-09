 #include <Timer.h>
 #include "PLR.h"
 #include <UserButton.h>

 #ifdef PRINTF_SUPPORT
 #include "printf.h"
 #endif

 #define MIN_DELTA 3000

module PLRC {

  provides interface Experiment;

  uses {
    interface Boot;
    interface Leds;
    
    interface Timer<TMilli> as TimerExperiment;
    interface Timer<TMilli> as TimerStats;
    interface AMSend;
    interface Receive;

    interface Packet; 
    interface CC2420Packet;
    /*     interface CC2420Config; */
            
    interface StatsReport;
    interface ResultsStore;

    interface LowPowerListening;

    interface Read<uint16_t> as ReadTemp; 
    interface Read<uint16_t> as ReadHumidity; 
    interface Read<uint16_t> as ReadVoltage;
    
#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {
 
  // Comm flags
  bool radioBusy = FALSE;

  // Experiment parameters
  uint16_t experimentId = 0;
  uint16_t experimentSender;
  uint16_t nr_packets;
  uint16_t packet_seqn;
  uint16_t time_interval;
  /*   uint8_t experimentChannel; */
  /*   uint8_t transmissionPower; */

  // Retries
  uint8_t stat_retx;  
  uint16_t seqn;

  // Average temperature during the experiment
  uint32_t avgTemperature;
  // Average humidity during the experiment
  uint32_t avgHumidity;

  // Battery voltage at the beginning and at the end of the experiment
  uint16_t initBattery,endBattery;

  event void Boot.booted() {
    call ResultsStore.clear();
  }

  event void TimerStats.fired() {

    uint8_t i;
    StatsMsg bt_msg;
    
    bt_msg.experimentId = experimentId;
    bt_msg.seqn = seqn;
    bt_msg.expSender = experimentSender;
    bt_msg.nodeid = TOS_NODE_ID;
    
    for (i = 0; i < RX_SIZE; i++) {
      if(seqn * RX_SIZE + i == TOS_NODE_ID) {
        bt_msg.rx_packets[i] = 0;
        // This is a hack: reusing a slot for hop count
        bt_msg.rx_rssi[i] = 0;
        // This is a hack: reusing a slot for stat_retx
        bt_msg.rx_lqi[i] = stat_retx;
      } else {
        if(call ResultsStore.getStats(seqn * RX_SIZE + i) > 0 &&
           (seqn * RX_SIZE + i) < NR_NODES) {
          // Filling message
          bt_msg.rx_packets[i] =
            call ResultsStore.getStats(seqn * RX_SIZE + i);
          bt_msg.rx_rssi[i] =
            (call ResultsStore.getRssi(seqn * RX_SIZE + i)/
             call ResultsStore.getStats(seqn * RX_SIZE + i));
          bt_msg.rx_lqi[i] =
            (call ResultsStore.getLqi(seqn * RX_SIZE + i)/
             call ResultsStore.getStats(seqn * RX_SIZE + i));
        } else {
          bt_msg.rx_packets[i] = 0;
          bt_msg.rx_rssi[i] = 0;
          bt_msg.rx_lqi[i] = 0;
        }
      }
      bt_msg.avgTemperature = (uint16_t) avgTemperature;
      bt_msg.avgHumidity = (uint16_t) avgHumidity;
      bt_msg.initBattery = initBattery;
      bt_msg.endBattery = endBattery;
    }

#ifdef PRINTF_SUPPORT
    printf("S%u\n", bt_msg.seqn);
#endif
    call StatsReport.report(&bt_msg);
    
    seqn++;
    if (seqn * RX_SIZE < NR_NODES){
      call TimerStats.startOneShot(REPORT_RETRY_INTERVAL);
    } else if(stat_retx < MAX_STATS_RETX) {
      seqn = 0;
      stat_retx++;
      call TimerStats.startOneShot(REPORT_RETRY_INTERVAL);
    }
  }

  /*   bool radioChannelChange = FALSE; */
  event void TimerExperiment.fired() {

    message_t pkt;
    /*     static uint8_t signallingChannel; */

    /*     if (!radioChannelChange) { */
    /*       radioChannelChange = TRUE; */
    /*       signallingChannel = call CC2420Config.getChannel(); */
    /*       call CC2420Config.setChannel(experimentChannel); */
    /*       call Leds.led2On(); */
    /*       call CC2420Config.sync(); */

    /*     } else  */if(packet_seqn<nr_packets) {

      if(!radioBusy) {
        PLRMsg* btrpkt =  (PLRMsg*)(call Packet.getPayload(&pkt, sizeof(PLRMsg)));
        //PLRMsg* btrpkt =  (PLRMsg*)(call Packet.getPayload(&pkt, NULL));
        btrpkt->nodeid = TOS_NODE_ID;
        btrpkt->seqn = experimentId;
        btrpkt->packet_seqn = packet_seqn++; 
	
        radioBusy = TRUE;
        /* 	call CC2420Packet.setPower(&pkt, transmissionPower); */
        call LowPowerListening.setRemoteWakeupInterval(&pkt, 0);
        if (call AMSend.send(AM_BROADCAST_ADDR, 
                             &pkt, sizeof(PLRMsg)) != SUCCESS) {
          radioBusy = FALSE;
        }

        // Gathering temperature and humidity
        call ReadTemp.read();

      } else {
#ifdef PRINTF_SUPPORT
        printf ("rb%d\n",time_interval);
        call PrintfFlush.flush();
#endif
        call TimerExperiment.startOneShot(time_interval);
      }  
    } else {

      call ReadVoltage.read();    

      /*       // Experiment ends: resetting signalling channel */
      /*       radioChannelChange = FALSE; */
      /*       call CC2420Config.setChannel(signallingChannel); */
      /*       call CC2420Config.sync(); */
    }

  }

  /*   event void CC2420Config.syncDone(error_t error) { */
  /*     if (radioChannelChange) { */
  /*       // Send first experiment message */
  /*       call Leds.led2Off(); */
  /* #ifdef PRINTF_SUPPORT */
  /*       printf ("sd%d\n",time_interval); */
  /* 	call PrintfFlush.flush(); */
  /* #endif */
  /*       call TimerExperiment.startOneShot(time_interval); */
  /*     } else { */
  /*       // Final battery reading */
  /*       call ReadVoltage.read();     */
  /*     } */
  /*   } */

  event void ReadTemp.readDone(error_t result, uint16_t val) {      
    avgTemperature = (avgTemperature*(packet_seqn-1) + val)/packet_seqn;
    call ReadHumidity.read();
  }

  event void ReadHumidity.readDone(error_t result, uint16_t val) {
    avgHumidity = (avgHumidity*(packet_seqn-1) + val)/packet_seqn;
  }

  event void ReadVoltage.readDone(error_t result, uint16_t val) {

    uint16_t realignDelta;

    if (initBattery == 0) {
      initBattery = val;
    } else {
      realignDelta = (((uint16_t)time_interval/NR_NODES)
                      *(NR_NODES-TOS_NODE_ID));
      endBattery = val;

#ifdef PRINTF_SUPPORT
      printf ("red%d\n",realignDelta);
      call PrintfFlush.flush();
#endif
      
      // Sends out stats
    
      // Reset flooding to report data
      call StatsReport.reset();
      call TimerStats.startOneShot(realignDelta+MIN_DELTA); 
    }
  }
  
  event void AMSend.sendDone(message_t* msg_plr_tx, error_t err) {

    radioBusy = FALSE;    
    call Leds.led1Toggle();
#ifdef PRINTF_SUPPORT
    printf ("asd%d\n",time_interval);
    call PrintfFlush.flush();
#endif
    call TimerExperiment.startOneShot(time_interval);
  }

  // Received experiment message
  event message_t* Receive.receive(message_t* msg_plr, 
                                   void* payload, uint8_t len){

    PLRMsg* btrpkt = (PLRMsg*)payload;
    uint8_t rssi_tmp=0;
    int int_rssi_tmp=0;
      
    atomic {

      // This packet belongs to the current experiment
      if(experimentId==btrpkt->seqn) {
	
        call Leds.led0Toggle();
        
        call ResultsStore.incrStats(btrpkt->nodeid, 1);
	
        call ResultsStore.incrLqi(btrpkt->nodeid, (uint16_t) call CC2420Packet.getLqi(msg_plr));
 
        // Convert to dBm
        rssi_tmp=call CC2420Packet.getRssi(msg_plr);
        if (rssi_tmp > 127) {
          int_rssi_tmp = rssi_tmp - 256;
        }
        int_rssi_tmp= rssi_tmp -45;
        rssi_tmp=-int_rssi_tmp;

        call ResultsStore.incrRssi(btrpkt->nodeid, (uint16_t) rssi_tmp);
      }
    }
    return msg_plr;
  }

  command void Experiment.start(uint16_t expId,
                                uint16_t numberPackets, 
                                uint16_t interval, 
                                uint8_t channel,
                                uint16_t sender,
                                uint16_t lplCheckInterval) {

    uint16_t deltaInit;

    call Leds.set(0);
    call Leds.led0On();

    // Stops any reporting if still going on...
    call StatsReport.reset();

    seqn = 0;
    // Reinit stats
    stat_retx=1;
    call ResultsStore.clear();
    
    // Experiment parameters
    experimentId = expId; 
    experimentSender = sender;
    /*     transmissionPower = power; */
    nr_packets = numberPackets;
    time_interval = interval;	  
    /*     experimentChannel = channel; */
     
    // Reset counter and environmental measures
    packet_seqn=0;
    avgTemperature = 0;
    avgHumidity = 0;
     
    // Initial battery reading
    initBattery = 0;
    call ReadVoltage.read();

    deltaInit = ((((uint16_t)time_interval/NR_NODES)
                  *TOS_NODE_ID) + MIN_DELTA); // Node 0 can't start after 0
 
#ifdef PRINTF_SUPPORT
    printf ("gTi%dTi%dI%d\n",interval, time_interval, deltaInit);
    call PrintfFlush.flush();
#endif

    // Computes time before starting experiment
    call TimerExperiment.startOneShot(deltaInit);
    
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

