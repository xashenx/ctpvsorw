 #include <Timer.h>
 #ifdef PRINTF_SUPPORT
 #include "printf.h"
 #endif

configuration TestAppC {
  uses interface ResetFlooding;
}

implementation {
  components MainC, LedsC, ActiveMessageC;
  components RoutingTesterC;
  components TestManagerC;
  components new TimerMilliC() as Timer;
  components new TimerMilliC() as ConfigFwTimer;
  components RandomC;
  //components DutyCycleC;
  components DCevaluatorC;
  
  components new AMSenderC(AM_CONFIG_MSG) as ConfigSend;
  components new AMReceiverC(AM_CONFIG_MSG) as ConfigReceive;

#ifdef LPL_COEXISTENCE
  components CC2420ActiveMessageC;
#endif
#ifdef PRINTF_SUPPORT
  components PrintfC;
#endif

  RoutingTesterC.Boot -> MainC;
  RoutingTesterC.AMPacket -> ActiveMessageC;
  RoutingTesterC.Leds -> LedsC;
  RoutingTesterC.RadioControl -> ActiveMessageC;

  TestManagerC.Boot -> MainC;
  TestManagerC.AMPacket -> ActiveMessageC;
  TestManagerC.Leds -> LedsC;
  TestManagerC.RoutingTester -> RoutingTesterC.RoutingTester;
  TestManagerC.Timer -> Timer;
  TestManagerC.ConfigSend -> ConfigSend;
  TestManagerC.ConfigReceive -> ConfigReceive;
  TestManagerC.ConfigFwTimer -> ConfigFwTimer;
  TestManagerC.Random -> RandomC;

  TestManagerC.ResetFlooding = ResetFlooding;

#ifdef LPL_COEXISTENCE
  TestManagerC.LowPowerListening -> CC2420ActiveMessageC;
#endif
  
#ifdef PRINTF_SUPPORT
  RoutingTesterC.PrintfControl -> PrintfC;
  RoutingTesterC.PrintfFlush -> PrintfC;
  TestManagerC.PrintfControl -> PrintfC;
  TestManagerC.PrintfFlush -> PrintfC;
#endif
  //TestManagerC.DutyCycle -> DutyCycleC;
  TestManagerC.DCevaluator -> DCevaluatorC;
}
