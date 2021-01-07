# Metric Collectors

This directory stores the main scripts used to interact with the individual metric collectors and the collectors directory containing the individual metric collectors.


1. **collect_metric.sh** - This script takes two arguments <metric_name> and <pid> and invokes the collector script corresponding to the metric to collect stats for the given pid. (Note: This script is for local metric collectors i.e the ones running in the same machine. The support for getting the metric from the host machine is not yet implemented.)
2. **get_avg_stat.sh** - This script can be used to calculate the average of any file containing a list of numbers. Thus, this script can be used to get the average from the metrics collected by any metric collector. Since the stats for each pid is stored separately, the arguments required are <pid> and <metric_name>. Currently the script only supports rss metric collector as other collectors do not need the avg statistic yet.
3. **get_partial_avg_stat.sh** - This script works the same as get_avg_stat.sh and only has implementation for rss metric collector. The only difference is that instead of returning the average of all the entries in a file, it returns average of only last few entries which can be specified using the 3rd argument.
4. **get_diff_stat.sh** - This script returns the difference between first and last collected metric values. It is useful for collectors like swapin and swapout.
5. **get_stat.sh** - Simply returns the collected statistic.
6. **cleanup.sh**- This script will call the individual cleanup scripts for all the metric collectors.

More information about individual metric [collectors](collectors/README.md).
