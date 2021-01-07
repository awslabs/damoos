#!/bin/bash

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: GPL-2.0

function get_workload_runtime()
{
	sudo DAMOOS="$DAMOOS" bash "$DAMOOS"/frontend/get_metric.sh "$1" runtime stat
	if [[ $? -ne 0 ]]
	then
		echo "Unable to get metrics. Please fix the problem mentioned above."
		exit 1
	else
		curr_runtime=$(cat "$DAMOOS/results/runtime/$1.stat")
	fi
	echo "$curr_runtime"
}

function get_workload_rss()
{
	sudo DAMOOS="$DAMOOS" bash "$DAMOOS"/frontend/get_metric.sh "$1" rss full_avg
	if [[ $? -ne 0 ]]
	then
		echo "Unable to get metrics. Please fix the problem mentioned above."
		exit 1
	else
		curr_rss=$(cat "$DAMOOS/results/rss/$1.full_avg")
	fi
	echo "$curr_rss"
}

orig_time=0
orig_rss=0

for (( j=0; j<3; ++j ))
do
	sudo DAMOOS="$DAMOOS" bash "$DAMOOS"/frontend/run_workloads.sh "$1" runtime rss
	if [[ $? -ne 0 ]]
	then
		echo "Fix the above problem."
		exit 1
	else
		pid=$(cat $DAMOOS/results/pid)
	fi
	sudo bash "$DAMOOS"/frontend/wait_for_process.sh "$pid"
	sudo DAMOOS="$DAMOOS" bash "$DAMOOS"/frontend/wait_for_metric_collector.sh "$pid" runtime rss
	curr_runtime=$(get_workload_runtime "$pid")
	curr_rss=$(get_workload_rss "$pid")
	orig_time=$(echo "scale=8; $orig_time + $curr_runtime"|bc)
	orig_rss=$(echo "scale=8; $orig_rss + $curr_rss" | bc)
done

orig_runtime=$(echo "scale=8; $orig_time / 3"|bc)
orig_rss=$(echo "scale=8; $orig_rss / 3"|bc)

echo "${orig_runtime}-${orig_rss}"
