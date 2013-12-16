 #include <Timer.h>
 #include "PreRouting.h"

 #ifdef FLASH_BACK_UP
 #include "StorageVolumes.h"
 #endif
 #ifdef MSG_LOGGER
 #include "StorageVolumes.h"
 #endif

configuration PreRoutingAppC {
  //provides interface ResetFlooding;
}

implementation {

  components MainC, LedsC;
  components ExperimentStarterC, PreRoutingC, ConfigSRC;
  //components OppC;

  components new QueueC(result_msg_t, 12);

  components new AlarmMilli16C() as TimerDequeue;
  components new TimerMilliC() as TimerSend;
  components new TimerMilliC() as StateTimer;
  components new TimerMilliC() as ConfigFwTimer;

  components new AMSenderC(AM_START_MSG) as SendStart;
  components new AMReceiverC(AM_START_MSG) as ReceiveStart;
  components new AMSenderC(AM_CONFIG_MSG) as ConfigSend;
#ifndef SERIAL_FW
  components new AMReceiverC(AM_CONFIG_MSG) as ConfigReceive;
#endif

  components ActiveMessageC, SerialActiveMessageC, CC2420ActiveMessageC;

  components new SensirionSht11C() as TempHum;
  components new VoltageC() as Battery;
#ifdef SERIAL_FW
  components new SerialAMSenderC(AM_RESULT_MSG);
  components new SerialAMReceiverC(AM_CONFIG_MSG) as SerialConfigReceive;
#endif
  components new SerialAMReceiverC(AM_START_MSG) as SerialStartReceive;

  components RandomC;

  PreRoutingC.Boot -> MainC;
  PreRoutingC.Leds -> LedsC;
  ConfigSRC.Boot -> MainC;
  ConfigSRC.Leds -> LedsC;
  ConfigSRC.AMPacket -> ActiveMessageC;
  ConfigSRC.StateTimer -> StateTimer;
  ConfigSRC.ConfigFwTimer -> ConfigFwTimer;
  ConfigSRC.ConfigSend -> ConfigSend;
  //ConfigSRC.RoutingControl -> OppC;
#ifndef SERIAL_FW
  ConfigSRC.ConfigReceive -> ConfigReceive;
#endif
  ConfigSRC.Random -> RandomC;
  ConfigSRC.Queue -> QueueC;
#ifdef LPL_COEXISTENCE
  ConfigSRC.LowPowerListening -> CC2420ActiveMessageC;
#endif
#ifdef SERIAL_FW
  ConfigSRC.SerialControl -> SerialActiveMessageC;
  ConfigSRC.SerialSend -> SerialAMSenderC.AMSend;
  ConfigSRC.SerialReceive -> SerialConfigReceive;
#endif

  ExperimentStarterC.Boot -> MainC;
  ExperimentStarterC.Leds -> LedsC;
  ExperimentStarterC.AMControl -> ActiveMessageC;
  ExperimentStarterC.SerialAMControl -> SerialActiveMessageC;

  ExperimentStarterC.ReceiveUART -> SerialStartReceive;
  ExperimentStarterC.Packet -> SendStart;
  ExperimentStarterC.CC2420Packet -> CC2420ActiveMessageC;

  ExperimentStarterC.SendStart -> SendStart;
  ExperimentStarterC.ReceiveStart -> ReceiveStart;
  ExperimentStarterC.LowPowerListening -> CC2420ActiveMessageC;

  PreRoutingC.ReadTemp -> TempHum.Temperature;  
  PreRoutingC.ReadHumidity -> TempHum.Humidity;  
  PreRoutingC.ReadVoltage -> Battery;  
  PreRoutingC.LowPowerListening -> CC2420ActiveMessageC;
  
  ExperimentStarterC.ExperimentPreRouting -> PreRoutingC;
}
