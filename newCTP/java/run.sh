#!/bin/bash

java -cp "netTests.jar:$TOSROOT/support/sdk/java/tinyos.jar" netTest.LaunchTest PURE_PLR 7 10 22 1000
