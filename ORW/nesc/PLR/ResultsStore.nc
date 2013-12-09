interface ResultsStore {
  command void clear();
  command void incrStats(uint16_t id, uint16_t incr);  
  command void incrLqi(uint16_t id, uint16_t incr);
  command void incrRssi(uint16_t id, uint16_t incr);
  command uint32_t getStats(uint16_t id);
  command uint32_t getLqi(uint16_t id);
  command uint32_t getRssi(uint16_t id); 
}
