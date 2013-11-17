#include <Timer.h>
#include "route_msg.h"

#ifdef PRINTF_SUPPORT
#include "printf.h"
#endif

configuration RoutingTesterC {
  uses {
    interface Boot;
    interface SplitControl as RadioControl;
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
  components CollectionC as Collector;
  components new CollectionSenderC(AM_DATA_MSG);
  components RoutingInfoC;
  components RoutingTesterP;
  components new SensirionSht11C() as TempHum;
  components new VoltageC() as Battery;
  components new TimerMilliC() as Period;
  components CtpRadioSettingsP;
  components RandomC;

  RoutingInfoC.Boot = Boot;
  RoutingInfoC.AMPacket = AMPacket;
  RoutingInfoC.Leds = Leds;

  RoutingTesterP.Boot = Boot;
  RoutingTesterP.RadioControl = RadioControl;
  RoutingTesterP.RootControl -> Collector;
  RoutingTesterP.RoutingControl -> Collector;
  RoutingTesterP.Send -> CollectionSenderC;
  RoutingTesterP.Leds = Leds;
  RoutingTesterP.AMPacket = AMPacket;
  RoutingTesterP.CtpClear -> Collector;
  RoutingTesterP.CtpRadioSettings -> CtpRadioSettingsP;

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

}
