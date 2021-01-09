#!/bin/bash

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: GPL-2.0

# This is the main runner script of damoos that interacts with the user.

DAMOOS=$(dirname "$0")

echo "Choose DAMOOS Scheme Adapter:"
cat "$DAMOOS"/scheme_adapters.txt
read -r choice

max_choice=$(wc -l < "scheme_adapters.txt")
if [ "$choice" -gt "$max_choice" ] || [ "$choice" -lt "1" ]
then
	echo "Wrong choice.  It should be a number in [1, $max_choice]"
	exit 1
fi

echo "Enter the log file name:"
read -r file

if [[ "$choice" -eq "1" ]]
then
	scheme_name=$(grep "$choice" < "$DAMOOS"/scheme_adapters.txt | grep -oh "[^ ]*$")
	lines=$(cat "$DAMOOS"/scheme_adapters/"$scheme_name"/requirements.txt)
	for line in $lines
	do
		echo "Please enter ${line}"
		read -r arg
		args="${args} $arg"
	done
	script -c "sudo DAMOOS="$DAMOOS" bash "$DAMOOS"/scheme_adapters/"$scheme_name"/"$scheme_name".sh $args" -f $file
	if [[ $? -eq 0 ]]
	then
		echo "Successfull!"
	else
		echo "Please fix the mentioned error"
		exit 1
	fi
elif [[ "$choice" -eq "2" ]]
then
	scheme_name=$(grep "$choice" < "$DAMOOS"/scheme_adapters.txt | grep -oh "[^ ]*$")
	lines=$(cat "$DAMOOS"/scheme_adapters/"$scheme_name"/requirements.txt)
	args="-p ${DAMOOS}"
	for line in $lines
	do
		echo "Please enter ${line}"
		read -r arg
		
		if [[ "$arg" == "$NL" ]]
		then
			continue
		elif [[ $line == *"-lb"* ]]
		then
			args="${args} -lb $arg"
		elif [[ $line == *"-w"* ]]
		then
			args="${args} -w $arg"
		elif [[ $line == *"-n"* ]]
		then
			args="${args} -n $arg"
		elif [[ $line == *"-lr"* ]]
		then
			args="${args} -lr $arg"
		elif [[ $line == *"-dm"* ]]
		then
			args="${args} -dm $arg"
		elif [[ $line == *"-e"* ]]
		then
			args="${args} -e $arg"
		elif [[ $line == *"-d"* ]]
		then
			args="${args} -d $arg"
		fi
	done
	script -c "sudo python3 $DAMOOS/scheme_adapters/simple_rl_adapter/simple_rl_adapter.py $args" -f $file
	if [[ $? -eq 0 ]]
	then
		echo "Successfull!"
	else
		echo "Please fix the mentioned error"
		exit 1
	fi

elif [[ "$choice" -eq "3" ]]
then
	scheme_name=$(grep "$choice" < "$DAMOOS"/scheme_adapters.txt | grep -oh "[^ ]*$")
	lines=$(cat "$DAMOOS"/scheme_adapters/"$scheme_name"/requirements.txt)
	args="-dp ${DAMOOS}"
	for line in $lines
	do
		echo "Please enter ${line}"
		read -r arg
		
		if [[ "$arg" == "$NL" ]]
		then
			continue
		elif [[ $line == *"-lb"* ]]
		then
			args="${args} -lb $arg"
		elif [[ $line == *"-dm"* ]]
		then
			args="${args} -dm $arg"
		elif [[ $line == *"-jp"* ]]
		then
			args="${args} -jp $arg"
		elif [[ $line == *"-pfn"* ]]
		then
			args="${args} -pfn $arg"
		fi
	done
	script -c "sudo python3 $DAMOOS/scheme_adapters/polyfit_adapter/polyfit_adapter.py $args" -f $file
	if [[ $? -eq 0 ]]
	then
		echo "Successfull!"
	else
		echo "Please fix the mentioned error"
		exit 1
	fi

elif [[ "$choice" -eq "4" ]]
then
	scheme_name=$(grep "$choice" < "$DAMOOS"/scheme_adapters.txt | grep -oh "[^ ]*$")
	lines=$(cat "$DAMOOS"/scheme_adapters/"$scheme_name"/requirements.txt)
	args="-dp ${DAMOOS}"
	for line in $lines
	do
		echo "Please enter ${line}"
		read -r arg
		
		if [[ "$arg" == "$NL" ]]
		then
			continue
		elif [[ $line == *"-lb"* ]]
		then
			args="${args} -lb $arg"
		elif [[ $line == *"-dm"* ]]
		then
			args="${args} -dm $arg"
		elif [[ $line == *"-jp"* ]]
		then
			args="${args} -jp $arg"
		fi
	done
	script -c "sudo python3 $DAMOOS/scheme_adapters/pso_adapter/pso_adapter.py $args" -f $file
	if [[ $? -eq 0 ]]
	then
		echo "Successfull!"
	else
		echo "Please fix the mentioned error"
		exit 1
	fi
fi
