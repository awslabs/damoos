#!/bin/bash

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: GPL-2.0

# Run the workloads using command in workload directory.
# Argument1 - Workload Name, Argument2 to ArgumentN - Metric Name
# Stores the pid of the workload in results/pid file.
# Workload should be registered in the workload_directory.

if [[ $# -eq 0 ]]
then
	echo "Usage: $0 <workload name> [metric1] [metric2] ... [metricN]"
fi

workload_directory="$DAMOOS/frontend/workload_directory.txt"
command=$(grep "^$1@@@" "$workload_directory" | grep -oh "[^@@@]*$")
if ! eval "$command"
then
        echo "Unable to run the workload. Please check the corresponding command."
        exit 1
fi
workload=$(grep "^$1@@@" "$workload_directory" | grep  -oh -e '@@@.*@@@' | grep -oh -e "[^@@@]*")

pid=$(pidof "$workload")
while [[ -z $pid ]]
do
	pid=$(pidof "$workload")
	sleep 1
done

# Check if the workload is already runnning, in that case pidof may return more than one pids
if [[ $pid =~ ^[0-9]+$ ]]
then
	for (( metric=2; metric<=$#; metric++))
	do
		eval "name=\${$metric}"
		metric_directory="$DAMOOS/frontend/metric_directory.txt"
		metric_entry=$(grep "^$name-" "$metric_directory" | grep -oh "[^-]*$")
	
		if [[ "$metric_entry" == "local" ]]
		then
			DAMOOS="$DAMOOS" bash "$DAMOOS"/metrics_collector/collect_metric.sh "$name" "$pid" &
		elif [[ "$metric_entry" == "host" ]]
		then
			echo "To be implemented"
			exit 1
		else
			echo "Invalid metric name or Invalid entry in metric directory"
			exit 1
		fi	
	done
	echo "$pid" > "$DAMOOS"/results/pid

else
	echo "Multiple $workload workloads are running, please kill or wait for them to finish"
	exit 1
fi
