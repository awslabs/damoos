# Collectors

This directory contains folders corresponding to the individual metric collectors.


1. **rss** - This is the metric collector for collecting the residential set size of a given pid.
    
    rss_collector.sh - This script simply collects the value of rss every 1 second using ps -o rss <pid> and store the results in the same folder with the name <pid>.stat.
    
    rss_cleanup.sh - Simply delete all the <pid>.stat file when invoked.
2. **runtime** - Collects the runtime of a process with pid passed as argument.
    
    runtime_collector.sh - Waits for the given pid and writes the amount of time waited to <pid>.stat file.
    
    runtime_cleanup.sh - Deletes the <pid>.stat files.
3. **swapin** - Collects the number of swap ins in the system while a process is running.
    
    swapin_collector.sh - Every 1 sec logs the number of swapins to <pid>.stat file
    
    swapin_cleanup.sh - Deletes the <pid>.stat files.
4. **swapout** - Collects the number of swap outs in the system while a process is running.
    
    swapout_collector.sh - Every 1 sec logs the number of swapouts to <pid>.stat file
    
    swapout_cleanup.sh - Deletes the <pid>.stat files.

