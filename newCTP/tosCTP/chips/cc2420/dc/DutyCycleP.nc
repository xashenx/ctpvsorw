/*
 * Copyright (c) 2012-2013 Omprakash Gnawali, Olaf Landsiedel
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 *
 * @author Olaf Landsiedel
 * @author Omprakash Gnawali
 * @author Fabrizio Zeni
 */

module DutyCycleP{

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
	uint16_t dcycleData;	   
	uint16_t dcycleIdle;
	uint16_t samplesCounter;
	bool last_state;

	
	command error_t Init.init() {
   		lastUpdateTime = call LocalTime32khz.get();
   		totalTime = 0;
   		upTimeData = 0;
   		upTimeIdle = 0;
		dcycleData = 0;
		dcycleIdle = 0;
		dcycleRawSum = 0;
		samplesCounter = 0;
   		call Timer.startPeriodic(100000L);
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

		/*
 		if( action ){
			upTimeData += d;
 		} else {
	 		upTimeIdle += d;
 		}*/
		upTimeData += d;
	}
	
	command uint16_t DutyCycle.getTimeData(){
		return dcycleData;
		//return call LowPowerListening.getLocalDutyCycle();
		//return TOS_NODE_ID+1;
	}

	command uint16_t DutyCycle.getTimeIdle(){
		return upTimeIdle;
		//return (uint16_t)samplesCounter;
		//return TOS_NODE_ID;
	}

	command void DutyCycle.startExperiment(){
   		lastUpdateTime = call LocalTime32khz.get();
   		totalTime = 0;
   		upTimeData = 0;
   		upTimeIdle = 0;
		dcycleData = 0;
		dcycleIdle = 0;
		dcycleRawSum = 0;
		samplesCounter = 0;
		last_state = FALSE;
   		call Timer.startPeriodic(100000L);
	}

	command void DutyCycle.stopExperiment(){
		call Timer.stop();
	}

	event void Timer.fired(){
	   uint32_t now = call LocalTime32khz.get();
	   samplesCounter++;
	   if(last_state)
	    	updateEnergyStat(now);
	   if(upTimeData == 0 && upTimeIdle == 0){
		dcycleRawSum += 1000;	   
	   }else{
	   	dcycleRawSum += (1000 * upTimeData) / totalTime;	   
	   }
	   dcycleData = dcycleRawSum / samplesCounter;	   
	   //dcycleIdle = (1000 * upTimeIdle) / totalTime;	   
	   //uint16_t time = (uint16_t)(call Timer.getNow() / 1024);
	   totalTime = 0;
	   upTimeData = 0;
	   upTimeIdle = 0;
	}

}
