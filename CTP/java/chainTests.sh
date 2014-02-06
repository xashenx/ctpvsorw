#!/bin/bash
# @author Fabrizio Zeni
#
# used to run consecutive tests
#
# $1: identifier of the run
# $2: length of the tests
# $3: first test indentifier
# $4: test mode [either AUTO or SAME]
# $5: number of test to perform
#
#
############# DEFINED PARAMETERS FOR THE TESTS #################
power=27 		# starting power
sleepI=2048 		# starting sleeping interval
runsPath=logs/runs  	# path to the logs of the runs
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
elif [ -e "logs/runs/run_$1.txt" ]; then
	echo -e "\t\t\t\tERROR!\n"
	echo -e "a run with that identifier has already been performed!\n"
	echo -e "look at it in logs/runs/run_$1.txt\n"
	exit 0
fi

echo -e "You are going to perform some test with these parameters:\n"
echo -e "\tRUN ID: $1"
echo -e "\tLENGTH OF EACH TEST: $2"
echo -e "\tFIRST TEST ID: $3"
echo -e "\tMODE: $4"
if [ $4 = "SAME" ]; then
	echo -e "\tNUMBER OF TESTS: $5\n"
fi
read -p "Press any key to continue..."

if [ ! -d "$runsPath" ]; then
	mkdir -p $runsPath
fi
## START OF THE TESTS LOOP

if [ $4 = "SAME" ]; then
	test=$3
	for ((i=0;i<$5;i++)); do
		echo "RUNNING TEST $i (id: $test)"
		if [ $i = 0 ]; then
			echo -e "TEST $i\n" >> $runsPath/run_$1.txt
		else
			echo -e "\nTEST $i\n" >> $runsPath/run_$1.txt
		fi
		echo -e "routing $test 15 $2 $power $sleepI"
		./routing.sh $test 15 $2 $power $sleepI >> $runsPath/run_$1.txt
		fileToParse=$(ls logs | grep msg-$test-)
		echo "PARSING logs/$fileToParse"
		echo -e "\nPARSING $fileToParse\n" >> $runsPath/run_$1.txt
		./parsing.sh logs/$fileToParse >> $runsPath/run_$1.txt
		#sleep 2 
		test=$((test+1))
	done
fi

if [ $4 = "AUTO" ]; then
	## FIRST LOOP OVER POWER, SECOND LOOP OVER SLEEP INTERVAL
	testId=$3
	testNr=0
	for ((i=0;i<3;i++)); do
		##SETTING POWER
		if [ $i = 1 ]; then
			power=17
		elif [ $i = 2 ]; then
			power=14
		elif [ $i = 3 ]; then
			power=7
		fi
		for((j=0;j<7;j++)); do
			#SETTING SLEEP
			if [[ $j > 0 && $j < 4 ]]; then
				sleepI=$((sleepI+1024))
			elif [ $j = 4 ]; then
				sleepI=8192
			elif [ $j = 5 ]; then
				sleepI=14336
			elif [ $j = 6 ]; then
				sleepI=15360
			else
				sleepI=1024
			fi
			echo "RUNNING TEST $testNr (id: $testId)"
			if [ $i = 0 ]; then
				echo -e "TEST $testNr\n" >> $runsPath/run_$1.txt
			else
				echo -e "\nTEST $testNr\n" >> $runsPath/run_$1.txt
			fi
			echo -e "routing $testId 15 $2 $power $sleepI"
			./routing.sh $testId 15 $2 $power $sleepI >> $runsPath/run_$1.txt
			fileToParse=$(ls logs | grep msg-$testId-)
			echo "PARSING $fileToParse"
			echo -e "\nPARSING $fileToParse\n" >> $runsPath/run_$1.txt
			./parsing.sh logs/$fileToParse>> $runsPath/run_$1.txt
			testNr=$((testNr+1))
			testId=$((testId+1))
		done
	done
fi



exit 0
