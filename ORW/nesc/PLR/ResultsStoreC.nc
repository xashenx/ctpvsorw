#include "PLR.h"

module ResultsStoreC {
  provides interface ResultsStore;
}

implementation {

  // Storing experiment results
  uint32_t rx_packets_stats[NR_NODES];
  uint32_t rx_packets_lqi[NR_NODES];
  uint32_t rx_packets_rssi[NR_NODES];

  command void ResultsStore.clear(){
    uint8_t i;
    for(i=0; i<NR_NODES; i++) {
      rx_packets_stats[i]=0;
      rx_packets_lqi[i]=0;
      rx_packets_rssi[i]=0;
    }
  }

  command void ResultsStore.incrStats(uint16_t id, uint16_t incr){
    rx_packets_stats[id] += (uint32_t) incr;
  }
  
  command void ResultsStore.incrLqi(uint16_t id, uint16_t incr){
    rx_packets_lqi[id] += (uint32_t) incr;
  }

  command void ResultsStore.incrRssi(uint16_t id, uint16_t incr){
    rx_packets_rssi[id] += (uint32_t) incr;
  }

  command uint32_t ResultsStore.getStats(uint16_t id){
    return rx_packets_stats[id];
  }

  command uint32_t ResultsStore.getLqi(uint16_t id){
    return rx_packets_lqi[id];
  }

  command uint32_t ResultsStore.getRssi(uint16_t id){
    return rx_packets_rssi[id];
  }
}
