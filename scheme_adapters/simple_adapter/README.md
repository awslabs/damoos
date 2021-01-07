# simple_adapter

As the name suggests this is a simple adapter that runs the given workload multiple times to find the optimal scheme based on a calculated score.

1. **simple_adapter.sh** - This script implements the main algorithm for this adapter. The algorithm involves defining a score to determine the effectiveness of the last applied scheme. The formula used is:
   
        score = (x) (Runtime_Overhead) + (1-x) (RSS_Overhead)
    
    where x = the importance given to runtime overhead and its value lies between 0 and 1. That means that if x=0 then we do not give any importance to runtime overhead and hence whichever scheme has the minimum RSS Overhead is selected as the best scheme. Similarly a value of 1 means no importance to RSS Overhead and thus whichever scheme has the minimum runtime overhead is selected. The right value of x depends on the need of the user. Based on this score the optimizations is performed in two steps:

        a)Step1 - Select the right min age value among 5s, 8s, 10s and 13s keeping the min region size constant (4KB).
        b)Step2 - Select the right min region size value by using the best min age value obtained from the Step1. (4KB, 8KB, 12KB, 16KB and 20KB)

2. **requirements.txt** - This file stores the inputs required by this scheme. It is used by the main damoos interface to ask the user for inputs.
