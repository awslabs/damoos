# simple_rl_adapter

**simple_rl_adapter** - This adapter uses Tabular Q-learning algorithm to find a best scheme by varying min_age and min_size.

**simple_adapter.sh** - The 30 states used in this adapter are:  The 30 actions correspond to {min_age:3s,5s,7s,9s,11s,13s}X{min_size:4KB,8KB,12KB,16KB,20KB}. There are number of tunables like number of runs, learning rate, epsilon and discount rate. This adapter uses the following score function:
        
        score = - (rss_overhead*0.5 + runtime_overhead*0.5)

**requirements.txt** - This file stores the inputs required by this scheme. It is used by the main damoos interface to ask the user for inputs.
