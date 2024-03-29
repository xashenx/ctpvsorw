/*
 * Copyright (c) 2005-2006 Rincon Research Corporation
 * Extensions for ORW: Copyright (c) 2012-2013 Olaf Landsiedel
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
 * This layer keeps a history of the past RECEIVE_HISTORY_SIZE received messages
 * If the source address and dsn number of a newly received message matches
 * our recent history, we drop the message because we've already seen it.
 * This should sit at the bottom of the stack
 * @author David Moss
 * @author Olaf Landsiedel
 */
 
configuration UniqueReceiveC {
  provides {
    interface Receive;
    interface Receive as DuplicateReceive;
    interface Unique;
    interface AsyncUnique;
    interface TxTime;
    // BEGIN ADD BY FABRIZIO
    interface OppClear;
    // END ADD
  }
  
  uses {
    interface Receive as SubReceive;

  }
}

implementation {
  components UniqueReceiveP,
      CC2420PacketC,
      LedsC, LocalTimeMilliC,
      MainC;
   // BEGIN ADD BY FABRIZIO
   components ActiveMessageC;
   // END ADD
      //RoutingInfoC;
  
  Receive = UniqueReceiveP.Receive;
  DuplicateReceive = UniqueReceiveP.DuplicateReceive;
  SubReceive = UniqueReceiveP.SubReceive;
      
  MainC.SoftwareInit -> UniqueReceiveP;
  
  UniqueReceiveP.CC2420PacketBody -> CC2420PacketC;
  
  Unique = UniqueReceiveP.Unique;
  AsyncUnique = UniqueReceiveP.AsyncUnique;
  
  UniqueReceiveP.Leds -> LedsC;
  UniqueReceiveP.LocalTime -> LocalTimeMilliC;
  // BEGIN ADD BY FABRIZIO
  UniqueReceiveP.AMPacket -> ActiveMessageC;
  OppClear = UniqueReceiveP.OppClear;
  //UniqueReceiveP.OppDebug -> RoutingInfoC;
  //END ADD
  TxTime = UniqueReceiveP.TxTime;
  
  components RandomC;
  UniqueReceiveP.Random -> RandomC;
}

