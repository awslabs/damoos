# pso_adapter

**pso_adapter** - Uses particle swarm optimization to find the optimal scheme. This is a generic adapter and can tune from 1-6 parameters in one go.

**pso_adapter.sh** - The entire search space is divided based on the number of runs allowed by the user. Then the search space is explored with random points uniformly distributed in the space for each dimenion. An approximation of a point is used by using the score value of its nearest neighbour based on euclidean distance and these values are used by the PSO Adapter. This is not accurate and hence in the future we will employ better techniques for approximating the function.

**requirements.txt** - This file stores the inputs required by this scheme. It is used by the main damoos interface to ask the user for inputs.
