#!/bin/bash

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: GPL-2.0

# Get the results from collected metrics either from local or remote metric collectors
# Argument1 - pid, Argument2 - Metric Name, Argument3 - Statistic Name (full_avg, partial_avg etc.)

if [[ $# -ne 3 ]] && [[ $# -ne 4 ]]
then
	echo "Usage: $0 <pid> <metric> <stat_name>"
	echo "If stat name is partial_avg, also provide the number of last entries to be considered."
	echo "Metrics:"
	cat "$DAMOOS/frontend/metric_directory.txt"
	exit 1
fi

metric_directory="$DAMOOS/frontend/metric_directory.txt"
metric_entry=$(grep "^$2-" "$metric_directory" | grep -oh "[^-]*$")

if [[ "$metric_entry" == "local" ]]
then
	if [[ "$3" == "full_avg" ]]
	then
		sudo DAMOOS="$DAMOOS" bash "$DAMOOS"/metrics_collector/get_avg_stat.sh "$1" "$2"
		if [[ $? -ne 0 ]]
		then
			exit 1
		else
			mv "$DAMOOS/metrics_collector/collectors/$2/$1.avg"  "$DAMOOS/results/$2/$1.$3"
		fi
	elif [[ "$3" == "partial_avg" ]]
	then
		sudo DAMOOS="$DAMOOS" bash "$DAMOOS"/metrics_collector/get_partial_avg_stat.sh "$1" "$2" "$4"
		if [[ $? -ne 0 ]]
		then
			exit 1
		else
			mv "$DAMOOS/metrics_collector/collectors/$2/$1.avg"  "$DAMOOS/results/$2/$1.$3"
		fi
	elif [[ "$3" == "diff" ]]
	then
		sudo DAMOOS="$DAMOOS" bash "$DAMOOS"/metrics_collector/get_diff_stat.sh "$1" "$2"
		if [[ $? -ne 0 ]]
		then
			exit 1
		else
			mv "$DAMOOS/metrics_collector/collectors/$2/$1.diff"  "$DAMOOS/results/$2/$1.$3"
		fi
	elif [[ "$3" == "stat" ]]
	then
		sudo DAMOOS="$DAMOOS" bash "$DAMOOS"/metrics_collector/get_stat.sh "$1" "$2"
		if [[ $? -ne 0 ]]
		then
			exit 1
		else
			mv "$DAMOOS/metrics_collector/collectors/$2/$1.stat"  "$DAMOOS/results/$2/$1.$3"
		fi
	fi

elif [[ "$metric_entry" == "host" ]]
then
	echo "To be implemented"
	exit 1
else
	echo "Invalid metric name or Invalid entry in metrics directory"
	exit 1
fi
