// maximum 1000 ms
#define RESET_PERIOD 700

module WatchdogP {
  provides interface Watchdog;
  uses interface Timer<TMilli> as ResetTimer;
  uses interface Boot;
}

implementation {

  event void Boot.booted(){
    call Watchdog.start();
  }

  command void Watchdog.start() {
    atomic WDTCTL = WDT_ARST_1000;
    call ResetTimer.startPeriodic(RESET_PERIOD);
  }

  command void Watchdog.stop() {
    call ResetTimer.stop();
    atomic WDTCTL = WDTPW + WDTHOLD;
  }

  event void ResetTimer.fired()
  {
    atomic WDTCTL = WDT_ARST_1000;
  }
}
