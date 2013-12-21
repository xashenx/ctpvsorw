module OppRadioSettingsP {
  provides interface OppRadioSettings;
}

implementation {
  uint8_t power;

  command uint8_t OppRadioSettings.getPower()
  {
    return power;
  }

  command void OppRadioSettings.setPower(uint8_t new_power)
  {
    power = new_power;
  }
}

