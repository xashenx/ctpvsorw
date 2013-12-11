#!/bin/bash

./make.bridge
make tmote reinstall.101 bsl,/dev/ttyUSB1
make tmote reinstall.102 bsl,/dev/ttyUSB2
make tmote reinstall.103 bsl,/dev/ttyUSB3
make tmote reinstall.104 bsl,/dev/ttyUSB4
make tmote reinstall.105 bsl,/dev/ttyUSB5
make tmote reinstall.110 bsl,/dev/ttyUSB10
make tmote reinstall.111 bsl,/dev/ttyUSB11
make tmote reinstall.112 bsl,/dev/ttyUSB12
make tmote reinstall.113 bsl,/dev/ttyUSB13

./make.wine-root
make tmote reinstall.0 bsl,/dev/ttyUSB6

./make.net
make tmote reinstall.1 bsl,/dev/ttyUSB7
make tmote reinstall.2 bsl,/dev/ttyUSB8
make tmote reinstall.3 bsl,/dev/ttyUSB9

./make.bridge-sink
make tmote reinstall.100 bsl,/dev/ttyUSB0
