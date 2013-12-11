#!/bin/bash
# @author Fabrizio Zeni

# $1: identifier of the test
# $2: application period
# $3: run period
# $4: power

clear
if [ $# != 1 ]; then
	echo -e "Missing parameters!\n"
	echo -e "\t1) identifier of the test"
	echo -e "\t2) application period"
	echo -e "\t3) run period"
	echo -e "\t4) power\n"
	exit 0
fi
java -cp "netTests.jar:$TOSROOT/support/sdk/java/tinyos.jar" netTest.HistoryProcessor $1
