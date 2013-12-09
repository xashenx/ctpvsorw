 #include "opp.h"

 #ifdef PRINTF_SUPPORT
 #include "printf.h"
 #endif

configuration RoutingInfoC {
  uses {
    interface Boot;
    interface AMPacket;
    interface Leds;

#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }

  provides{
    interface RoutingInfo;
  }
}

implementation {
  //components CollectionC as Collector;
  components OppC;
  components RoutingInfoP;

  RoutingInfoP.Boot = Boot;
  RoutingInfoP.Leds = Leds;
  //RoutingInfoP.CollectionPacket -> OppC;
  //RoutingInfoP.CtpInfo -> OppC;
  RoutingInfoP.AMPacket = AMPacket;
  //RoutingInfoP.CollectionDebug <- Collector.CollectionDebug;
  RoutingInfoP.RoutingInfo = RoutingInfo;

#ifdef PRINTF_SUPPORT
  RoutingInfoP.PrintfControl = PrintfControl;
  RoutingInfoP.PrintfFlush = PrintfFlush;
#endif

}
