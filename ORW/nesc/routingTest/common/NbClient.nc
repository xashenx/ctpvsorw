interface NbClient {

  /* Updates the top three neighbors of the node */
  event void updateNb(uint16_t addr,uint8_t edc,uint8_t pos);

}
