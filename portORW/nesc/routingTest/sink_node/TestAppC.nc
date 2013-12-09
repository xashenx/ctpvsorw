 #include <Timer.h>
 #include "route_msg.h"
 #include "config_msg.h"

 #ifdef PRINTF_SUPPORT
 #include "printf.h"
 #endif

 #ifdef MSG_LOGGER
 #include "StorageVolumes.h"
 #endif

configuration TestAppC {
  uses interface ResetFlooding;
}

implementation {
  components MainC, LedsC, ActiveMessageC;
  //components CollectionC as Collector;
  components OppC;
  components RoutingTesterC;
  components TestManagerC;
  components new QueueC(result_msg_t, 12);
  components new TimerMilliC() as Timer;
  components new TimerMilliC() as ConfigFwTimer;
  components new AMSenderC(AM_CONFIG_MSG) as ConfigSend;

#ifdef MSG_LOGGER
  components new TimerMilliC() as FwTimer;
  components new LogStorageC(VOLUME_PACKETS, TRUE);
  components new AMSenderC(AM_REPORT_MSG) as ReportSendC;
  components new AMReceiverC(AM_CONFIG_MSG) as ConfigReceive;
#endif
#ifdef LPL_COEXISTENCE
  components CC2420ActiveMessageC;
#endif
#ifdef SERIAL_FW
  components new SerialAMSenderC(AM_RESULT_MSG);
  components SerialActiveMessageC;
  components new SerialAMReceiverC(AM_CONFIG_MSG);
#endif

#ifdef PRINTF_SUPPORT
  components PrintfC;
#endif

  components RandomC;

  RoutingTesterC.Boot -> MainC;
  RoutingTesterC.AMPacket -> ActiveMessageC;
  RoutingTesterC.Leds -> LedsC;
  //RoutingTesterC.RadioControl -> ActiveMessageC;
  RoutingTesterC.RadioControl -> OppC;

  TestManagerC.Boot -> MainC;
  TestManagerC.AMPacket -> ActiveMessageC;
  TestManagerC.Leds -> LedsC;
  TestManagerC.RoutingTester -> RoutingTesterC.RoutingTester;
  //TestManagerC.Receive -> Collector.Receive[AM_DATA_MSG];
  TestManagerC.Receive -> OppC.Receive;
  //TestManagerC.Receive -> OppC.Receive;
  TestManagerC.Timer -> Timer;
  TestManagerC.ConfigFwTimer -> ConfigFwTimer;
  TestManagerC.Queue -> QueueC;
  TestManagerC.ConfigSend -> ConfigSend;
  TestManagerC.Random -> RandomC;

  TestManagerC.ResetFlooding = ResetFlooding;

#ifdef MSG_LOGGER
  TestManagerC.FwTimer -> FwTimer;
  TestManagerC.LogRead -> LogStorageC;
  TestManagerC.LogWrite -> LogStorageC;
  TestManagerC.ReportSend -> ReportSendC;
  TestManagerC.ConfigReceive -> ConfigReceive;
#endif

#ifdef LPL_COEXISTENCE
  TestManagerC.LowPowerListening -> CC2420ActiveMessageC;
#endif

#ifdef ALTERNATE_RADIO_FLASH
  TestManagerC.AMControl -> ActiveMessageC;
#endif

#ifdef SERIAL_FW
  TestManagerC.SerialControl -> SerialActiveMessageC;
  TestManagerC.SerialSend -> SerialAMSenderC.AMSend;
  TestManagerC.SerialReceive -> SerialAMReceiverC;
#endif

#ifdef PRINTF_SUPPORT
  RoutingTesterC.PrintfControl -> PrintfC;
  RoutingTesterC.PrintfFlush -> PrintfC;
  TestManagerC.PrintfControl -> PrintfC;
  TestManagerC.PrintfFlush -> PrintfC;
#endif
}

