#!/bin/bash
# @author Fabrizio Zeni

# $1: bin file to parse

clear
if [[ $# != 1 &&  $# != 2 ]]; then
	echo -e "Missing parameters!\n"
	echo -e "\t1) binary file to parse"
	exit 0
fi

if [ $# = 1 ]; then 
	java -cp "netTests.jar:$TOSROOT/support/sdk/java/tinyos.jar" netTest.HistoryProcessor $1
else
	java -cp "netTests.jar:$TOSROOT/support/sdk/java/tinyos.jar" netTest.HistoryProcessor $1 $2
fi
tail -n 29 logs/results.txt
exit 0
