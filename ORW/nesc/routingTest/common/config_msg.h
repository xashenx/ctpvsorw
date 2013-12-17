#ifndef __CONFIG_MSG_H
#define __CONFIG_MSG_H

enum {
  AM_CONFIG_MSG = 14,
  AM_REPORT_MSG = 15
};

typedef nx_struct config_msg {
  nx_uint16_t seq_no;
  nx_uint16_t app_period;
  nx_uint16_t wait_period;
  nx_uint16_t routing_boot_period;
  nx_uint16_t run_period;
  nx_uint16_t stop_period;
  nx_uint8_t power;
  nx_bool randomize_start;
} config_msg_t;


#endif
