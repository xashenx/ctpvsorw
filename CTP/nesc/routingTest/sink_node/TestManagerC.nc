 #include <Timer.h>
 #include "Configuration.h"
 #include "route_msg.h"
 #include "config_msg.h"

 #ifdef PRINTF_SUPPORT
 #include "printf.h"
 #endif
#ifdef PRINTF
 #include "printf.h"
 #endif


 #ifdef MSG_LOGGER
 #include "StorageVolumes.h"
 #endif

module TestManagerC {
  uses {
    interface Boot;
    interface Leds;
    interface Timer<TMilli>;
    interface Random;
    interface Timer<TMilli> as ConfigFwTimer;
    interface Receive;
    interface AMPacket;
    interface RoutingTester;
    interface Queue<result_msg_t>;
    interface AMSend as ConfigSend;
   interface DCevaluator;

    interface ResetFlooding;

#ifdef MSG_LOGGER
    interface Timer<TMilli> as FwTimer;
    interface LogRead;
    interface LogWrite;
    interface AMSend as ReportSend;
    interface Receive as ConfigReceive;
#endif

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
#ifdef PRINTF
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

#ifdef MSG_LOGGER
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
#endif

  event void Boot.booted() {
    test_state = DONE;
#ifdef SERIAL_FW
    call SerialControl.start();
#endif

#ifdef MSG_LOGGER
    flashBusy = TRUE;
    call Leds.led1On();
    call Leds.led2On();
    call LogWrite.erase();
    booting = TRUE;
    post sendBootupMsg();
#endif

#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
#ifdef PRINTF
    call PrintfControl.start();
#endif
  	#ifdef PRINTF
	printf("sink booted!!!\n");
	call PrintfFlush.flush();
	#endif
#ifdef DUMMY_START
	#warning ****** DUMMY START ACTIVE ******
   	call ConfigFwTimer.startOneShot(4000);
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
      call RoutingTester.setRoot();
      test_state = BOOTING_ROUTING;
      call Timer.startOneShot(1000ULL * config.routing_boot_period);
    } else if (test_state == BOOTING_ROUTING){
/*    if(config.random_interval){
	wakeup_interval = call Random.rand32();
      	wakeup_interval %= (config.sleep_interval - 100);
      	wakeup_interval += 100;
      }else{
	wakeup_interval = config.sleep_interval;
      }*/
      #warning "**** SINK ALWAYS ON ****"
	//if(config.random_interval)
		wakeup_interval = 0;
/*	else
		wakeup_interval = 0;*/
      /*call LowPowerListening.setLocalSleepInterval(config.sleep_interval);
      call DCevaluator.startExperiment(config.sleep_interval);*/
#ifdef LPL_COEXISTENCE
      call LowPowerListening.setLocalSleepInterval(wakeup_interval);
#endif
      call DCevaluator.startExperiment(wakeup_interval);
      call Leds.led0Off();
      test_state = RUNNING_APP;
      call RoutingTester.activateTask(config.randomize_start,
                                      1000ULL * config.app_period, 
                                      config.run_period / config.app_period);
      call Timer.startOneShot(1000ULL * config.run_period);
    } else if (test_state == RUNNING_APP){
      test_state = STOPPING_APP;
      call Timer.startOneShot(1000ULL * config.stop_period);
    } else if (test_state == STOPPING_APP){
      call RoutingTester.stopRouting();
      test_state = DONE;
      call Leds.set(0x0);
#ifdef MSG_LOGGER
      call LogRead.read(&flash_msg, sizeof(result_msg_t));
#endif
    }
  }
  
  event message_t* Receive.receive(message_t* msg, 
                                   void* payload, 
                                   uint8_t len) {
    result_msg_t temp;
  	#ifdef PRINTF
	printf("received a message!\n");
	call PrintfFlush.flush();
	#endif
    call Leds.led2Toggle();
    if (len == sizeof(data_msg_t) && test_state != DONE){
      data_msg_t* net_msg = (data_msg_t *) payload;
      if (call Queue.size() < call Queue.maxSize()) {
        memcpy(&(temp.data_msg), net_msg, sizeof(data_msg_t));
        temp.rep_seq_no = ++last_result_seq_no;
        call Queue.enqueue(temp);
#ifdef SERIAL_FW
        if (!serialBusy) {
          post serialSend();
        }
#endif
#ifdef MSG_LOGGER
       if (!flashBusy)
         post flashLog();
#endif
      }
    }
    return msg;
  }

#ifdef SERIAL_FW
 task void serialSend() {
   if (call Queue.empty()) {
     return;
   }
   else if (!serialBusy) {
     result_msg_t temp = call Queue.head();
     result_msg_t* msg = (result_msg_t*) call
       SerialSend.getPayload(&packet);
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
      call ConfigSend.getPayload(&config_packet);
    call Leds.led2Toggle();
    call ResetFlooding.reset();   
#ifdef DUMMY_START
	config.seq_no=27;
	config.app_period=30;
	config.wait_period=3;
	config.routing_boot_period=3;
	config.run_period=180;
	config.stop_period=3;
	config.power=27;
	config.sleep_interval=250;
	config.randomize_start = FALSE;
	config.random_interval = FALSE;
  	#ifdef PRINTF
	printf("building dummy start config msg! %lu\n",config.run_period);
	call PrintfFlush.flush();
	#endif
#endif
    memcpy(msg, &config, sizeof(config_msg_t));
#ifdef LPL_COEXISTENCE
    call LowPowerListening.setRxSleepInterval(&config_packet, 0);
#endif
    if (call ConfigSend.send(AM_BROADCAST_ADDR, &config_packet, 
                             sizeof(config_msg_t)) != SUCCESS){
      call ConfigFwTimer.startOneShot(call Random.rand32() % 10);
   #ifdef PRINTF
	printf("failing to send the config message!(1)\n");
	call PrintfFlush.flush();
    #endif
      }
 
  }

  event void ConfigSend.sendDone(message_t *msg, error_t error)
  {
    if (error != SUCCESS) {
      call ConfigFwTimer.startOneShot(call Random.rand32() % 10);
    #ifdef PRINTF
	printf("failing to send the config message!(2)\n");
	call PrintfFlush.flush();
    #endif
      return;
    }
    call RoutingTester.setPower(config.power);
    test_state = WAITING;
    #ifdef PRINTF
	printf("Configuration message broadcasted\n");
	call PrintfFlush.flush();
    #endif
    call Timer.startOneShot(1000ULL * config.wait_period);
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
    call RoutingTester.setPower(config.power);
    test_state = WAITING;
    call Timer.startOneShot(1000ULL * config.wait_period);
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
#ifdef PRINTF
  event void PrintfControl.startDone(error_t error) {}

  event void PrintfControl.stopDone(error_t error) {}

  event void PrintfFlush.flushDone(error_t error) {}
#endif

}
