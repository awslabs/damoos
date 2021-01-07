#!/bin/bash

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: GPL-2.0

# Get the direct values stored in the stat file
# Argument1 is the pid and Argument2 is the metric name

if [[ $# -ne 2 ]]
then
	echo "Usage: $0 <pid> <metric_name>"
	exit
fi

# Write code to get the average from different metric collectors using elif
if [[ "$2" == "runtime" ]]
then
	path="$DAMOOS/metrics_collector/collectors/runtime/$1.stat"
	if [[ -e $path ]]
	then
		#Nothing to be done
		:
	else
		echo "Statistics for pid $1 does not exist."
		echo "Please collect the metric first using collect_metric.sh"
		exit 1
	fi
else
	echo "Invalid metric name."
fi
