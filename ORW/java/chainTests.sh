#!/bin/bash
# @author Fabrizio Zeni
#
# used to run consecutive tests
#
# $1: identifier of the run
# $2: number of test to perform
# $3: length of the tests
# $4: first test indentifier
# $5: test mode [either AUTO or SAME]
#
#
############# DEFINED PARAMETERS FOR THE TESTS #################
runningP=600 	# each test will run for such period of time (s)
power=27 	# starting power
sleepI=2048 	# starting sleeping interval
################################################################
clear
if [[ $# < 4 || ( $4 != "SAME" && $4 != "AUTO" ) ]]; then
	echo -e "Missing parameters!"
	echo -e "\t1) identifier of the run"
	echo -e "\t2) length of the tests (seconds)"
	echo -e "\t3) first test identifier"
	echo -e "\t4) execution mode [AUTO or SAME]"
	echo -e "\t5) {number of test to be performed} only if in SAME mode"
	echo -e "\nMODE can be:"
	echo -e "\t- AUTO to perform a chain of test in which power and sleep are changed by the script"
	echo -e "\t- SAME to perform the same test a given number of times" 
	exit 0
elif [[ $4 = "SAME" && $# < 5 ]]; then
	echo -e "SAME MODE requires the fifth parameter!"
	echo -e "USAGE:"
	echo -e "\t1) identifier of the run"
	echo -e "\t2) length of the tests (seconds)"
	echo -e "\t3) first test identifier"
	echo -e "\t4) execution mode [AUTO or SAME]"
	echo -e "\t5) {number of test to be performed} only if in SAME mode"
	echo -e "\nMODE can be:"
	echo -e "\t- AUTO to perform a chain of test in which power and sleep are changed by the script"
	echo -e "\t- SAME to perform the same test a given number of times" 
	exit 0
elif [ -e "run_$1.txt" ]; then
	echo -e "\t\t\t\tERROR!\n"
	echo -e "a run with that identifier has already been performed!\n"
	echo -e "look at it in logs/runs/run_$1.txt\n"
	exit 0
fi

if [ $4 = "SAME" ]; then
	echo -e "You are going to perform $5 tests of length $2 and initial identifier $3 in $4 mode\n"
else
	echo -e "You are going to perform DEFINE_THE_NUMBER_OF_TESTS tests of length $2 and initial identifier $3 in $4 mode\n"
fi
read -p "Press any key to continue..."

if [ ! -d "logs/runs" ]; then
	mkdir -p logs/runs
fi
## START OF THE TESTS LOOP

if [ $4 = "SAME" ]; then
	test=$4
	for ((i=0;i<$2;i++)); do
		echo "RUNNING TEST $i (id: $test)"
		if [ $i = 0 ]; then
			echo -e "TEST $i\n" >> run_$1.txt
		else
			echo -e "\nTEST $i\n" >> run_$1.txt
		fi
		echo -e "routing $test 15 $runningP $power $sleepI"
		./routing.sh $test 15 $runningP $power $sleepI >> run_$1.txt
		sleep 2
		#ls logs/msg-$i | grep msg-$(test)
		echo "PARSING TEST $i"
		echo -e "\nPARSING TEST $i\n" >> run_$1.txt
		./parsing.sh >> run_$1.txt
		sleep 2 
		test=$((test+1))
	done
fi

if [ $4 = "AUTO" ]; then
	for ((i=0;i<$2;i++)); do
		echo "RUNNING TEST $i (id: $test)"
		if [ $i = 0 ]; then
			echo -e "TEST $i\n" >> run_$1.txt
		else
			echo -e "\nTEST $i\n" >> run_$1.txt
		fi
		echo -e "routing $test 15 $runningP $power $sleepI"
		./routing.sh $test 15 $runningP $power $sleepI >> run_$1.txt
		sleep 2
		#ls logs/msg-$i | grep msg-$(test)
		echo "PARSING TEST $i"
		echo -e "\nPARSING TEST $i\n" >> run_$1.txt
		./parsing.sh >> run_$1.txt
		sleep 2 
	done
fi

exit 0
