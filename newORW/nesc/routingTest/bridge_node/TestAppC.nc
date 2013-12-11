#include <Timer.h>
#include "route_msg.h"
#include "config_msg.h"

#ifdef PRINTF_SUPPORT
#include "printf.h"
#endif

configuration TestAppC {
  uses interface ResetFlooding;
}

implementation {
  components MainC, LedsC, ActiveMessageC;
  components TestManagerC;
  components new QueueC(result_msg_t, 12);
  components new TimerMilliC() as FwTimer;
  components new TimerMilliC() as ConfigFwTimer;

  components new AMSenderC(AM_CONFIG_MSG) as ConfigSend;
  components new AMReceiverC(AM_CONFIG_MSG) as ConfigReceive;
  
  components new AMSenderC(AM_REPORT_MSG) as ReportSendC;
  components new AMReceiverC(AM_REPORT_MSG) as ReportReceiveC;

#ifdef SERIAL_FW
  components new SerialAMSenderC(AM_RESULT_MSG);
  components SerialActiveMessageC;
  components new SerialAMReceiverC(AM_CONFIG_MSG);
#endif
#ifdef LPL_COEXISTENCE
  components CC2420ActiveMessageC;
#endif
#ifdef PRINTF_SUPPORT
  components PrintfC;
#endif

  components RandomC;

  TestManagerC.Boot -> MainC;
  TestManagerC.AMPacket -> ActiveMessageC;
  TestManagerC.Leds -> LedsC;
  TestManagerC.ConfigSend -> ConfigSend;
  TestManagerC.ConfigReceive -> ConfigReceive;
  TestManagerC.ReportSend -> ReportSendC;
  TestManagerC.ReportReceive -> ReportReceiveC;
  TestManagerC.FwTimer -> FwTimer;
  TestManagerC.ConfigFwTimer -> ConfigFwTimer;
  TestManagerC.Queue -> QueueC;
  TestManagerC.Random -> RandomC;

  TestManagerC.ResetFlooding = ResetFlooding;

#ifdef SERIAL_FW
  TestManagerC.SerialControl -> SerialActiveMessageC;
  TestManagerC.SerialSend -> SerialAMSenderC.AMSend;
  TestManagerC.SerialReceive -> SerialAMReceiverC; 
#endif

#ifdef LPL_COEXISTENCE
  TestManagerC.LowPowerListening -> CC2420ActiveMessageC;
#endif

#ifdef PRINTF_SUPPORT
  TestManagerC.PrintfControl -> PrintfC;
  TestManagerC.PrintfFlush -> PrintfC;
#endif
}
