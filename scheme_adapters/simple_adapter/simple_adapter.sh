#!/bin/bash

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: GPL-2.0

# Simple Scheme Adapter runs the given workload multiple times in two steps:
# Step1 - Keeping region size constant, vary min age value in the scheme.
# Use the best min age value for step 2.
# Step2 - Keeping the age value constant, vary the min region size.
# Declare the Best Scheme with minimum score.
# x = Importance given to runtime.
# score = x * runtime_overhead + (1-x) * rss_overhead

if [[ $# -ne 3 ]]
then
	echo "Usage: $0 <workload name> <Importance weight>"
	exit 1
fi

min_score=10000000000
min_scheme_name=0
best_runtime=10000000000
best_rss=10000000000
min_size=0
LAZYBOX=$3

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

aggr_interval=$(sudo cat /sys/kernel/debug/damon/attrs | awk -F ' ' '{print $2}')
max_region_size=18446744073709551615
max_age=4294967295

orig_time=0
orig_rss=0
echo " Optimizing $1 workload.."
echo "Running workload without scheme.."

for (( j=0; j<5; ++j ))
do
	sudo DAMOOS="$DAMOOS" bash "$DAMOOS"/frontend/run_workloads.sh "$1" runtime rss
	if [[ $? -ne 0 ]]
	then
		echo "Fix the above problem."
		exit 1
	else
		pid=$(cat "$DAMOOS"/results/pid)
	fi
	sudo bash "$DAMOOS"/frontend/wait_for_process.sh "$pid"
	sudo DAMOOS="$DAMOOS" bash "$DAMOOS"/frontend/wait_for_metric_collector.sh "$pid" runtime rss
	curr_runtime=$(get_workload_runtime "$pid")
	curr_rss=$(get_workload_rss "$pid")

	echo "$curr_runtime"
	echo "$curr_rss"
	orig_time=$(echo "scale=8; $orig_time + $curr_runtime"|bc)
	orig_rss=$(echo "scale=8; $orig_rss + $curr_rss" | bc)
done

orig_runtime=$(echo "scale=8; $orig_time / 5"|bc)
orig_rss=$(echo "scale=8; $orig_rss / 5"|bc)

echo "Average Original Runtime ${orig_runtime}"
echo "Average Original RSS ${orig_rss}"

# Enable zram
sudo "$LAZYBOX"/scripts/zram_swap.sh 4G

for i in 5 8 10 13
do
	runtime_sum=0
	rss_sum=0
	echo "Scheme with minimum age ${i} running..."
	min_age=$(echo "($i * 1000000)/$aggr_interval" | bc)
	echo "$min_age"
	for (( j=0; j<5; ++j))
	do
		sudo DAMOOS="$DAMOOS" bash "$DAMOOS"/frontend/run_workloads.sh "$1" runtime rss
		if [[ $? -ne 0 ]]
		then
			echo "Fix the above problem."
			exit 1
		else
			pid=$(cat "$DAMOOS"/results/pid)
		fi
		monitor_status=$(sudo cat "/sys/kernel/debug/damon/monitor_on")
		if [[ "$monitor_status" == "on" ]]
		then
			echo "DAMON Monitoring is already on, please switch off monitoring to run this adapter"
			exit 1
		else
			sudo echo "$pid" > "/sys/kernel/debug/damon/target_ids"
        		sudo echo "4096 ${max_region_size}    0 0    ${min_age} ${max_age}   2" > "/sys/kernel/debug/damon/schemes"
			sudo echo "on" > "/sys/kernel/debug/damon/monitor_on"
		fi
		sudo bash "$DAMOOS"/frontend/wait_for_process.sh "$pid"
		sudo DAMOOS="$DAMOOS" bash "$DAMOOS"/frontend/wait_for_metric_collector.sh "$pid" runtime rss
		curr_runtime=$(get_workload_runtime "$pid")
		curr_rss=$(get_workload_rss "$pid")
		echo "$curr_runtime"
		echo "$curr_rss"

		runtime_sum=$(echo "scale=8; $runtime_sum + $curr_runtime" | bc)
		rss_sum=$(echo "scale=8; $rss_sum + $curr_rss" | bc)
	done

	avg_runtime=$(echo "scale=8; $runtime_sum / 5" | bc)
	avg_rss=$(echo "scale=8; $rss_sum / 5" | bc)

	runtime_overhead=$(echo "scale=8; (($avg_runtime - $orig_runtime)/ $orig_runtime)*100" | bc)
	rss_overhead=$(echo "scale=8; (($avg_rss - $orig_rss)/ $orig_rss)*100" | bc)
	
	echo "Runtime Overhead: ${runtime_overhead}"
	echo "RSS Overhead: ${rss_overhead}"
	temp=$(echo "scale=8; 1 - $2" | bc)
	score=$(echo "scale=8; ($runtime_overhead * $2) + ($rss_overhead * $temp)" | bc)
	if (( $(echo "$score < $min_score" | bc -l) ))
	then
		min_score=$score
		min_scheme_name=$i
		min_size=4096
		best_rss=$avg_rss
		best_runtime=$avg_runtime
		best_min_age=$min_age
	fi
	echo "Score: ${score}"
done

echo "Minimum Score obtained for minimum age value of: ${min_scheme_name}"

for i in 4096 8192 12288 16384 20480
do
	runtime_sum=0
	rss_sum=0
        min_age=$(echo "($i * 1000000)/$aggr_interval" | bc)
	echo "$min_age"
	echo "Scheme with minimum region size ${i} running..."

	for (( j=0; j<5; ++j))
	do
		sudo DAMOOS="$DAMOOS" bash "$DAMOOS"/frontend/run_workloads.sh "$1" runtime rss
		if [[ $? -ne 0 ]]
		then
			echo "Fix the above problem."
			exit 1
		else
			pid=$(cat "$DAMOOS"/results/pid)
		fi
		monitor_status=$(sudo cat "/sys/kernel/debug/damon/monitor_on")
		if [[ "$monitor_status" == "on" ]]
		then
			echo "DAMON Monitoring is already on, please switch off monitoring to run this adapter"
			exit 1
		else
			sudo echo "$pid" > "/sys/kernel/debug/damon/target_ids"
        		sudo echo "${i} ${max_region_size}  0 0    ${best_min_age} ${max_age}    2" > "/sys/kernel/debug/damon/schemes"
			sudo echo "on" > "/sys/kernel/debug/damon/monitor_on"
		fi
		sudo bash "$DAMOOS"/frontend/wait_for_process.sh "$pid"
		sudo DAMOOS="$DAMOOS" bash "$DAMOOS"/frontend/wait_for_metric_collector.sh "$pid" runtime rss
		curr_runtime=$(get_workload_runtime "$pid")
		curr_rss=$(get_workload_rss "$pid")
		echo "$curr_runtime"
		echo "$curr_rss"
		runtime_sum=$(echo "scale=8; $runtime_sum + $curr_runtime" | bc)
		rss_sum=$(echo "scale=8; $rss_sum + $curr_rss" | bc)
	done

	avg_runtime=$(echo "scale=8; $runtime_sum / 5" | bc)
	avg_rss=$(echo "scale=8; $rss_sum / 5" | bc)

	runtime_overhead=$(echo "scale=8; (($avg_runtime - $orig_runtime)/ $orig_runtime)*100" | bc)
	rss_overhead=$(echo "scale=8; (($avg_rss - $orig_rss)/ $orig_rss)*100" | bc)
	
	echo "Runtime Overhead ${runtime_overhead}"
	echo "RSS Overhead ${rss_overhead}"
	temp=$(echo "scale=8; 1 - $2" | bc)
	score=$(echo "scale=8; ($runtime_overhead * $2) + ($rss_overhead * $temp)" | bc)
	if (( $(echo "$score < $min_score" | bc -l) ))
	then
		min_score=$score
		min_scheme_name=$min_scheme_name
		min_size=$i
		best_rss=$avg_rss
		best_runtime=$avg_runtime
	fi
	echo "Score: ${score}"
done

runtime_overhead=$(echo "scale=8; (($best_runtime - $orig_runtime)/ $orig_runtime)*100" | bc)
rss_overhead=$(echo "scale=8; (($best_rss - $orig_rss)/ $orig_rss)*100" | bc)
echo "Runtime Overhead: ${runtime_overhead}"
echo "RSS Overhead: ${rss_overhead}"
echo "Best Scheme:"
echo "${min_size} ${max_region_size} 0 0 ${best_min_age} ${max_age} pageout"
sudo DAMOOS="$DAMOOS" bash "$DAMOOS"/frontend/cleanup.sh
