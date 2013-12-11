#ifndef PLR_H
#define PLR_H

enum {
  AM_PLRMSG = 6,
  AM_STARTMSG = 7,
  AM_STATSMSG = 8,
  AM_MAC_PLRMSG = 9,
};

// Experiment types
enum {
  PURE_PLR = 0,
  MAC_PLR = 1,
  LPL_PLR = 2,
};

enum {
  // Estimates the minimum time (in ms) for 
  // the radio to send a message
  MIN_SEND_PACKET_TIME = 10, 
  SINK_NODE_ID = 1,
  //SINK_NODE_ID = 0,
};

enum {
  NR_NODES = 5,
  PAYLOAD_LENGTH = 94, // Must be equal to the value in Makefile
  REPORT_DELAY_WINDOW = 1200U,
  UART_INTERVAL = 1000,
  CTP_BOOTSTRAP = 5000ULL,
  QUEUE_SIZE = 20,
};

enum {
  REPORT_RETRY_INTERVAL = 60000U,
  MAX_STATS_RETX = 2, //10, // Max number of retransmission of stats
  RX_SIZE = 16, //(PAYLOAD_LENGTH - 24)/4,
};

enum {
  // Expressed in number of 30 secs rounds - 2880 corresponds to 24h 
  RESET_TIME = 2880,
};

typedef nx_struct PLRMsg {
  nx_uint16_t seqn;
  nx_uint16_t nodeid;
  nx_uint16_t packet_seqn;
  nx_uint8_t payload[PAYLOAD_LENGTH - 6];
} PLRMsg;

typedef nx_struct StartMsg {
  nx_uint8_t type;
  nx_uint16_t seqn;
  nx_uint16_t nPackets;
  nx_uint16_t interval;
  nx_uint16_t expSender;
  nx_uint16_t lplCheckInterval;
  nx_uint8_t channel;
/*   nx_uint8_t power; */
} StartMsg;

typedef nx_struct StatsMsg {
  nx_uint16_t experimentId;
  nx_uint16_t seqn;
  nx_uint16_t nodeid;
  nx_uint16_t expSender;
  nx_uint16_t rx_packets[RX_SIZE];
  nx_uint8_t rx_rssi[RX_SIZE];
  nx_uint8_t rx_lqi[RX_SIZE];
  nx_uint16_t avgTemperature;
  nx_uint16_t avgHumidity;
  nx_uint16_t initBattery;
  nx_uint16_t endBattery;
} StatsMsg;

#endif
