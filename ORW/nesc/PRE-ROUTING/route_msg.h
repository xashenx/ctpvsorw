 #ifndef __ROUTE_MSG_H
 #define __ROUTE_MSG_H

enum{
	MAX_PARENTS = 3,
	AM_DATA_MSG = 13,
};

typedef nx_struct parent {
	nx_uint16_t addr;
	nx_uint16_t etx;
	nx_uint16_t periods; // number of application ticks
	nx_uint16_t subunits; // decimals
} parent_t;

typedef nx_struct routing_info {
	nx_uint16_t node_addr;
	nx_uint16_t seq_no;
	// network overhead statistics
	nx_uint16_t ack_received;
	nx_uint16_t beacons;
	// acks that were not received; = no of retransmissions
	nx_uint16_t ack_failed; 
	// dropped packets
	nx_uint16_t tx_queue_full;
	nx_uint16_t dropped_duplicates;
	nx_uint16_t parents_seen;
	nx_uint16_t parents_no;
	nx_uint16_t forwarded;
	nx_uint16_t dcIdle;
	nx_uint16_t dcData;
	parent_t parents[MAX_PARENTS];
} routing_info_t;

typedef nx_struct data_msg {
	nx_uint16_t temperature;
	nx_uint16_t humidity;
	nx_uint16_t voltage;
	routing_info_t routing_data;
} data_msg_t;

typedef nx_struct result_msg {
  nx_uint32_t rep_seq_no;
  data_msg_t data_msg;
} result_msg_t;


#endif
