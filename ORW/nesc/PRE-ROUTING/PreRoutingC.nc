 #include <Timer.h>
 #include "PreRouting.h"
 #include <UserButton.h>

 #ifdef PRINTF_SUPPORT
 #include "printf.h"
 #endif

 #define MIN_DELTA 3000

module PreRoutingC {

  provides interface Experiment;

  uses {
    	interface Boot;
    	interface Leds;
    
    //interface Timer<TMilli> as TimerExperiment;

    //interface ResultsStore;
	interface LowPowerListening;
    	interface Read<uint16_t> as ReadTemp; 
    	interface Read<uint16_t> as ReadHumidity; 
   	interface Read<uint16_t> as ReadVoltage;
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
    //call ResultsStore.clear();
  }

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
    }
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

    seqn = 0;
    
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
  }

}

