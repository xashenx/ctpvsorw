#include <Timer.h>
#include "PLR.h"
#include <UserButton.h>

#ifdef PRINTF_SUPPORT
#include "printf.h"
#endif

#define HALF_MINUTE 30000

module Resetter {

  uses {
    interface Boot;
    interface Leds;
    interface Alarm<TMilli,uint16_t> as AlarmReset;

#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {

  uint32_t localtime = 0;

  void netprog_reboot() {
    WDTCTL = WDT_ARST_1_9; 
    while(1);
  }

  event void Boot.booted() {
    call AlarmReset.start(HALF_MINUTE);
  }

  task void resetTask() {

    static bool reset = FALSE;
    localtime++;
    
    if (reset) {
      netprog_reboot(); 
    }

    if (localtime/2 == RESET_TIME) {
      call Leds.set(7);
      reset = TRUE;

#ifdef PRINTF_SUPPORT
      printf("to RST\n");
#endif
    }

#ifdef PRINTF_SUPPORT
    call PrintfFlush.flush();
#endif

  }

  async event void AlarmReset.fired() {
    post resetTask();
    call AlarmReset.start(HALF_MINUTE);
  }

#ifdef PRINTF_SUPPORT
  event void PrintfControl.startDone(error_t error) {
  }

  event void PrintfControl.stopDone(error_t error) {
  }

  event void PrintfFlush.flushDone(error_t error) {
  }
#endif

}
