#!/bin/bash
# @author Fabrizio Zeni

# $1: identifier of the test
# $2: application period
# $3: run period
# $4: power
# $4: sleep interval
# $5: randomized start directive

clear
if [[ $# < 5 ]]; then
	echo -e "Missing parameters!\n"
	echo -e "\t1) identifier of the test"
	echo -e "\t2) application period"
	echo -e "\t3) run period"
	echo -e "\t4) power"
	echo -e "\t5) sleep interval"
	echo -e "\t6) {DESYNCH_APP}"
	exit 0
fi

if [ $# = 5 ]; then
	java -cp "netTests.jar:$TOSROOT/support/sdk/java/tinyos.jar" netTest.LaunchTest ROUTING $1 $2 $3 $4 $5
elif [ $# = 6 ]; then
	java -cp "netTests.jar:$TOSROOT/support/sdk/java/tinyos.jar" netTest.LaunchTest ROUTING $1 $2 $3 $4 $5 $6
fi
