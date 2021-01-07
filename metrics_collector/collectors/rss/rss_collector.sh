#!/bin/bash

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: GPL-2.0

# Store the rss recorded for process with pid=$1 in file $1.stat every 1 second
if [[ $# -ne 1 ]]
then
	echo "Usage: $0 <pid>"
	exit 1
fi
sudo rm -f "$1".stat
while true
do
	if ps -p "$1" > /dev/null
	then
		ps -o rss "$1" | tail -1  >> "$DAMOOS"/metrics_collector/collectors/rss/"$1".stat
		sleep 1
	else
		break
	fi
done
