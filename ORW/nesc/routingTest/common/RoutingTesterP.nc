 #include <Timer.h>
 #include "route_msg.h"

 //#ifdef PRINTF_SUPPORT
 #ifdef PRINTF
 #include "printf.h"
 #endif

module RoutingTesterP {
  uses {
    interface Boot;
    interface SplitControl as RadioControl;
    //TODO IMPLEMENT THE STOP OF THE ROUTING
    interface StdControl as RoutingControl;
    //interface RootControl;
    interface Leds;
    interface Send;
    //interface AMPacket;
    interface Packet;
    interface Read<uint16_t> as ReadVoltage;
    interface Read<uint16_t> as ReadTemp;
    interface Read<uint16_t> as ReadHumidity;
    interface Timer<TMilli> as Period;
    interface RoutingInfo;
    interface OppClear;
    interface OppRadioSettings;
    interface Random;
    //interface DutyCycle;

#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }

  provides {
    interface RoutingTester;
  }
}

implementation {

  uint16_t period;
  uint16_t operatingPeriods;
  uint16_t currentTemp;
  uint16_t currentHum;
  uint16_t currentBat;
  uint16_t numParentsSeen;
  parent_t parents[MAX_PARENTS];
  uint8_t current_parent_index;
  uint32_t last_time_recorded;
  uint16_t dcIdle;
  uint16_t dcData;
  uint16_t currentTick;
  uint16_t sinkAcks;

  message_t packet;
  uint16_t msgSeqNum;

  event void Boot.booted() {
    uint8_t i;
    call RoutingControl.stop();
    period = 0;
    operatingPeriods = 0;
    msgSeqNum = 0;
    current_parent_index = 0;
    currentTick = 0;
    numParentsSeen = 0;
    sinkAcks = 0;
    for (i = 0; i < MAX_PARENTS; i++){
      parents[i].addr = TOS_NODE_ID;
      parents[i].etx = 0;
      parents[i].periods = 0;
      parents[i].subunits = 0;
    }
    call RadioControl.start();
#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

  event void RadioControl.startDone(error_t err) {
    if (err != SUCCESS) {
      call RadioControl.start();
    }
  }

  event void RadioControl.stopDone(error_t err) {
    if (err != SUCCESS) {
      call RadioControl.stop();
    }
  }

  void sendMsg(){
    uint8_t i;
    uint16_t parent_id;
    data_msg_t* msg = (data_msg_t*) call Send.getPayload(&packet,sizeof(data_msg_t));
/*    msg->temperature = currentTemp;
    msg->humidity = currentHum;
    msg->voltage = currentBat;*/
    // TODO GET IT FROM OPP
/*    msg->routing_data.node_addr = call AMPacket.address();
    msg->routing_data.node_addr = call Packet.address();
    msg->routing_data.seq_no = msgSeqNum++;*/
    if(TOS_NODE_ID != SINK_ID)
	    msg->routing_data.ack_received = 
      		call RoutingInfo.getNumAckReceived();
    else
	    msg->routing_data.ack_received = sinkAcks; 
    msg->routing_data.beacons = 
      call RoutingInfo.getNumBeaconSent();
    msg->routing_data.ack_failed = 
      call RoutingInfo.getNumAckFailed();
    msg->routing_data.tx_queue_full = 
      call RoutingInfo.getNumQueueFull();
    msg->routing_data.dropped_duplicates = 
      call RoutingInfo.getNumDroppedDuplicates();
    msg->routing_data.forwarded =
      call RoutingInfo.getNumForwardedMessages();
    /*msg->routing_data.dcIdle =
      call DutyCycle.getTimeIdle();
    msg->routing_data.dcData =
      call DutyCycle.getTimeData();*/
    msg->temperature = currentTemp;
    msg->humidity = currentHum;
    msg->voltage = currentBat;
    // TODO GET IT FROM OPP
    msg->routing_data.node_addr = TOS_NODE_ID;
    msg->routing_data.seq_no = msgSeqNum++;
    /*msg->routing_data.ack_received = 
      currentTick;
    msg->routing_data.beacons = 
      7;
    msg->routing_data.ack_failed = 
      8;
    msg->routing_data.tx_queue_full = 
      9;
    msg->routing_data.dropped_duplicates = 
      10;
    msg->routing_data.forwarded =
      11;*/
    msg->routing_data.dcIdle =
      12;
    msg->routing_data.dcData =
      13;
    msg->routing_data.parents_seen = 14;

    msg->routing_data.parents_no = current_parent_index + 1;
    
    parents[current_parent_index].subunits += call Period.getNow() - 
      last_time_recorded;
    last_time_recorded = call Period.getNow();

    if (parents[current_parent_index].subunits >= period){
      parents[current_parent_index].periods += 1;
      parents[current_parent_index].subunits -= period;
    }
    for (i = 0; i < MAX_PARENTS; i++){
      msg->routing_data.parents[i].addr = parents[i].addr;
      msg->routing_data.parents[i].etx = parents[i].etx;
      msg->routing_data.parents[i].periods = parents[i].periods;
      msg->routing_data.parents[i].subunits = parents[i].subunits;
    }

    parent_id = parents[current_parent_index].addr;

    parents[0].addr = call RoutingInfo.getParent();
    parents[0].etx = call RoutingInfo.getParentEtx();

    if (parent_id == parents[0].addr){
      parents[0].periods = parents[current_parent_index].periods;
      parents[0].subunits = parents[current_parent_index].subunits;
    } else {
      numParentsSeen++;
      parents[0].periods = 0;
      parents[0].subunits = 0;
    }

    current_parent_index = 0;

    for (i=1 ; i < MAX_PARENTS; i++){
      parents[i].addr = TOS_NODE_ID;
      parents[i].etx = 0;
      parents[i].periods = 0;
      parents[i].subunits = 0;
    }
/*#ifdef PRINTF
	printf("sending message of length %u\n",sizeof(*msg));
	printfflush();
#endif*/
    if (call Send.send(&packet, sizeof(data_msg_t)) != SUCCESS)
	      call Leds.led0On();
    else if(TOS_NODE_ID == SINK_ID)
	      sinkAcks++;
  }

  event void Period.fired(){
#ifdef PRINTF
	printf("period fired: %u\n",currentTick);
#endif
    if (currentTick == 0){
      call Period.startPeriodic(period);
    }
    if (currentTick == operatingPeriods){
      call Period.stop();
    } else {
      currentTick++;
      //sendMsg();
      call ReadTemp.read();
    }
#ifdef PRINTF_SUPPORT
    call PrintfFlush.flush();
#endif
  } 

  event void Send.sendDone(message_t* m, error_t err) {
  	if(TOS_NODE_ID != SINK_ID)
		call Leds.led2Toggle();
  } 

  event void ReadTemp.readDone(error_t result, uint16_t val) {  
    currentTemp = val;
    sendMsg();
    //call ReadHumidity.read();
  }

  event void ReadHumidity.readDone(error_t result, uint16_t val) {
    currentHum = val;
    sendMsg();
    //call ReadVoltage.read();
  }

  event void ReadVoltage.readDone(error_t result, uint16_t val) {
    currentBat = val;
    sendMsg();
  }

  command void RoutingTester.startRouting(){
    call OppClear.clear();
    call RoutingInfo.clearStats();
    call RoutingControl.start();
  }

  command void RoutingTester.stopRouting(){
    call RoutingControl.stop();
  }

  command void RoutingTester.setRoot(){
    //call RootControl.setRoot();
  }

  command void RoutingTester.activateTask(bool randomize_start,
                                          uint32_t taskPeriod, 
                                          uint32_t taskOperatingPeriods){
    uint8_t i;
    uint32_t random_delay;
#ifdef PRINTF
	printf("sending task activated(%lu,%i,%lu)\n",randomize_start,taskPeriod,taskOperatingPeriods);
	printfflush();
#endif
    period = taskPeriod;
    operatingPeriods = taskOperatingPeriods;
    msgSeqNum = 0;
    current_parent_index = 0;
    sinkAcks = 0;
    numParentsSeen = 0;    
    parents[0].addr = TOS_NODE_ID;
    parents[0].etx = 0;
    parents[0].periods = 0;
    parents[0].subunits = 0;      
    for (i = 1; i < MAX_PARENTS; i++){
      parents[i].addr = TOS_NODE_ID;
      parents[i].etx = 0;
      parents[i].periods = 0;
      parents[i].subunits = 0;
    }
    currentTick = 0;
    last_time_recorded = call Period.getNow();
    if (randomize_start){
      random_delay = call Random.rand32();
      random_delay %= (period - 100);
      random_delay += 100;
      call Period.startOneShot(random_delay);
    } else {
      call Period.startOneShot(period);
    }
  }

  command void RoutingTester.setPower(uint8_t newPower) {
    call OppRadioSettings.setPower(newPower);
  }

  event void RoutingInfo.parentChanged(){
    if (current_parent_index < MAX_PARENTS){
      parents[current_parent_index].subunits += call Period.getNow() - 
        last_time_recorded;
      if (parents[current_parent_index].subunits >= period){
        parents[current_parent_index].periods += 1;
        parents[current_parent_index].subunits -= period;
      }
    }
    last_time_recorded = call Period.getNow();
    current_parent_index++;
    numParentsSeen++;
    if (current_parent_index < MAX_PARENTS){
      parents[current_parent_index].addr = call RoutingInfo.getParent();
      parents[current_parent_index].etx = call RoutingInfo.getParentEtx();
      parents[current_parent_index].periods = 0;
      parents[current_parent_index].subunits = 0;      
    }
  }

  event void RoutingInfo.parentLost(){
    if (current_parent_index < MAX_PARENTS){
      parents[current_parent_index].subunits += call Period.getNow() - 
        last_time_recorded;
      if (parents[current_parent_index].subunits >= period){
        parents[current_parent_index].periods += 1;
        parents[current_parent_index].subunits -= period;
      }
    }
    last_time_recorded = call Period.getNow();
    current_parent_index++;
    if (current_parent_index < MAX_PARENTS){
      parents[current_parent_index].addr = TOS_NODE_ID;
      parents[current_parent_index].etx = 0;
      parents[current_parent_index].periods = 0;
      parents[current_parent_index].subunits = 0;      
    }
  }


#ifdef PRINTF_SUPPORT
  event void PrintfControl.startDone(error_t error) {}

  event void PrintfControl.stopDone(error_t error) {}

  event void PrintfFlush.flushDone(error_t error) {}
#endif

}
