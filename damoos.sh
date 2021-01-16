#!/bin/bash

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: GPL-2.0

# This is the main runner script of damoos that interacts with the user.

DAMOOS=$(dirname "$0")

scheme_adapters=$(ls "$DAMOOS/scheme_adapters")

function pr_usage {
	echo "Usage: $0 [OPTION]... <scheme adapter> <log file>"
	echo
	echo "OPTION"
	echo "  --dry		Do nothing but show how it will work"
	echo "  -h, --help	Show this usage"
	echo
	echo "Supported <scheme adapter>s are:"
	for s in $scheme_adapters
	do
		echo "  $s"
	done
	echo
}

if [ $# -lt 1 ]
then
	pr_usage
	exit 1
fi

while [ $# -ne 0 ]; do
	case $1 in
	"--dry")
		DRYRUN=echo
		shift 1
		continue
		;;
	"--help" | "-h")
		pr_usage
		exit 0
		;;
	*)
		if [ $# -ne 2 ]
		then
			pr_usage
			exit 1
		fi
		scheme_name=$1
		file=$2

		wrong_scheme_name=1
		for s in $scheme_adapters
		do
			if [ "$scheme_name" == "$s" ]
			then
				wrong_scheme_name=0
				break
			fi
		done
		if [ "$wrong_scheme_name" -eq 1 ]
		then
			pr_usage
			exit 1
		fi

		break
		;;
	esac
done

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
