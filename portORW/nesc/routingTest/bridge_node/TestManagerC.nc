#include <Timer.h>
#include "Configuration.h"
#include "route_msg.h"
#include "config_msg.h"

#ifdef PRINTF_SUPPORT
#include "printf.h"
#endif

module TestManagerC {
  uses {
    interface Boot;
    interface Leds;
    interface AMPacket;
    interface Random;
    interface AMSend as ConfigSend;
    interface Receive as ConfigReceive;
    interface AMSend as ReportSend;
    interface Receive as ReportReceive;
    interface Timer<TMilli> as FwTimer;
    interface Timer<TMilli> as ConfigFwTimer;
    interface Queue<result_msg_t>;

    interface ResetFlooding;

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

#ifdef SERIAL_FW
#warning ATTENTION: this bridge node will forward data to the serial!
#endif

  uint16_t last_seq_no = 0;
  uint32_t last_net_seq_no = 0;

  message_t packet, config_packet;
  uint8_t msglen;
  bool forwardBusy;
  config_msg_t config;

  event void Boot.booted() {
#ifdef SERIAL_FW
    call SerialControl.start();
#endif
#ifndef SERIAL_FW
    forwardBusy = FALSE;
#endif

#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

#ifdef SERIAL_FW
  event void SerialControl.startDone(error_t err) {
    if (err == SUCCESS){
      forwardBusy = FALSE;
    } else {
      call SerialControl.start();
    }
  }

  event void SerialControl.stopDone(error_t err) {}
#endif

  task void forwardSend() 
  {
    if (call Queue.empty()){
      return;
    } else if (!forwardBusy){
      result_msg_t temp = call Queue.head();
      result_msg_t *msg;
#ifdef SERIAL_FW
      msg = (result_msg_t *) call SerialSend.getPayload(&packet);
#endif
#ifndef SERIAL_FW
      msg = (result_msg_t *) call ReportSend.getPayload(&packet);
#endif
      memcpy(msg, &temp, sizeof(result_msg_t));
#ifdef SERIAL_FW
      if (call SerialSend.send(AM_BROADCAST_ADDR, 
                               &packet, 
                               sizeof(result_msg_t)) == SUCCESS){
        forwardBusy = TRUE;
      } else {
        post forwardSend();
      }
#endif
#ifndef SERIAL_FW
#ifdef LPL_COEXISTENCE
     call LowPowerListening.setRxSleepInterval(&packet, 0);
#endif
      if (call ReportSend.send(AM_BROADCAST_ADDR, 
                               &packet,
                               sizeof(result_msg_t)) == SUCCESS){
        forwardBusy = TRUE;
      } else {
        post forwardSend();
      }
#endif
    }
  }

  event void ConfigFwTimer.fired()
  {
     config_msg_t *msg = (config_msg_t *)
           call ConfigSend.getPayload(&config_packet);
     memcpy(msg, &config, sizeof(config_msg_t));     
     call ResetFlooding.reset();
     call Leds.led2Toggle();
#ifdef LPL_COEXISTENCE
     call LowPowerListening.setRxSleepInterval(&config_packet, 0);
#endif
     if (call ConfigSend.send(AM_BROADCAST_ADDR, &config_packet, 
            sizeof(config_msg_t)) != SUCCESS)
       call ConfigFwTimer.startOneShot(call Random.rand32() % 10);
  }


  event message_t * ConfigReceive.receive(message_t *msg, void *payload,
        uint8_t len)
  {
    config_msg_t *data = (config_msg_t *) payload;
    if (data->seq_no <= last_seq_no)
      return msg;
    last_net_seq_no = 0;
    memcpy(&config, payload, sizeof(config_msg_t));
    last_seq_no = config.seq_no;
    call ConfigFwTimer.startOneShot(call Random.rand32() % 10);
    return msg;
  }
 
  event message_t* ReportReceive.receive(message_t* msg, 
                                         void* payload, 
                                         uint8_t len) {
    result_msg_t temp;
    call Leds.led0Toggle();
    if (len == sizeof(result_msg_t)){
      result_msg_t *net_msg = (result_msg_t *) payload;
      if (net_msg->rep_seq_no > last_net_seq_no){
        last_net_seq_no = net_msg->rep_seq_no;
        if (call Queue.size() < call Queue.maxSize()){
          memcpy(&temp, net_msg, sizeof(result_msg_t));
          call Queue.enqueue(temp);
          if (!forwardBusy){
#ifdef SERIAL_FW
            post forwardSend();
#endif
#ifndef SERIAL_FW
            call FwTimer.startOneShot(call Random.rand32() % 10);
#endif
          }
        }
      }
    }
    return msg;
  }

  event void FwTimer.fired()
  {
    post forwardSend();
  }

  event void ConfigSend.sendDone(message_t *msg, error_t error)
  {
    if (error != SUCCESS)
      call ConfigFwTimer.startOneShot(call Random.rand32() % 10);
  }

  event void ReportSend.sendDone(message_t *msg, error_t error)
  {
    if (error == SUCCESS)
      call Queue.dequeue();
    forwardBusy = FALSE;
    if (!call Queue.empty())
      post forwardSend();
  }


#ifdef SERIAL_FW
  event void SerialSend.sendDone(message_t* msg, error_t error) {
    if (error == SUCCESS)
      call Queue.dequeue();
    forwardBusy = FALSE;
    if (!call Queue.empty()) {
      post forwardSend();
    }
  }

  event message_t *SerialReceive.receive(message_t *msg, void *payload,
        uint8_t len)
  {
    config_msg_t *data = (config_msg_t *) payload;
    if (data->seq_no <= last_seq_no)
      return msg;
    last_net_seq_no = 0;
    last_seq_no = data->seq_no;
    memcpy(&config, payload, sizeof(config_msg_t));
    call ConfigFwTimer.startOneShot(call Random.rand32() % 10);
    return msg;
  }
#endif

#ifdef PRINTF_SUPPORT
  event void PrintfControl.startDone(error_t error) {}

  event void PrintfControl.stopDone(error_t error) {}

  event void PrintfFlush.flushDone(error_t error) {}
#endif
}
