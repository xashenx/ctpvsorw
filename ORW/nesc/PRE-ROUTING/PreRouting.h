#ifndef PLR_H
#define PLR_H

enum {
  AM_START_MSG = 7,
  AM_RESULT_MSG = 12,
  AM_CONFIG_MSG = 14,
};

enum {
  // Estimates the minimum time (in ms) for 
  // the radio to send a message
  MIN_SEND_PACKET_TIME = 10, 
  SINK_NODE_ID = 0,
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

#endif
