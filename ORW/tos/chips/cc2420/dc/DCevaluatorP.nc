/*
 * @author Fabrizio Zeni
 */

 #ifdef PRINTF
 #include "printf.h"
 #endif

module DCevaluatorP{

	provides interface DCevaluator;
	provides interface DutyCycle;
	provides interface Init;
	
	uses interface LocalTime<T32khz> as LocalTime32khz;
	uses interface Timer<TMilli>;
	uses interface Leds;
	uses interface LowPowerListening;
} 

implementation {

	uint32_t lastUpdateTime;
	uint32_t totalTime;
	uint32_t upTimeData, upStartTime;
	uint32_t upTimeIdle;
	uint16_t dcycleRawSum;
	uint16_t dcycle;	   
	uint16_t samplesCounter;
	uint16_t sleepInterval;
	bool last_state; // do we get at least an update?

	
	command error_t Init.init() {
   		lastUpdateTime = call LocalTime32khz.get();
   		totalTime = 0;
   		upTimeData = 0;
   		upTimeIdle = 0;
		dcycle = 0;
		dcycleRawSum = 0;
		samplesCounter = 0;
		sleepInterval = 0;
   		//call Timer.startPeriodic(100000L);
		last_state = FALSE;
    		return SUCCESS;
  	}



	void updateEnergyStat(uint32_t now) {
   		uint32_t t;
   		if( now < lastUpdateTime) {
			// because we can exceed the uint32_t!
     			t = (now + ((uint32_t)0xFFFFFFFF - lastUpdateTime));
   		} else {
	     		t = (now - lastUpdateTime);
   		}
   		totalTime += t;
   		lastUpdateTime = now;
 	}
	
	command void DutyCycle.radioOn(){
	   	uint32_t now = call LocalTime32khz.get();
	    	updateEnergyStat(now);
   		upStartTime = now;
		last_state = TRUE;
		/*#ifdef PRINTF
		printf("DCEV: radio turned on!\n");
		#endif*/
	}
  
	command void DutyCycle.radioOff(bool action){
	   	uint32_t now = call LocalTime32khz.get();
	   	uint32_t d;
		last_state = TRUE;
	    	updateEnergyStat(now);
 		if (now < upStartTime) {
			// because we can exceed the uint32_t!
   			d = (now + ((uint32_t)0xFFFFFFFF - upStartTime));
 		} else {
   			d = (now - upStartTime);
 		}

		
 		/*if( action ){
			upTimeData += d;
 		} else {
	 		upTimeIdle += d;
 		}*/
		upTimeData += d;
		/*#ifdef PRINTF
		printf("DCEV: radio turned off!\n");
		#endif*/
	}
	
	command uint16_t DCevaluator.getActualDutyCycle(){
		if (TOS_NODE_ID == SINK_ID || sleepInterval == 0)
			return 1000;
		return dcycle;
	}

	command uint16_t DCevaluator.getSleepInterval(){
		return sleepInterval;
	}

	command void DCevaluator.startExperiment(uint16_t sleep){
		/*#ifdef PRINTF
		printf("DCEV: start Exp!\n");
		#endif*/
	   	lastUpdateTime = call LocalTime32khz.get();
   		upStartTime = call LocalTime32khz.get();
   		totalTime = 0;
   		upTimeData = 0;
	   	upTimeIdle = 0;
		dcycle = 0;
		dcycleRawSum = 0;
		samplesCounter = 0;
		last_state = FALSE;
	   	//call Timer.startPeriodic(1000);
		sleepInterval = sleep;
		if(sleepInterval > 0){
	   		call Timer.startPeriodic(sleepInterval*1.2);
			#ifdef PRINTF
			printf("sleepInterval: %u\n",sleepInterval);
			printfflush();
			#endif
//	   		call Timer.startPeriodic(LPL_DEF_LOCAL_WAKEUP*1.2);
		}
	}

	command void DCevaluator.stopExperiment(){
		/*#ifdef PRINTF
		printf("DCEV: stop Exp!\n");
		#endif*/
		call Timer.stop();
	}

	event void Timer.fired(){
	   /*uint32_t now = call LocalTime32khz.get();
	   samplesCounter++;
	   if(last_state)
	    	updateEnergyStat(now);
	   if(upTimeData == 0 && upTimeIdle == 0){
	   	#ifdef PRINTF
		printf("DCEV: uptime = 0\n");
		#endif
		dcycleRawSum += 1000;	   
	   }else{
	   	#ifdef PRINTF
		printf("DCEV: normal timer computation\n");
		#endif
	   	dcycleRawSum += (1000 * upTimeData) / totalTime;	   
	   }
	   dcycle = dcycleRawSum / samplesCounter;  
	   #ifdef PRINTF
	   printf("DCEV: duty cycle = %u!\n", dcycle);
	   printfflush();
	   #endif
	   //dcycleIdle = (1000 * upTimeIdle) / totalTime;	   
	   //uint16_t time = (uint16_t)(call Timer.getNow() / 1024);
	   totalTime = 0;
	   upTimeData = 0;
	   upTimeIdle = 0;*/
	   uint32_t now = call LocalTime32khz.get();
	   if(last_state){
	    	updateEnergyStat(now);
	   /*if(upTimeData == 0 && upTimeIdle == 0){
	   	#ifdef PRINTF
		printf("DCEV: uptime = 0\n");
		#endif
		//dcycleRawSum += 1000;
	   }else{*/
	   	samplesCounter++;
	   	dcycleRawSum += (1000 * upTimeData) / totalTime;	   
	   	dcycle = dcycleRawSum / samplesCounter;  
		totalTime = 0;
		upTimeData = 0;
		upTimeIdle = 0;
		#ifdef PRINTF
	 	printf("DCEV: duty cycle = %u!\n", dcycle);
	  	printfflush();
	  	#endif
	   }
	}

}
