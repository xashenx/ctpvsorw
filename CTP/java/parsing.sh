#!/bin/bash
# @author Fabrizio Zeni

# $1: bin file to parse

clear
if [ $# != 1 ]; then
	echo -e "Missing parameters!\n"
	echo -e "\t1) binary file to parse"
	exit 0
fi
java -cp "netTests.jar:$TOSROOT/support/sdk/java/tinyos.jar" netTest.HistoryProcessor $1
tail -n 25 logs/results.txt
exit 0
