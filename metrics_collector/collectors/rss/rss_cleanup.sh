#!/bin/bash

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: GPL-2.0

# Cleanup the files storing statistics for different processes
sudo rm -f "$DAMOOS"/metrics_collector/collectors/rss/*.stat
