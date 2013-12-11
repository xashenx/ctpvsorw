configuration WatchdogC {
  provides interface Watchdog;
}

implementation {
  components WatchdogP, MainC;
  components new TimerMilliC() as ResetTimer;

  WatchdogP.Boot -> MainC;
  WatchdogP.ResetTimer -> ResetTimer;
  Watchdog = WatchdogP.Watchdog;
}
