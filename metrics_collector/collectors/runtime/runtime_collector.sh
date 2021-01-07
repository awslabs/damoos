#!/bin/bash

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: GPL-2.0

# Store the runtime recorded for a process with pid=$1 in file $1.stat
if [[ $# -ne 1 ]]
then
	echo "Usage: $0 <pid>"
	exit 1
fi
sudo rm -f "$1".stat

pid=$1
TIMEFORMAT=%R
exec 3>&1 4>&2
curr_runtime=$({ time tail --pid=$pid -f /dev/null 1>&3 2>&4; } 2>&1)
exec 3>&- 4>&-
echo $curr_runtime > $DAMOOS/metrics_collector/collectors/runtime/$1.stat
