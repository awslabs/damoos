#!/usr/bin/env python

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: GPL-2.0

import random
import numpy as np
import subprocess
import time
import argparse
import os

class System:
    def __init__(self, damoos_path, lazybox_path, damos_path, workload):
        # Run the workload 3 times to get the original rss and runtime
        self.path = damoos_path
        self.workload = workload
        self.damos_path = damos_path
        print("Finding original runtime and rss of " + self.workload)
        res = subprocess.check_output(["sudo", "DAMOOS=" + self.path, "bash", self.path + "/scheme_adapters/simple_rl_adapter/run_orig.sh", self.workload])
        res = str(res)
        self.orig_runtime = float(res.split("-")[0].split("'")[1])
        self.orig_rss = float(res.split("-")[1].split("\\")[0])
        print("orig runtime", self.orig_runtime)
        print("orig rss", self.orig_rss)
        self.pid=0

        # Enable zram for further optimizations
        subprocess.call(["sudo", "bash", lazybox_path + "/scripts/zram_swap.sh", "4G"])
    
    def reset(self):
        # Run workload and get the pid
        ret = subprocess.call(["sudo", "DAMOOS=" + self.path, "bash", self.path + "/frontend/run_workloads.sh", self.workload, "runtime", "rss"])
        if ret==0:
            self.pid = open(self.path + "/results/pid").readline()
            self.pid = self.pid.strip()
        return np.array(0)

    def get_action(self, action):
        div = action/6
        rem = action%6
        action1 = 4*div + 4
        action2 = 2*rem + 3
        return int(action1), int(action2)

    def step(self,action):
        action1, action2 = self.get_action(action)
        scheme = str(action1) + "K \t max \t 0 \t 0 \t" + str(action2) + "s \t max \t pageout" 
        file_name = self.path + "/scheme_adapters/simple_rl_adapter/scheme"
        scheme_file = open(file_name, "w")
        scheme_file.write(scheme)
        scheme_file.close()
        subprocess.Popen(["sudo", "python3", self.damos_path, "schemes", "--schemes", file_name, self.pid])
        subprocess.call(["sudo", "DAMOOS=" + self.path, "bash", self.path + "/frontend/wait_for_process.sh", self.pid])
        subprocess.call(["sudo", "DAMOOS=" + self.path, "bash", self.path + "/frontend/wait_for_metric_collector.sh", self.pid, "runtime", "rss"])

        subprocess.call(["sudo", "DAMOOS=" + self.path, "bash", self.path + "/frontend/get_metric.sh", self.pid, "runtime", "stat"])
        fil1 = open(self.path + "/results/runtime/" + str(self.pid) + ".stat", "r")
        runtime = float(str(fil1.readlines()).split("'")[1][0:-2])
        print("runtime", runtime)
        runtime_overhead = ((runtime - self.orig_runtime)/self.orig_runtime)*100
        print("runtime_overhead", runtime_overhead)

        subprocess.call(["sudo", "DAMOOS=" + self.path, "bash", self.path + "/frontend/get_metric.sh", self.pid, "rss", "full_avg"])
        fil1 = open(self.path + "/results/rss/" + str(self.pid) + ".full_avg", "r")
        rss = float(str(fil1.readlines()).split("'")[1][0:-2])
        print("rss", rss)
        rss_overhead=((rss - self.orig_rss)/self.orig_rss)*100
        print("rss_overhead", rss_overhead)

        score = -((rss_overhead)*0.5 + (runtime_overhead)*0.5)
        print("score", score)
        subprocess.call(["sudo", "DAMOOS=" + self.path, "bash", self.path + "/frontend/cleanup.sh"])
        return np.array(score),np.array(int(rss_overhead)),True

def state_to_index(state):
    if state > 0:
        return 20
    return int(-(state/5))

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("-p", "--path", required=True, help="DAMOOS path")
    parser.add_argument("-lb", "--lazybox_path", required=True, help="Lazybox path")
    parser.add_argument("-w", "--workload", required=True, help="Workload name.")
    parser.add_argument("-n", "--num_iterations", required=False, help="Number of Iterations.")
    parser.add_argument("-lr", "--learning_rate", required=False, help="Learning Rate.")
    parser.add_argument("-e", "--epsilon", required=False, help="Epsilon.")
    parser.add_argument("-d", "--discount", required=False, help="Discount rate")
    parser.add_argument("-dm", "--damos_path", required=True, help="DAMOS Path")
    args = vars(parser.parse_args())

    path = args["path"]
    lazybox_path = args["lazybox_path"]
    workload = args["workload"]
    damos_path = args["damos_path"]
    
    if args["num_iterations"]:
        numiters = int(args["num_iterations"])
    else:
        numiters = 50

    if args["learning_rate"]:
        alpha = float(args["learning_rate"])
    else:
        alpha = 0.2

    if args["epsilon"]:
        epsilon = float(args["epsilon"])
    else:
        epsilon = 0.2

    if args["discount"]:
        discount = float(args["discount"])
    else:
        discount = 0.9

    ''' 
    The 21 states correspond to rss overhead of 0%:-4%, -5%:-9%, -10%:-14%.....-95%:-99%, >0%.
    100% reduction in rss is not possible as that will indicate a new rss of 0!
    '''
    num_states=21

    '''
    The 30 actions correspond to {min_age:3s,5s,7s,9s,11s,13s}X{min_size:4KB,8KB,12KB, 16KB, 20KB}
    '''
    num_actions=30

    # Initialize the Q-Table.
    Qvalue=np.random.rand(num_states,num_actions)

    # Initialize the System Environment
    system = System(path,lazybox_path, damos_path, workload)

    for i in range(numiters):
        state=system.reset()
        rew=0
        done=False
        while not done:
            randomnum = random.uniform(0,1)
            action=0
            if randomnum>=epsilon:
                lst=Qvalue[state_to_index(state)]
                action=lst.argmax(axis=0)
            else:
                action=random.randint(0,num_actions-1)

            reward,nextstate,done = system.step(action)
            if done:
                print(str(i)+". Reward", reward)
            rew=rew+reward
            nxtlist=Qvalue[state_to_index(nextstate)]
            currval=Qvalue[state_to_index(state)][action]
            Qvalue[state_to_index(state)][action-1] = currval +  alpha * (reward + discount*(max(nxtlist)) - currval)
            state=nextstate

    # Save the Q-values in a file
    if not os.path.exists(path + "/results/simple_rl"):
        os.makedirs(path + "/results/simple_rl")
    np.savetxt(path + "/results/simple_rl" + "/qvalue-"+workload+".txt", Qvalue, fmt='%f')

    # Evaluate
    avg_rew=0
    for i in range(5):
        state = system.reset()
        done=False
        while not done:
            action=Qvalue[state_to_index(state)].argmax(axis=0)
            reward, nextstate, done = system.step(action)
            if done:
                avg_rew = avg_rew + reward
                print("Final Evaluation "+str(i)+" reward = ",reward)
            state = nextstate
    print("Average Reward", avg_rew/5)

if __name__=='__main__':
    main()
