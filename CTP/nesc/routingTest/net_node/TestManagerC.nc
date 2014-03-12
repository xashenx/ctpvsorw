 #include <Timer.h>
 #include <Configuration.h>
 #include "config_msg.h"
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
    
    interface AMSend as ConfigSend;
    interface Receive as ConfigReceive;

   interface ResetFlooding;
   interface DCevaluator;

#ifdef LPL_COEXISTENCE
    interface LowPowerListening;
#endif

#ifdef PRINTF
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
           call ConfigSend.getPayload(&config_packet);
     memcpy(msg, &config, sizeof(config_msg_t));
     call ResetFlooding.reset();
#ifdef LPL_COEXISTENCE
     call LowPowerListening.setRxSleepInterval(&config_packet, 0);
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
  	uint32_t wakeup_interval;
    if (test_state == DONE){
      call Leds.led0Toggle();
      call Leds.led1Toggle();
      call Leds.led2Toggle();
    } else if (test_state == WAITING){
      call Leds.set(0);
      call Leds.led0On();
      call RoutingTester.startRouting();
      test_state = BOOTING_ROUTING;
      call Timer.startOneShot(1000ULL * config.routing_boot_period);

    } else if (test_state == BOOTING_ROUTING){
      //call LowPowerListening.setLocalSleepInterval(LOCAL_SLEEP);
      if(config.random_interval){
	wakeup_interval = call Random.rand32();
      	wakeup_interval %= (config.sleep_interval - 100);
      	wakeup_interval += 100;
      }else{
	wakeup_interval = config.sleep_interval;
      }
      /*call LowPowerListening.setLocalSleepInterval(config.sleep_interval);
      call DCevaluator.startExperiment(config.sleep_interval);*/
      call LowPowerListening.setLocalSleepInterval(wakeup_interval);
      call DCevaluator.startExperiment(wakeup_interval);
      //call Leds.led0Off();
      call Leds.led1On();
      // CHANGE FROM FABRIZIO
      // END OF CHANGE
      test_state = RUNNING_APP;
      call RoutingTester.activateTask(config.randomize_start,
                                      1000ULL * config.app_period, 
                                      config.run_period / config.app_period);
      call Timer.startOneShot(1000ULL * config.run_period);
    } else if (test_state == RUNNING_APP){
      call Leds.led1Off();
      test_state = STOPPING_APP;
      call Timer.startOneShot(1000ULL * config.stop_period);
    } else if (test_state == STOPPING_APP){
      call RoutingTester.stopRouting();
      test_state = DONE;
      // CHANGE FROM FABRIZIO
      // setting back the radio as always on
      // so net_nodes will be waiting for further config messages
      //#warning changing the Local Sleep!
      call DCevaluator.stopExperiment();
      call LowPowerListening.setLocalSleepInterval(0);
      // END OF CHANGE
      call Leds.set(0);
    }
  }
 
  event message_t *ConfigReceive.receive(message_t *msg, void *payload,
        uint8_t len)
  {
    config_msg_t *data = (config_msg_t *) payload;
    if (data->seq_no <= last_seq_no)
      return msg;
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

#ifdef PRINTF
  event void PrintfControl.startDone(error_t error) {}

  event void PrintfControl.stopDone(error_t error) {}

  event void PrintfFlush.flushDone(error_t error) {}
#endif

}
