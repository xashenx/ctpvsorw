/*
 * @author Fabrizio Zeni
 */
 
 interface NbInfo{
	/* asks for a refresh of the actual 3 top nb */
	command void getActualNeighbors();
	
	/* return the number of parents seen */
	command uint8_t getNeighborsSeen();
	
	/* return the actual number of neighbors */
	command uint8_t getNeighborsNo();
	
	/* Updates the top three neighbors of the node */
	event void updateNb(uint16_t addr,uint8_t edc,uint8_t pos);

} 
