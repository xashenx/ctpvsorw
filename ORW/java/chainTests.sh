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
#power=27 		# starting power
sleepI=2048 		# starting sleeping interval
appP=4			# application period
runsPath=logs/runs  	# path to the logs of the runs
################################################################
clear
if [[ $# < 4 || ( $4 != "SAME" && $4 != "AUTO" && $4 != "DUAL" ) ]]; then
	echo -e "Missing parameters!"
	echo -e "\t1) identifier of the run"
	echo -e "\t2) length of the tests (seconds)"
	echo -e "\t3) first test identifier"
	echo -e "\t4) execution mode [AUTO or SAME or DUAL]"
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
	echo -e "\t4) execution mode [AUTO or SAME or DUAL]"
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
if [[ $4 = "SAME" || $4 = "DUAL" ]]; then
	echo -e "\tNUMBER OF TESTS: $5\n"
fi
read -p "Press any key to continue..."

if [ ! -d "$runsPath" ]; then
	mkdir -p $runsPath
fi

if [ -e "logs/results.txt" ]; then
	mv logs/results.txt logs/resultback.txt
fi

if [ -e "logs/global.txt" ]; then
	mv logs/global.txt logs/globalback.txt
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
		sleep 10
		echo "PARSING logs/$fileToParse"
		echo -e "\nPARSING $fileToParse\n" >> $runsPath/run_$1.txt
		./parsing.sh logs/$fileToParse >> $runsPath/run_$1.txt
		sleep 10 
		test=$((test+1))
	done
fi

if [ $4 = "AUTO" ]; then
	## FIRST LOOP OVER POWER, SECOND LOOP OVER SLEEP INTERVAL
	testId=$3
	testNr=0
	#for ((i=0;i<3;i++)); do
	for ((i=0;i<1;i++)); do
		##SETTING POWER
		if [ $i = 1 ]; then
			power=17
		elif [ $i = 2 ]; then
			power=14
		elif [ $i = 3 ]; then
			power=7
		fi
		#for((j=0;j<7;j++)); do
		for((j=0;j<5;j++)); do
			#SETTING SLEEP
			if [[ $j > 0 && $j < 5 ]]; then
				appP=$((appP*2))
				#sleepI=$((sleepI*2))
			#elif [ $j = 4 ]; then
			#	sleepI=8192
			#elif [ $j = 5 ]; then
			#	sleepI=14336
			#elif [ $j = 6 ]; then
			#	sleepI=15360
			#else
			#	sleepI=1024
			fi
			echo "RUNNING TEST $testNr (id: $testId)"
			if [ $i = 0 ]; then
				echo -e "TEST $testNr\n" >> $runsPath/run_$1.txt
			else
				echo -e "\nTEST $testNr\n" >> $runsPath/run_$1.txt
			fi
			echo -e "routing $testId $appP $2 $power $sleepI RANDOM_INTERVAL"
			./routing.sh $testId $appP $2 $power $sleepI RANDOM_INTERVAL >> $runsPath/run_$1.txt
			fileToParse=$(ls logs | grep msg-$testId-)
			sleep 10
			echo "PARSING $fileToParse"
			echo -e "\nPARSING $fileToParse\n" >> $runsPath/run_$1.txt
			./parsing.sh logs/$fileToParse>> $runsPath/run_$1.txt
			testNr=$((testNr+1))
			testId=$((testId+1))
			sleep 10
		done
	done
fi

if [ $4 = "DUAL" ]; then
	testId=$3
	echo "RUNNING TEST 0 (id: $testId)"
	if [ $i = 0 ]; then
		echo -e "TEST 0\n" >> $runsPath/run_$1.txt
	else
		echo -e "\nTEST 0\n" >> $runsPath/run_$1.txt
	fi
	echo -e "routing $testId $appP $2 $power $sleepI"
	./routing.sh $testId $appP $2 $power $sleepI >> $runsPath/run_$1.txt
	fileToParse=$(ls logs | grep msg-$testId-)
	echo "PARSING $fileToParse"
	echo -e "\nPARSING $fileToParse\n" >> $runsPath/run_$1.txt
	./parsing.sh logs/$fileToParse>> $runsPath/run_$1.txt
	testId=$((testId+1))

	echo "RUNNING TEST 2 (id: $testId)"
	if [ $i = 0 ]; then
		echo -e "TEST 1\n" >> $runsPath/run_$1.txt
	else
		echo -e "\nTEST 1\n" >> $runsPath/run_$1.txt
	fi
	echo -e "routing $testId $appP $2 $power $sleepI"
	./routing.sh $testId $appP $2 $power $sleepI >> $runsPath/run_$1.txt
	fileToParse=$(ls logs | grep msg-$testId-)
	echo "PARSING $fileToParse"
	echo -e "\nPARSING $fileToParse\n" >> $runsPath/run_$1.txt
	./parsing.sh logs/$fileToParse>> $runsPath/run_$1.txt
fi

cp logs/results.txt /home/ashen/Dropbox/Tesi\ Magistrale/results/results_$1.txt
cp $runsPath/run_$1.txt /home/ashen/Dropbox/Tesi\ Magistrale/results/
mv logs/results.txt logs/runs/results_$1.txt
mv logs/global.txt logs/runs/global_$1.txt

exit 0
