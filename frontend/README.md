#Frontend

Front-end provides an interface for the scheme adapters to interact with the metric collectors. Since metric collectors may be running on the host or locally, the scheme adapters need not worry about it and front-end would manage this.

1. **metric_directory.txt** - This file stores a list of metrics and whether they need to be run locally or on the host. This file should be updated whenever a new metric is added. Format is <metric-name>-<local|host>
2. **run_workloads.sh** - This script does two things, run the corresponding workload (name passed as an argument, the workload name and command to run it should be registered with the workload directory) and invoke the metric collectors corresponding to the list of metric names passed as argument. After doing these two things, it will write the pid of the currently running workload in a file named “pid” in the results directory. Both the workload and the metric collector run in the background and this script immediately returns so that the scheme_adapters can get the pid and start applying the DAMON schemes.
3. **get_metric.sh** - This script is used by the scheme adapters to get the collected metric (usually something like the average or difference of the collected metric). It determines whether the metric is a local one or not and will call the corresponding script to get the data. The final results obtained are stored in the results directory inside the directory with the name of the metric. It also accepts the statistic name which can be diff, partial_avg, avg or stat.
4. **wait_for_metric_collector.sh** - This script waits till the .stat files corresponding to the metric names (2nd to last argument) passed are created for the pid (the 1st arguments.) It serves as a synchronization mechanism to know when the metric collectors have finished and written the values in the .stat files.
5. **wait_for_process.sh** - This script simply waits till the process with the given pid is running.
6. **cleanup.sh** - This script will call the cleanup scripts for local and remote metric collectors and also cleanup the files in the results directory.

