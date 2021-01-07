#!/bin/bash

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: GPL-2.0

# Cleanup the resources created by metric collectors

# Cleanup local metrics collectors
sudo DAMOOS="$DAMOOS" bash "$DAMOOS"/metrics_collector/cleanup.sh

# Cleanup remote metrics collectors - TODO

# Cleanup results directory for local metric collectors
metrics=$(tail -n +2 $DAMOOS/frontend/metric_directory.txt | sed '1s|-local||g')
for metric in $metrics
do
	sudo rm -f "$DAMOOS"/results/"$metric"/*
done
