#!/bin/bash

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: GPL-2.0

# Get the average of the values stored in the stat file
# Argument1 is the pid and Argument2 is the metric name
# Argument3 is the number of last collected metric to be considered

if [[ $# -ne 3 ]]
then
	echo "Usage: $0 <pid> <metric_name> <number_of_last_entries>"
	exit
fi

# Write code to get the average from different metric collectors using elif
if [[ "$2" == "rss" ]]
then
	path="$DAMOOS/metrics_collector/collectors/rss/$1.stat"
	if [[ -e $path ]]
	then
		lines=$(cat "$path" | tail -$3)
		count=0
		sum=0
		for l in $lines
		do
			sum=$(echo "scale=8; $sum + $l"|bc)
			count=$(echo "scale=8; $count + 1" | bc)
		done
		avg=$(echo "scale=8; $sum/$count" | bc)
		echo "$avg" > "$DAMOOS/metrics_collector/collectors/rss/$1.avg"
	else
		echo "Statistics for pid $1 does not exist."
		echo "Please collect the metric first using collect_metric.sh"
		exit 1
	fi
else
	echo "Invalid metric name."
fi
