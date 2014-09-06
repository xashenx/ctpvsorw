 #include "opp.h"

 //#ifdef PRINTF_SUPPORT
 #ifdef PRINTF
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
    interface OppDebug;
  }
}

implementation {
  //components CollectionC as Collector;
  components OppC;
  components RoutingInfoP;
  #ifdef PRINTF
	components PrintfC, SerialStartC;
	//components SerialPrintfC, SerialStartC;
  #endif

  RoutingInfoP.Boot = Boot;
  RoutingInfoP.Leds = Leds;
  //RoutingInfoP.CollectionPacket -> Collector;
  //RoutingInfoP.CtpInfo -> Collector;
  RoutingInfoP.AMPacket = AMPacket;
  RoutingInfoP.OppDebug = OppDebug;
  RoutingInfoP.RoutingInfo = RoutingInfo;
}
