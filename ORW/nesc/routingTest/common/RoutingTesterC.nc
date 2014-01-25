 #include <Timer.h>
 #include "route_msg.h"

 //#ifdef PRINTF_SUPPORT
 #ifdef PRINTF
 #include "printf.h"
 #endif

configuration RoutingTesterC {
  uses {
    interface Boot;
    //interface SplitControl as RadioControl;
    interface AMPacket;
    interface Leds;
    
#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }

  provides{
    interface RoutingTester;
  }
}

implementation {
  //components CollectionC as Collector;
  components OppC;
  //components new CollectionSenderC(AM_DATA_MSG);
  components RoutingInfoC;
  components RoutingTesterP;
  components new SensirionSht11C() as TempHum;
  components new VoltageC() as Battery;
  components new TimerMilliC() as Period;
  components OppRadioSettingsP;
  components RandomC;
  components UniqueReceiveC;
  components DCevaluatorC;
#ifdef PRINTF
	components PrintfC, SerialStartC;
#endif 

  RoutingInfoC.Boot = Boot;
  RoutingInfoC.AMPacket = AMPacket;
  RoutingInfoC.Leds = Leds;

  RoutingTesterP.Boot = Boot;
  //RoutingTesterP.RadioControl = RadioControl;
  RoutingTesterP.RadioControl -> OppC;
  //RoutingTesterP.RootControl -> Collector;
  RoutingTesterP.RoutingControl -> OppC;
  //RoutingTesterP.Send -> CollectionSenderC;
  RoutingTesterP.Send -> OppC.Send;
  RoutingTesterP.Leds = Leds;
  //RoutingTesterP.AMPacket = AMPacket;
  RoutingTesterP.Packet -> OppC;
  RoutingTesterP.OppClear -> OppC;
  RoutingTesterP.OppClear -> UniqueReceiveC;
  RoutingTesterP.OppRadioSettings -> OppRadioSettingsP;

  RoutingTesterP.RoutingInfo -> RoutingInfoC.RoutingInfo;
  RoutingTesterP.RoutingTester = RoutingTester;

  RoutingTesterP.Random -> RandomC;

  RoutingTesterP.ReadTemp -> TempHum.Temperature;
  RoutingTesterP.ReadHumidity -> TempHum.Humidity;
  RoutingTesterP.ReadVoltage -> Battery;
  RoutingTesterP.Period -> Period;

#ifdef PRINTF_SUPPORT
  RoutingInfoC.PrintfControl = PrintfControl;
  RoutingInfoC.PrintfFlush = PrintfFlush;

  RoutingTesterP.PrintfControl = PrintfControl;
  RoutingTesterP.PrintfFlush = PrintfFlush;
#endif
  RoutingTesterP.DCevaluator -> DCevaluatorC;
}
