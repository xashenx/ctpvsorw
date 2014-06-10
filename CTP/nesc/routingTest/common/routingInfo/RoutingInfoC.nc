 #include "Ctp.h"

 #ifdef PRINTF
 #include "printf.h"
 #endif

configuration RoutingInfoC {
  uses {
    interface Boot;
    interface AMPacket;
    interface Leds;

#ifdef PRINTF
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }

  provides{
    interface RoutingInfo;
  }
}

implementation {
  components CollectionC as Collector;
  components RoutingInfoP;

  RoutingInfoP.Boot = Boot;
  RoutingInfoP.Leds = Leds;
  RoutingInfoP.CollectionPacket -> Collector;
  RoutingInfoP.CtpInfo -> Collector;
  RoutingInfoP.AMPacket = AMPacket;
  RoutingInfoP.CollectionDebug <- Collector.CollectionDebug;
  RoutingInfoP.RoutingInfo = RoutingInfo;

#ifdef PRINTF
  RoutingInfoP.PrintfControl = PrintfControl;
  RoutingInfoP.PrintfFlush = PrintfFlush;
#endif


}
