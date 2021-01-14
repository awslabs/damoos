#!/bin/bash

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: GPL-2.0

# This is the main runner script of damoos that interacts with the user.

if [ $# -eq 1 ] && [ "$1" == "--dry" ]
then
	DRYRUN=echo
fi

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

scheme_name=$(grep "$choice" < "$DAMOOS"/scheme_adapters.txt | grep -oh "[^ ]*$")
scheme_dir="$DAMOOS/scheme_adapters/$scheme_name"
lines=$(cat "$scheme_dir/requirements.txt")

cmd=""
if [[ "$scheme_name" == "simple_adapter" ]]
then
	for line in $lines
	do
		echo "Please enter ${line}"
		read -r arg
		args="${args} $arg"
	done
	cmd="sudo DAMOOS=\"$DAMOOS\" bash \"$scheme_dir/$scheme_name.sh\" $args"
elif [[ "$scheme_name" == "simple_rl_adapter" ]]
then
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
	cmd="sudo python3 $scheme_dir/simple_rl_adapter.py $args"

elif [[ "$scheme_name" == "polyfit_adapter" ]]
then
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
	cmd="sudo python3 $scheme_dir/polyfit_adapter.py $args"

elif [[ "$scheme_name" == "pso_adapter" ]]
then
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
	cmd="sudo python3 $scheme_dir/pso_adapter.py $args"

elif [[ "$scheme_name" == "multiD_polyfit_adapter" ]]
then
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
	cmd="sudo python3 $scheme_dir/multiD_polyfit_adapter.py $args"

fi

if [ "$cmd" == "" ]
then
	echo "Wrong scheme adapter name ($scheme_name) is given"
	exit 1
fi

if $DRYRUN script -c "$cmd" -f "$file"
then
	echo "Successfull!"
else
	echo "Please fix the mentioned error"
	exit 1
fi
