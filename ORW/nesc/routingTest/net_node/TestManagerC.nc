 #include <Timer.h>
 #include <Configuration.h>
 #include "config_msg.h"
 //#ifdef PRINTF_SUPPORT
 #ifdef PRINTF
 #include "printf.h"
 #endif

module TestManagerC {
  uses {
    interface Boot;
    interface Leds;
    interface Timer<TMilli>;
    interface AMPacket;
    interface RoutingTester;
    interface Timer<TMilli> as ConfigFwTimer;
    interface Random;
    interface Receive;
    
    interface AMSend as ConfigSend;
    interface Receive as ConfigReceive;

   //interface ResetFlooding;
   //interface DutyCycle;

#ifdef LPL_COEXISTENCE
    interface LowPowerListening;
#endif

#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {

  uint16_t last_seq_no;
  uint8_t test_state;
  config_msg_t config;
  message_t config_packet;

  event void ConfigFwTimer.fired()
  {
     config_msg_t *msg = (config_msg_t *)
           call ConfigSend.getPayload(&config_packet,sizeof(config_msg_t));
     memcpy(msg, &config, sizeof(config_msg_t));
     //call ResetFlooding.reset();
#ifdef LPL_COEXISTENCE
     call LowPowerListening.setRemoteWakeupInterval(&config_packet, 0);
#endif
     if (call ConfigSend.send(AM_BROADCAST_ADDR, &config_packet, 
            sizeof(config_msg_t)) != SUCCESS)
       call ConfigFwTimer.startOneShot(call Random.rand32() % 10);
  }

  event void Boot.booted() {
    test_state = DONE;
#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

  event void Timer.fired() {
    if (test_state == DONE){
#ifdef PRINTF
		printf("phase change: turning off\n");
#endif
      call Leds.led0Toggle();
      call Leds.led1Toggle();
      call Leds.led2Toggle();
    } else if (test_state == WAITING){
#ifdef PRINTF
		printf("phase change: booting\n");
#endif
      call Leds.set(0);
      call Leds.led0On();
      call RoutingTester.startRouting();
      test_state = BOOTING_ROUTING;
      call Timer.startOneShot(1000ULL * config.routing_boot_period);
    } else if (test_state == BOOTING_ROUTING){
#ifdef PRINTF
		printf("phase change: running app\n");
		printf("initial WakupI: %u\n",call LowPowerListening.getLocalWakeupInterval());
#endif
      //call Leds.led0Off();
      call Leds.led1On();
      // CHANGE FROM FABRIZIO
      //call DutyCycle.startExperiment();
      call LowPowerListening.setLocalWakeupInterval(LPL_DEF_LOCAL_WAKEUP);

      // END OF CHANGE
      test_state = RUNNING_APP;
      call RoutingTester.activateTask(config.randomize_start,
                                      1000ULL * config.app_period, 
                                      config.run_period / config.app_period);
      call Timer.startOneShot(1000ULL * config.run_period);
    } else if (test_state == RUNNING_APP){
#ifdef PRINTF
		printf("phase change: stopping app\n");
		printf("running WakupI: %u\n",call LowPowerListening.getLocalWakeupInterval());
#endif

      call Leds.led1Off();
      test_state = STOPPING_APP;
      call Timer.startOneShot(1000ULL * config.stop_period);
    } else if (test_state == STOPPING_APP){
      call RoutingTester.stopRouting();
      test_state = DONE;
      // CHANGE FROM FABRIZIO
      // setting back the radio as always on
      // so net_nodes will be waiting for further config messages
      //call DutyCycle.stopExperiment();
      call LowPowerListening.setLocalWakeupInterval(0);
      // END OF CHANGE
      call Leds.set(0);
#ifdef DUMMY_START
	// so that by unplug and replug the sink we can start another test!
	last_seq_no = 0;
#endif
#ifdef PRINTF
		printf("phase change: end of the test\n");
		printf("final WakupI: %u\n",call LowPowerListening.getLocalWakeupInterval());
#endif
    }
#ifdef PRINTF
	printfflush();
#endif
  }
 
  event message_t *ConfigReceive.receive(message_t *msg, void *payload,
        uint8_t len)
  {
    config_msg_t *data = (config_msg_t *) payload;
#ifdef PRINTF
		printf("CONFIG message received from %u\n",call AMPacket.source(msg));
#endif
    if (data->seq_no <= last_seq_no)
      return msg;
#ifdef PRINTF
	printf("config accepted!!!\n");
	printfflush();
#endif
    call Leds.led2Toggle();    
    memcpy(&config, payload, sizeof(config_msg_t));
    last_seq_no = config.seq_no;
    call ConfigFwTimer.startOneShot(call Random.rand32() % 10);
    return msg;
  }
 
  event void ConfigSend.sendDone(message_t *msg, error_t error)
  {
    if (error != SUCCESS){
      call ConfigFwTimer.startOneShot(call Random.rand32() % 10);
      return;
    } 
    call RoutingTester.setPower(config.power);
    test_state = WAITING;
    call Timer.startOneShot(1000ULL * config.wait_period);
    call Leds.set(0);
  }

event message_t* Receive.receive(message_t* bufPtr, 
				   void* payload, uint8_t len){
    return bufPtr;
  }



#ifdef PRINTF_SUPPORT
  event void PrintfControl.startDone(error_t error) {}

  event void PrintfControl.stopDone(error_t error) {}

  event void PrintfFlush.flushDone(error_t error) {}
#endif

}
