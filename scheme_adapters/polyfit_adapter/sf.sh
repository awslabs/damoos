#!/bin/bash

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: GPL-2.0

#All metrics passed as arguments are in the same order as registered with the environment.

curr_runtime=$4
curr_rss=$2
orig_runtime=$3
orig_rss=$1

runtime_overhead=$(echo "scale = 10;($curr_runtime/$orig_runtime - 1)*100" | bc)
if (( $(echo "$runtime_overhead > 20" | bc -l) ))
then
	echo -1000
else
	rss_overhead=$(echo "scale = 10;(${curr_rss}/${orig_rss} - 1)*100" | bc)
	reward=$(echo "scale = 10;- ${runtime_overhead}*0.5 - ${rss_overhead}*0.5" | bc)
	echo "$reward"
fi
