THIS REPO IS DEPRECATED
=======================

This repo (https://github.com/awslabs/damoos) was one of the official GitHub
repos for damo.  However, after 2024-09-05, this has been[1] no longer the
official GitHub repo.  Please use the new official GitHub repo
(https://github.com/damonitor/damoos) instead.

[1] https://lore.kernel.org/20240813232158.83903-1-sj@kernel.org

---

DAMOOS (DAMON-based Optimal Operation Schemes)
==============================================

[DAMON](https://damonitor.github.io) allows users to do data access
monitoring-based memory-management optimizations with no code but simple
[scheme](https://damonitor.github.io/doc/html/next/admin-guide/mm/damon/usage.html?highlight=damos#damon-based-operation-schemes).

This project aims to automate the process of choosing right schemes for a
workload-system pair.

Overview
--------

DAMOOS stands for DAMon-based Optimal Operation Schemes and it is built to help
the users to find the best DAMON scheme automatically. As the scheme depends
both on the workload and the system characteristics, finding a good scheme
manually is difficult. DAMOOS currently supports simple scheme adapter, simple
RL Adapter, Polynomial Fit Adapter, Multi Dimension Polynomial Fit Adapter and
Particle Swarm Optimization based adapter and in the future would also support
more scheme adapters that the users can try out.

Prerequisites
-------------

To understand DAMOOS and the need for it, having a basic understanding of DAMON
and DAMON-based Operation Schemes (DAMOS) is required. Please read the
documentation about them here:
https://damonitor.github.io/doc/html/next/admin-guide/mm/damon/index.html

Quick Start
-----------

If you are only a user of DAMOOS, then the interactive `damoos.sh` script is
all that you need to know about. If you are interested in writing your own
scheme adapters or tweaking some of the code, please read the details of DAMOOS
in the different subdirectories.

You need a DAMON-enabled kernel to try out DAMOOS. You also need to register
your workload in the `frontend/workload_directory.txt` in the following format:

ShortName@@@NameforPID@@@Command

Here, ShortName is the name of the workload that you will be using with DAMOOS.
NameforPID is the name of the process using which DAMOOS can get the process's
PID (Just use the top command to find the name under the command column).
Command is used to run the workload, it should ideally use an absolute path and
put the process in background so that DAMOOS can apply the different schemes to
it.

Below is a small example of using the `simple_adapter` for a parsec3 workload
named “dedup” and record the log in `damoos_log` file.

```
$ sudo bash damoos.sh simple_adapter damoos_log
Please enter Workload_Name(E.g:dedup,canneal,etc.)
dedup
Please enter Runtime_Importance_Score(E.g:"0.3")
0.4
Please enter Lazybox_Path(E.g:"/home/user/laxybox")
/home/dev4/lazybox
Script started, file is dedup_best_scheme.txt
 Optimizing dedup workload..
```

`damoos.sh` receives name of the adapter to use and name of a file to record
the log as command line arguments.  Then, it will ask you to enter the inputs
required by the chosen scheme adapter.

Here is another example for `polyfit_adapter`:
```
$ sudo bash damoos.sh polyfit_adapter damoos_log
Please enter 1.Lazybox_Path(-lb)
/home/dev4/lazybox
Please enter 2.DAMOS_Path(-dm)
/home/dev4/linux/tools/damon/damo
Please enter 3.JSON_Path(-jp)
splash2x.barnes.json
Please enter 4.Pickle_File_Path(-pfn)

Script started, file is splash2x.barnes_best_scheme.txt
Optimizing splash2x.barnes...
```

DAMOOS Components
-----------------

For more information about the implementation details of DAMOOS, read the
following README files:

1. [Front-end](frontend/README.md)
2. [Metric Collectors](metrics_collector/README.md)
3. Scheme Adapters
   
    a) [Simple Adapter](scheme_adapters/simple_adapter/README.md)
    
    b) [Simple RL Adapter](scheme_adapters/simple_rl_adapter/README.md)

    c) [PolyFit Adapter](scheme_adapters/polyfit_adapter/README.md)
    
    d) [PSO Adapter](scheme_adapters/pso_adapter/README.md)

    e) [Multi Dimension Polyfit Adapter](scheme_adapters/multiD_polyfit_adapter/README.md)


Contact Details
---------------

Madhuparna Bhowmik (madhuparnabhowmik04@gmail.com)

SeongJae Park (sjpark@amazon.com)
