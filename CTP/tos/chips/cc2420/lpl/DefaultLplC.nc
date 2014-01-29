/*
 * Copyright (c) 2005-2006 Rincon Research Corporation
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
 * - Neither the name of the Rincon Research Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * RINCON RESEARCH OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * Low Power Listening for the CC2420
 * @author David Moss
 * @author Fabrizio Zeni
 */


#include "DefaultLpl.h"
#warning "*** USING DEFAULT POWER LISTENING LAYER"

configuration DefaultLplC {
  provides {
    interface LowPowerListening;
    interface Send;
    interface Receive;
    interface SplitControl;
    interface State as SendState;
#ifdef RADIO_ACTIVATIONS
    interface RadioActivations;
#endif
  }
  
  uses { 
    interface Send as SubSend;
    interface Receive as SubReceive;
    interface SplitControl as SubControl;
  }
}

implementation {
  components MainC,
      DefaultLplP,
      PowerCycleC,
      CC2420ActiveMessageC,
      CC2420CsmaC,
      CC2420TransmitC,
      CC2420PacketC,
      RandomC,
      new StateC() as SendStateC,
      new TimerMilliC() as OffTimerC,
      new TimerMilliC() as SendDoneTimerC,
      //DutyCycleC;
      LedsC,
      DCevaluatorC;


#ifdef RADIO_ACTIVATIONS
  DefaultLplP = RadioActivations;
#endif

  
  LowPowerListening = DefaultLplP;
  Send = DefaultLplP;
  Receive = DefaultLplP;
  SplitControl = PowerCycleC;
  SendState = SendStateC;
  
  SubControl = DefaultLplP.SubControl;
  SubReceive = DefaultLplP.SubReceive;
  SubSend = DefaultLplP.SubSend;
  
  
  MainC.SoftwareInit -> DefaultLplP;
  
  
  DefaultLplP.SplitControlState -> PowerCycleC.SplitControlState;
  DefaultLplP.RadioPowerState -> PowerCycleC.RadioPowerState;
  DefaultLplP.SendState -> SendStateC;
  DefaultLplP.OffTimer -> OffTimerC;
  DefaultLplP.SendDoneTimer -> SendDoneTimerC;
  DefaultLplP.PowerCycle -> PowerCycleC;
  DefaultLplP.Resend -> CC2420TransmitC;
  DefaultLplP.PacketAcknowledgements -> CC2420ActiveMessageC;
  DefaultLplP.AMPacket -> CC2420ActiveMessageC;
  DefaultLplP.CC2420PacketBody -> CC2420PacketC;
  DefaultLplP.RadioBackoff -> CC2420CsmaC;
  DefaultLplP.Random -> RandomC;
  DefaultLplP.Leds -> LedsC;
  //DefaultLplP.DutyCycle -> DutyCycleC;
  DefaultLplP.DutyCycle -> DCevaluatorC;
}
