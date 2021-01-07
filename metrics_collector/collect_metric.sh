#!/bin/bash

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: GPL-2.0

# This script calls the respective metrics collector based on argument1 ($1) and for pid $2

if [[ $# -ne 2 ]]
then
	echo "There should be exactly two arguments in the following format:"
	echo "Usage: $0 <metric_name> <pid>"
	exit
fi

# Add new elif condition to add new metric collectors
if [[ "$1" == "rss" ]]
then
	sudo DAMOOS="$DAMOOS" bash "$DAMOOS"/metrics_collector/collectors/rss/rss_collector.sh "$2" &
elif [[ "$1" == "swapout" ]]
then
	sudo DAMOOS="$DAMOOS" bash "$DAMOOS"/metrics_collector/collectors/swapout/swapout_collector.sh "$2" &
elif [[ "$1" == "swapin" ]]
then
	sudo DAMOOS="$DAMOOS" bash "$DAMOOS"/metrics_collector/collectors/swapin/swapin_collector.sh "$2" &
elif [[ "$1" == "runtime" ]]
then
	sudo DAMOOS="$DAMOOS" bash "$DAMOOS"/metrics_collector/collectors/runtime/runtime_collector.sh "$2" &
else
	echo "Invalid metric name"
fi
