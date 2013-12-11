interface Experiment {
  
  command void start(uint16_t expId,
		     uint16_t numberPackets, 
		     uint16_t interval, 
		     uint8_t channel,
/* 		     uint8_t power, */
		     uint16_t sender,
		     uint16_t lplCheckInterval);
}

