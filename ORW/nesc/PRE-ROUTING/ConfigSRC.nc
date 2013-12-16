 #include <Timer.h>
 #include "Configuration.h"
 #include "config_msg.h"
 #include "route_msg.h"

 #ifdef PRINTF_SUPPORT
 #include "printf.h"
 #endif

 #ifdef MSG_LOGGER
 #include "StorageVolumes.h"
 #endif

module ConfigSRC {
  uses {
    interface Boot;
    interface Leds;
    interface Timer<TMilli> as StateTimer;
    interface Random;
    interface Timer<TMilli> as ConfigFwTimer;
    interface AMPacket;
    //interface RoutingTester;
    interface AMSend as ConfigSend;
    //interface StdControl as RoutingControl;
#ifndef SERIAL_FW
    interface Receive as ConfigReceive;
#endif

    //interface ResetFlooding;

    interface Queue<result_msg_t>;
/*#ifdef MSG_LOGGER
    interface Timer<TMilli> as FwTimer;
    interface LogRead;
    interface LogWrite;
    interface AMSend as ReportSend;
    interface Receive as ConfigReceive;
#endif*/

#ifdef ALTERNATE_RADIO_FLASH
    interface SplitControl as AMControl;
#endif

#ifdef SERIAL_FW
    interface SplitControl as SerialControl;
    interface AMSend as SerialSend;
    interface Receive as SerialReceive;
#endif

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

  uint8_t test_state;
  uint16_t last_seq_no = 0;
  uint32_t last_result_seq_no = 0;

  message_t packet, config_packet;
  uint8_t msglen;
  config_msg_t config;

#ifdef SERIAL_FW
  task void serialSend();
  bool serialBusy = FALSE;
#endif

/*#ifdef MSG_LOGGER
  task void flashLog();
  bool flashBusy = FALSE;
  result_msg_t flash_msg;
  bool booting;
#endif

#ifdef MSG_LOGGER
  task void sendBootupMsg(){
    result_msg_t* msg = (result_msg_t*) call
      ReportSend.getPayload(&packet);
    msg->rep_seq_no = 0xFFFFFFFF;
#ifdef LPL_COEXISTENCE
    call LowPowerListening.setRxSleepInterval(&packet, 0);
#endif
    call ReportSend.send(AM_BROADCAST_ADDR, &packet, sizeof(result_msg_t));
  }
#endif*/

  event void Boot.booted() {
  	//call RoutingControl.stop();
    test_state = DONE;
#ifdef SERIAL_FW
    call SerialControl.start();
#endif

/*#ifdef MSG_LOGGER
    flashBusy = TRUE;
    call Leds.led1On();
    call Leds.led2On();
    call LogWrite.erase();
    booting = TRUE;
    post sendBootupMsg();
#endif*/

#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

#if defined(SERIAL_FW) && (defined(MSG_LOGGER) || defined(PRINTF_SUPPORT))
#error SERIAL_FW is incompatible with MSG_LOGGER and PRINTF_SUPPORT
#endif

#ifdef ALTERNATE_RADIO_FLASH
#warning you are switching off the radio while writing on the flash
#endif

#if defined (ALTERNATE_RADIO_FLASH) && !defined(MSG_LOGGER)
#error ALTERNATE_RADIO_FLASH can be used only with MSG_LOGGER
#endif

#ifdef SERIAL_FW
  event void SerialControl.startDone(error_t err) {
    if (err == SUCCESS){
      serialBusy = FALSE;
    } else {
      call SerialControl.start();
    }
  }

  event void SerialControl.stopDone(error_t err) {}
#endif

#ifdef ALTERNATE_RADIO_FLASH
  event void AMControl.startDone(error_t error){
    if (error != SUCCESS)
        call AMControl.start();
  }

  event void AMControl.stopDone(error_t error){
    if (error != SUCCESS)
        call AMControl.stop();
  }
#endif

  event void StateTimer.fired() {
    if (test_state == DONE){
      call Leds.led0Toggle();
      call Leds.led1Toggle();
      call Leds.led2Toggle();
    } else if (test_state == WAITING){
      call Leds.set(0);
      call Leds.led0On();
      //call RoutingControl.start();
      //call RoutingTester.startRouting();
      //call RoutingTester.setRoot();
      test_state = BOOTING_ROUTING;
      call StateTimer.startOneShot(1000ULL * config.routing_boot_period);
    } else if (test_state == BOOTING_ROUTING){
#ifdef SERIAL_FW
      call Leds.led0Off();
#else
      call Leds.led1On();
#ifdef LOCAL_SLEEP
      call LowPowerListening.setLocalWakeupInterval(LOCAL_SLEEP);
#endif
#endif
      test_state = RUNNING_APP;
      /*call RoutingTester.activateTask(config.randomize_start,
                                      1000ULL * config.app_period, 
                                      config.run_period / config.app_period);*/
      call StateTimer.startOneShot(1000ULL * config.run_period);
    } else if (test_state == RUNNING_APP){
#ifndef SERIAL_FW
      call Leds.led1Off();
#endif
      test_state = STOPPING_APP;
      call StateTimer.startOneShot(1000ULL * config.stop_period);
    } else if (test_state == STOPPING_APP){
    	//call RoutingControl.stop();
//      call RoutingTester.stopRouting();
      test_state = DONE;
      call Leds.set(0x0);
#ifndef SERIAL_FW
#ifdef LOCAL_SLEEP
      #warning changing the Local Wakeup!
      call LowPowerListening.setLocalWakeupInterval(0);
#endif
#endif

#ifdef MSG_LOGGER
      call LogRead.read(&flash_msg, sizeof(result_msg_t));
#endif
    }
  }
  
#ifdef SERIAL_FW
 task void serialSend() {
   if (call Queue.empty()) {
     return;
   }
   else if (!serialBusy) {
     result_msg_t temp = call Queue.head();
     result_msg_t* msg = (result_msg_t*) call
       SerialSend.getPayload(&packet,sizeof(result_msg_t));
     memcpy(msg, &temp, sizeof(result_msg_t));
     if (call SerialSend.send(AM_BROADCAST_ADDR,
                              &packet,
                              sizeof(result_msg_t)) == SUCCESS) {
       serialBusy = TRUE;
     } else {
       post serialSend();
     }
   }
 }
#endif

#ifdef MSG_LOGGER
  task void flashLog()
  {
    result_msg_t temp;
    if (call Queue.empty()){
      flashBusy = FALSE;
#ifdef ALTERNATE_RADIO_FLASH
      call AMControl.start();
#endif
    } else {
      temp = call Queue.head();
#ifdef ALTERNATE_RADIO_FLASH
      call AMControl.stop();
#endif
      if (call LogWrite.append(&temp, sizeof(result_msg_t)) == SUCCESS){
        flashBusy = TRUE;
      } else {
        call Leds.led1On();
        flashBusy = FALSE;
      }
    }
  }
#endif

  event void ConfigFwTimer.fired()
  {
    config_msg_t *msg = (config_msg_t *)
      call ConfigSend.getPayload(&config_packet,sizeof(config_msg_t));
    memcpy(msg, &config, sizeof(config_msg_t));
    call Leds.led2Toggle();
    //call ResetFlooding.reset();   
#ifdef LPL_COEXISTENCE
    call LowPowerListening.setRemoteWakeupInterval(&config_packet, 0);
#endif
    if (call ConfigSend.send(AM_BROADCAST_ADDR, &config_packet, 
                             sizeof(config_msg_t)) != SUCCESS)
      call ConfigFwTimer.startOneShot(call Random.rand32() % 10);
  }

  event void ConfigSend.sendDone(message_t *msg, error_t error)
  {
    if (error != SUCCESS) {
      call ConfigFwTimer.startOneShot(call Random.rand32() % 10);
      return;
    }
    //call RoutingTester.setPower(config.power);
    test_state = WAITING;
    call StateTimer.startOneShot(1000ULL * config.wait_period);
    call Leds.set(0);
  }

#ifdef MSG_LOGGER
  event void ReportSend.sendDone(message_t *msg, error_t error)
  {
    if (booting){
      if (error != SUCCESS){
        post sendBootupMsg();
      } else {
        booting = FALSE;
      }
      return;
    }
    call FwTimer.startOneShot(200);
  }

  event message_t *ConfigReceive.receive(message_t *msg, void *payload,
        uint8_t len)
  {
    config_msg_t *data = (config_msg_t *) payload;
    call Leds.led1Toggle();;
    if (data->seq_no <= last_seq_no)
      return msg;
    last_result_seq_no = 0;
    last_seq_no = data->seq_no;
    memcpy(&config, payload, sizeof(config_msg_t));
    call ConfigFwTimer.startOneShot(call Random.rand32() % 10);
    return msg;
  }
#endif

#ifndef SERIAL_FW
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
#endif

#ifdef SERIAL_FW
  event void SerialSend.sendDone(message_t* msg, error_t error) {
    if (error == SUCCESS)
      call Queue.dequeue();
    serialBusy = FALSE;
    if (!call Queue.empty()) {
      post serialSend();
    }
  }

  event message_t *SerialReceive.receive(message_t *msg, void *payload,
        uint8_t len)
  {
    config_msg_t *data = (config_msg_t *) payload;
    if (data->seq_no <= last_seq_no)
      return msg;
    call Leds.led2Toggle();
    last_result_seq_no = 0;
    last_seq_no = data->seq_no;
    memcpy(&config, payload, sizeof(config_msg_t));
    //call RoutingTester.setPower(config.power);
    test_state = WAITING;
    call StateTimer.startOneShot(1000ULL * config.wait_period);
    call Leds.set(0);
    call ConfigFwTimer.startOneShot(call Random.rand32() % 10);
    return msg;
  }
#endif

#ifdef MSG_LOGGER
  event void LogRead.readDone(void *buf, storage_len_t len, error_t err)
  {
    if (len == sizeof(result_msg_t) && buf == &flash_msg) {
      result_msg_t *msg = (result_msg_t *) call ReportSend.getPayload(&packet);
      memcpy(msg, buf, sizeof(result_msg_t));
#ifdef LPL_COEXISTENCE
      call LowPowerListening.setRxSleepInterval(&packet, 0);
#endif
      call ReportSend.send(AM_BROADCAST_ADDR, &packet, sizeof(result_msg_t));
      call Leds.led1Toggle();
    } else {
      flashBusy = TRUE;
      call Leds.led1On();
      call Leds.led2On();
#ifdef ALTERNATE_RADIO_FLASH
      call AMControl.stop();
#endif
      call LogWrite.erase();
    }
  }

  event void LogWrite.appendDone(void *buf, storage_len_t len, bool recordsLost,
        error_t err)
  {
    if (err == SUCCESS)
      call Queue.dequeue();
    post flashLog();
  }

  event void LogRead.seekDone(error_t error)
  {
  }

  event void LogWrite.eraseDone(error_t error)
  {
    call Leds.led1Off();
    call Leds.led2Off();
    flashBusy = FALSE;
#ifdef ALTERNATE_RADIO_FLASH
    call AMControl.start();
#endif
  }

  event void LogWrite.syncDone(error_t error)
  {
  }

  event void FwTimer.fired()
  {
    call LogRead.read(&flash_msg, sizeof(result_msg_t));
  }
#endif

#ifdef PRINTF_SUPPORT
  event void PrintfControl.startDone(error_t error) {}

  event void PrintfControl.stopDone(error_t error) {}

  event void PrintfFlush.flushDone(error_t error) {}
#endif

}
