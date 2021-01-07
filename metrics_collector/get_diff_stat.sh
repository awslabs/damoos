#!/bin/bash

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: GPL-2.0

# Get the difference between the first and last values stored in the stat file
# Argument1 is the pid and Argument2 is the metric name

if [[ $# -ne 2 ]]
then
	echo "Usage: $0 <pid> <metric_name>"
	exit
fi

# Write code to get the difference from different metric collectors using elif
if [[ "$2" == "swapin" ]]
then
	path="$DAMOOS/metrics_collector/collectors/swapin/$1.stat"
	if [[ -e $path ]]
	then
		last=$(tail -n 1 "$path")
		first=$(head -n 1 "$path" )
		swapin=$( echo "$last - $first" | bc)
		echo "$swapin" > "$DAMOOS/metrics_collector/collectors/swapin/$1.diff"
	else
		echo "Statistics for pid $1 does not exist."
		echo "Please collect the metric first using collect_metric.sh"
		exit 1
	fi
elif [[ "$2" == "swapout" ]]
then
	path="$DAMOOS/metrics_collector/collectors/swapout/$1.stat"
	if [[ -e $path ]]
	then
		last=$(tail -n 1 "$path")
		first=$(head -n 1 "$path" )
		swapout=$( echo "$last - $first" | bc)
		echo "$swapout" > "$DAMOOS/metrics_collector/collectors/swapout/$1.diff"
	else
		echo "Statistics for pid $1 does not exist."
		echo "Please collect the metric first using collect_metric.sh"
		exit 1
	fi


else
	echo "Invalid metric name."
fi
