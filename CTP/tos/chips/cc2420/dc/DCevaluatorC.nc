/*
 * @author Fabrizio Zeni 
 */

 #ifdef PRINTF
 #include "printf.h"
 #endif
 
 configuration DCevaluatorC{

	provides interface DCevaluator;
	provides interface DutyCycle;
	
} 
implementation {

	components DCevaluatorP;
	components MainC;
	components new TimerMilliC();
	components LedsC;
	components CC2420ActiveMessageC;
#ifdef PRINTF
	components PrintfC;
  DCevaluatorP.PrintfControl -> PrintfC;
  DCevaluatorP.PrintfFlush -> PrintfC;
#endif
	
	MainC -> DCevaluatorP.Init;
	
	DCevaluatorP.Timer -> TimerMilliC;
	
	DCevaluator = DCevaluatorP;	
	DutyCycle = DCevaluatorP;

	components Counter32khz32C, new CounterToLocalTimeC(T32khz);
  	CounterToLocalTimeC.Counter -> Counter32khz32C;
	DCevaluatorP.LocalTime32khz -> CounterToLocalTimeC;
	
	DCevaluatorP.Leds -> LedsC;
	DCevaluatorP.LowPowerListening -> CC2420ActiveMessageC;
}
