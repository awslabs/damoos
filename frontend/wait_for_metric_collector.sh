#!/bin/bash

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: GPL-2.0

# Wait for metric collectors to write into the .stat file

for (( metric=2; metric<=$#; metric++))
do
	eval "name=\${$metric}"
	while [ ! -f "$DAMOOS/metrics_collector/collectors/$name/$1.stat" ]
	do
		sleep "0.5"
	done
done
