#!/bin/bash
# @author Fabrizio Zeni

# $1: first identifier
# $2: last identifier
# $3: name of the experiment
clear
if [[ $# < 2 ]]; then
	echo -e "Missing parameters!\n"
	echo -e "\t1) first identifier"
	echo -e "\t2) last identifier"
	echo -e "\t3) name of the experiment"
	exit 0
fi

first=$1
last=$2
name=$3
for((i=$first;i<$((last+1));i++)); do
		fileToParse=$(ls logs | grep msg-$i-)
		#./parsing.sh logs/$fileToParse $name
		./parsing.sh logs/$fileToParse
done
#mv logs/$name* logs/runs/
