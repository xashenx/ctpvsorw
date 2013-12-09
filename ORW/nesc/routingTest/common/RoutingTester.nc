interface RoutingTester {

  /* Starts the routing */
  command void startRouting();

  /* Stops the routing */
  command void stopRouting();

  /* Sets the node as root of the collection tree */
  //command void setRoot();

  /* Activates the application task */
  command void activateTask(bool randomize_start,
                            uint32_t taskPeriod, 
                            uint32_t taskOperatingPeriods);

  /* Sets the power that is used for transmitting messages */
  command void setPower(uint8_t newPower);
}
