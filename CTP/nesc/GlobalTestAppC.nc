configuration GlobalTestAppC {
}

implementation {
  components PLRAppC;
  components TestAppC;
  //components WatchdogC;

  TestAppC.ResetFlooding -> PLRAppC.ResetFlooding;

}
