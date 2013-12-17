module CtpRadioSettingsP {
  provides interface CtpRadioSettings;
}

implementation {
  uint8_t power;

  command uint8_t CtpRadioSettings.getPower()
  {
    return power;
  }

  command void CtpRadioSettings.setPower(uint8_t new_power)
  {
    power = new_power;
  }
}

