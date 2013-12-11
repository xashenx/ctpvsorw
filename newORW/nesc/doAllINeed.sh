#!/bin/bash

./make.sink
make tmote reinstall.0 bsl,/dev/ttyUSB0
./make.net
declare -i i
i=-1
for file in /dev/ttyUSB*
do
  i+=1
done

if [ $i -gt 9 ]
     then
     i=9
fi

for x in $(seq 1 $i)
do
  echo "--> Programming node ${x}"
  make tmote reinstall.${x} bsl,/dev/ttyUSB${x}
done

# while [ 19 -gt $i ]; do
#   i+=1
#   echo "Put node $i in /dev/ttyUSB$x and press enter"
#   read
#   make tmote reinstall.${i} bsl,/dev/ttyUSB${x}
# done
