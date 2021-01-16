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
		adapter=$1
		log_file=$2

		wrong_scheme_name=1
		for s in $scheme_adapters
		do
			if [ "$adapter" == "$s" ]
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

adapter_dir="$DAMOOS/scheme_adapters/$adapter"
adapter_requirements=$(cat "$adapter_dir/requirements.txt")

cmd=""
if [[ "$adapter" == "simple_adapter" ]]
then
	for line in $adapter_requirements
	do
		echo "Please enter ${line}"
		read -r arg
		args="${args} $arg"
	done
	cmd="sudo DAMOOS=\"$DAMOOS\" bash \"$adapter_dir/$adapter.sh\" $args"
elif [[ "$adapter" == "simple_rl_adapter" ]]
then
	args="-p ${DAMOOS}"
	for line in $adapter_requirements
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
	cmd="sudo python3 $adapter_dir/simple_rl_adapter.py $args"

elif [[ "$adapter" == "polyfit_adapter" ]]
then
	args="-dp ${DAMOOS}"
	for line in $adapter_requirements
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
	cmd="sudo python3 $adapter_dir/polyfit_adapter.py $args"

elif [[ "$adapter" == "pso_adapter" ]]
then
	args="-dp ${DAMOOS}"
	for line in $adapter_requirements
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
	cmd="sudo python3 $adapter_dir/pso_adapter.py $args"

elif [[ "$adapter" == "multiD_polyfit_adapter" ]]
then
	args="-dp ${DAMOOS}"
	for line in $adapter_requirements
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
	cmd="sudo python3 $adapter_dir/multiD_polyfit_adapter.py $args"

fi

if [ "$cmd" == "" ]
then
	echo "something wrong!"
	exit 1
fi

if $DRYRUN script -c "$cmd" -f "$log_file"
then
	echo "Successfull!"
else
	echo "Please fix the mentioned error"
	exit 1
fi
