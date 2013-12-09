 #include <Timer.h>
 #include "PLR.h"

 #ifdef FLASH_BACK_UP
 #include "StorageVolumes.h"
 #endif

configuration PLRAppC {
  provides interface ResetFlooding;
}

implementation {

  components MainC, LedsC;
  components ExperimentStarterC, PLRC, MAC_PLRC;

  components ResultsStoreC;

  components new TimerMilliC() as TimerExperimentPLR;
  components new TimerMilliC() as TimerStatsPLR;
  components new TimerMilliC() as TimerExperimentMAC_PLR;
  components new TimerMilliC() as TimerStatsMAC_PLR;
  components new AlarmMilli16C() as TimerDequeue;
/*   components new TimerMilliC() as TimerDequeue; */
  components new TimerMilliC() as TimerSend;
/*   components new AlarmMilli16C() as AlarmReset; */

  components new AMSenderC(AM_PLRMSG) as SendPLR;
  components new AMReceiverC(AM_PLRMSG) as ReceivePLR;

  components new AMSenderC(AM_MAC_PLRMSG) as SendMAC_PLR;
  components new AMReceiverC(AM_MAC_PLRMSG) as ReceiveMAC_PLR;

  components new AMSenderC(AM_STARTMSG) as SendStart;
  components new AMReceiverC(AM_STARTMSG) as ReceiveStart;

#if !defined(CTP_REPORT) || defined(ROUTING_NODE) 
  components FloodingReportP;
  components new QueueC(message_t, QUEUE_SIZE) as MessageQueue;
  components new AMSenderC(AM_STATSMSG) as SendStats;
  components new AMReceiverC(AM_STATSMSG) as ReceiveStats;
#else
  components CtpReportP;
  components new QueueC(StatsMsg, QUEUE_SIZE) as MessageQueue;
  components CollectionC as Collector;
  components new CollectionSenderC(AM_STATSMSG) as SendStats;
#endif

  components new SerialAMSenderC(AM_STATSMSG);
  components new SerialAMReceiverC(AM_STARTMSG);

  components ActiveMessageC, SerialActiveMessageC, CC2420ActiveMessageC;

  components new SensirionSht11C() as TempHumPLR;
  components new VoltageC() as BatteryPLR;

  components new SensirionSht11C() as TempHumMAC_PLR;
  components new VoltageC() as BatteryMAC_PLR;

  components RandomC;

  PLRC.Boot -> MainC;
  PLRC.Leds -> LedsC;
  MAC_PLRC.Boot -> MainC;
  MAC_PLRC.Leds -> LedsC;
#ifndef CTP_REPORT
  FloodingReportP.Boot -> MainC;
  FloodingReportP.Leds -> LedsC;
#else
  CtpReportP.Boot -> MainC;
  CtpReportP.Leds -> LedsC;
  CtpReportP.RootControl -> Collector;
  CtpReportP.RoutingControl -> Collector;
#endif

/*   Resetter.Boot -> MainC; */
/*   Resetter.Leds -> LedsC; */

  ExperimentStarterC.Boot -> MainC;
  ExperimentStarterC.Leds -> LedsC;
  ExperimentStarterC.AMControl -> ActiveMessageC;
  ExperimentStarterC.SerialAMControl -> SerialActiveMessageC;

  PLRC.TimerExperiment -> TimerExperimentPLR;
  PLRC.TimerStats -> TimerStatsPLR;
  MAC_PLRC.TimerExperiment -> TimerExperimentMAC_PLR;
  MAC_PLRC.TimerStats -> TimerStatsMAC_PLR;
  MAC_PLRC.TimerSend -> TimerSend;
/*   Resetter.AlarmReset -> AlarmReset; */

  PLRC.ResultsStore -> ResultsStoreC;
  MAC_PLRC.ResultsStore -> ResultsStoreC;
  
  ExperimentStarterC.ReceiveUART -> SerialAMReceiverC;
  ExperimentStarterC.Packet -> SendStart;
  ExperimentStarterC.CC2420Packet -> CC2420ActiveMessageC;

  PLRC.Packet -> SendPLR;
  PLRC.AMSend -> SendPLR;
  PLRC.Receive -> ReceivePLR;
  PLRC.LowPowerListening -> CC2420ActiveMessageC;

  MAC_PLRC.Packet -> SendMAC_PLR;
  MAC_PLRC.AMSend -> SendMAC_PLR;
  MAC_PLRC.Receive -> ReceiveMAC_PLR;
  MAC_PLRC.LowPowerListening -> CC2420ActiveMessageC;
  MAC_PLRC.RadioActivations -> CC2420ActiveMessageC;

  ExperimentStarterC.SendStart -> SendStart;
  ExperimentStarterC.ReceiveStart -> ReceiveStart;
  ExperimentStarterC.LowPowerListening -> CC2420ActiveMessageC;

#ifndef CTP_REPORT
  FloodingReportP.Packet -> SendStats;
  FloodingReportP.SendStats -> SendStats;
  FloodingReportP.ReceiveStats -> ReceiveStats;
  FloodingReportP.SendUART -> SerialAMSenderC;
  FloodingReportP.MessageQueue -> MessageQueue;
  FloodingReportP.TimerDequeue -> TimerDequeue;
  FloodingReportP.CC2420Packet -> CC2420ActiveMessageC;
  FloodingReportP.LowPowerListening -> CC2420ActiveMessageC;
#else
  CtpReportP.Packet -> SendStats;
  CtpReportP.SendStats -> SendStats;
  CtpReportP.ReceiveStats -> Collector.Receive[AM_STATSMSG];
  CtpReportP.SendUART -> SerialAMSenderC;
  CtpReportP.SerialPacket -> SerialAMSenderC;
  CtpReportP.MessageQueue -> MessageQueue;
  CtpReportP.TimerDequeue -> TimerDequeue;
  CtpReportP.CC2420Packet -> CC2420ActiveMessageC;
  CtpReportP.LowPowerListening -> CC2420ActiveMessageC;
#endif

  PLRC.ReadTemp -> TempHumPLR.Temperature;  
  PLRC.ReadHumidity -> TempHumPLR.Humidity;  
  PLRC.ReadVoltage -> BatteryPLR;  

  MAC_PLRC.ReadTemp -> TempHumMAC_PLR.Temperature;
  MAC_PLRC.ReadHumidity -> TempHumMAC_PLR.Humidity;
  MAC_PLRC.ReadVoltage -> BatteryMAC_PLR;

#ifndef CTP_REPORT
  FloodingReportP.Random -> RandomC;
#endif  
  MAC_PLRC.Random -> RandomC;

  PLRC.CC2420Packet -> CC2420ActiveMessageC;
  MAC_PLRC.CC2420Packet -> CC2420ActiveMessageC;
  
#ifdef PRINTF_SUPPORT
  components PrintfC;

/*   Resetter.PrintfControl -> PrintfC; */
/*   Resetter.PrintfFlush -> PrintfC; */
  ExperimentStarterC.PrintfControl -> PrintfC;
  ExperimentStarterC.PrintfFlush -> PrintfC;
  PLRC.PrintfControl -> PrintfC;
  PLRC.PrintfFlush -> PrintfC;
  MAC_PLRC.PrintfControl -> PrintfC;
  MAC_PLRC.PrintfFlush -> PrintfC;
#ifndef CTP_REPORT
  FloodingReportP.PrintfControl -> PrintfC;
  FloodingReportP.PrintfFlush -> PrintfC;
#else
  CtpReportP.PrintfControl -> PrintfC;
  CtpReportP.PrintfFlush -> PrintfC;
#endif
#endif

  ExperimentStarterC.ExperimentPLR -> PLRC;
  ExperimentStarterC.ExperimentMAC_PLR -> MAC_PLRC;
#ifndef CTP_REPORT
  PLRC.StatsReport -> FloodingReportP;
  MAC_PLRC.StatsReport -> FloodingReportP;
#else
  PLRC.StatsReport -> CtpReportP;
  MAC_PLRC.StatsReport -> CtpReportP;
#endif

#ifndef CTP_REPORT
  FloodingReportP.ResetFlooding = ResetFlooding;
#else
  CtpReportP.ResetFlooding = ResetFlooding;
#endif
}
