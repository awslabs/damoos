# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: GPL-2.0

import numpy as np
import json
import argparse
import subprocess
import time
import random
import re
import math
import pyswarms as ps
from cache import Cache
from pyswarms.utils.functions import single_obj as fx

class PSO:
    def __init__(self, damoos_path, lazybox_path, damos_path, json_path):
        self.orig_metric_values = []
        self.metrics = []
        self.workload = ""
        self.workload_info = []
        self.score_func_path = ""
        self.scores = []
        self.ranges = dict()
        self.num_runs = 0
        self.total_runtime = 0
        self.num_dim = 0
        self.cache_file = ""
        self.cache_instance = None
        self.cache_read_enabled = False
        self.cache_write_enabled = True
        self.cache_option = "check" 
        self.search_param = dict()
        self.workload_metrics = dict()
        self.damoos_path = damoos_path
        self.lazybox_path = lazybox_path
        self.damos_path = damos_path
        self.json_path = json_path
        self.conversion_factor = {"us" : 1, "ms" : 1000, "s" : 1000000, "m" : 60000000, "h" : 3600000000, "d" : 86400000000,
                                   "B" : 1, "K": 1024, "M": 1048576, "G": "1073741824", "T": 1099511627776}
        self.params = ["min_size", "max_size", "min_freq", "max_freq", "min_age", "max_age"]
        
    def validate_json_list(self, json_list):
        if isinstance(json_list, list):
            for el in self.metrics:
                if type(el) != str:
                    raise Exception("List elements should be of type string.")
        else:
            raise Exception("Invalid type. List is expected.")

    def validate_json_string(self, json_string):
        if type(json_string) != str:
            raise Exception("String expected.")

    def parse_json(self, file_name):
        file = open(self.damoos_path + "/scheme_adapters/pso_adapter/json_files/" + file_name, "r")
        json_parsed = json.load(file)

        self.num_dim = json_parsed["num_dimension"]
        if type(self.num_dim) != int:
            raise Exception("Integer expected.")

        self.metrics = json_parsed["metrics"]
        self.validate_json_list(self.metrics)

        self.workload = json_parsed["workload"]
        self.validate_json_string(self.workload)

        self.score_func_path = json_parsed["score_function"]
        self.validate_json_string(self.score_func_path)

        self.ranges = json_parsed["range"]
        if not isinstance(self.ranges, dict):
            raise Exception("Dictionary expected.")

        count = 0
        for key, value in self.ranges.items():
            if isinstance(value, list):
                if key == "action":
                    raise Exception("Action is a non-tunable parameter. Please specify only one action.")
                else:
                    count += 1
                    if count > self.num_dim:
                        raise Exception("Number of dimensions and number of ranges given does not match.")

        self.num_runs = json_parsed["num_runs"]
        if type(self.num_runs) != int:
            raise Exception("Integer expected.")

        self.total_runtime = json_parsed["total_runtime"]
        if type(self.total_runtime) != int:
            raise Exception("Integer expected.")

        self.cache_read_enabled = json_parsed["read_from_cache"]
        if type(self.cache_read_enabled) != bool:
            raise Exception("Boolean expected")

        self.cache_write_enabled = json_parsed["write_to_cache"]
        if type(self.cache_write_enabled) != bool:
            raise Exception("Boolean expected")

        self.cache_option = json_parsed["cache_option"]
        self.validate_json_string(self.cache_option)

        self.cache_file = json_parsed["cache_file"]
        self.validate_json_string(self.cache_file)

    def run_workload(self):
        command = ["sudo", "DAMOOS=" + self.damoos_path, "bash", self.damoos_path + "/frontend/run_workloads.sh", self.workload]
        for metric in self.metrics:
            command.append(metric.split(";")[0])
        ret = subprocess.call(command)
        if ret==0:
            pid = open(self.damoos_path + "/results/pid").readline()
            pid = pid.strip()
            return pid
        else:
            raise Exception("Unable to run the workload")

    def get_metric(self, pid, metric_list):
        subprocess.call(["sudo", "bash", self.damoos_path + "/frontend/wait_for_process.sh", str(pid)])
        wait_command = ["sudo", "DAMOOS=" + self.damoos_path, "bash", self.damoos_path + "/frontend/wait_for_metric_collector.sh", str(pid)]
        for metric in metric_list:
            name = metric.split(";")[0]
            wait_command.append(name)
        subprocess.call(wait_command)
        workload_metrics = dict()
        for metric in metric_list:
            name = metric.split(";")[0]
            collect_type = metric.split(";")[1]
            subprocess.call(["sudo", "DAMOOS=" + self.damoos_path, "bash", self.damoos_path + "/frontend/get_metric.sh", str(pid), name, collect_type])
            fil1 = open(self.damoos_path + "/results/" + name + "/" + str(pid) + "." + collect_type, "r")
            result = float(str(fil1.readlines()).split("'")[1][0:-2])
            workload_metrics[name] = result
        return workload_metrics

    def run_orig(self):
            pid = self.run_workload()
            if pid == 0:
                self.workload_info.append(self.get_stat())
            temp_list = self.metrics[:]
            if "runtime;stat" not in temp_list:
                temp_list.append("runtime;stat")
            self.workload_info.append(self.get_metric(pid, temp_list))

    def convert(self, value):
        if type(value) == int:
            return value
        try:
            return(int(value))
        except:
            pass

        if value == "max" or value == "min":
            return value

        unit = " ".join(re.findall("[a-zA-Z]+", value))
        num = int(" ".join(re.findall("[0-9]+", value)))
        return self.conversion_factor[unit]*num

    def find_key_dim(self, num_runs, key_range_list):
        curr_dim = self.num_dim
        curr_left = num_runs
        key_dim = []
        ind = 0
        while curr_dim > 0:
            key_dim.append(min(key_range_list[ind], int(curr_left**(1/float(curr_dim)))))
            curr_left = int(curr_left/key_dim[-1])
            curr_dim -= 1
            ind += 1 
        return key_dim


    def generate_search_param(self):
        num = self.total_runtime / self.workload_info[0]["runtime"]
        self.num_runs = max(2**self.num_dim, min(self.num_runs, num))

        key_range_list = []
        for key, value in self.ranges.items():
            if isinstance(value, list):
                range_diff = self.convert(value[1]) - self.convert(value[0])
                key_range_list.append(range_diff + 1)

        key_dim = self.find_key_dim(self.num_runs, key_range_list)
        key_index = 0
        for key, value in self.ranges.items():
            if isinstance(value, list):
                range_diff = self.convert(value[1]) - self.convert(value[0])
                num_runs = key_dim[key_index]
                key_index += 1
                num_runs = min(num_runs, range_diff+1)
                num_regions = max(1, int(num_runs / 5))
                region_size = int(range_diff/num_regions)
                self.search_param[key] = [self.convert(value[0])]
                num_left = num_runs - (num_regions + 1)
                num_samples = int(num_left/ num_regions)
                remainder = num_left % num_regions
                for i in range(num_regions):
                    self.search_param[key].append((i+1)*region_size)
                    numbers = num_samples + (1 if i < remainder else 0)
                    random_list = random.sample(range((i*region_size)+1, (i+1)*region_size), numbers)
                    self.search_param[key] += random_list
            else:
                self.search_param[key] = [value]
        for key, value in self.search_param.items():
            value.sort()
            print(key,value)

    def collect_data(self):
        subprocess.call(["sudo", "bash", self.lazybox_path + "/scripts/zram_swap.sh", "4G"])
        index_dict = dict()
        for key, value in self.search_param.items():
            index_dict[key] = [0, len(value)]
        store_metrics = []

        action = self.search_param["action"][0]

        for min_size in self.search_param["min_size"]:
            for max_size in self.search_param["max_size"]:
                for min_freq in self.search_param["min_freq"]:
                    for max_freq in self.search_param["max_freq"]:
                        for min_age in self.search_param["min_age"]:
                            for max_age in self.search_param["max_age"]:
                                scheme_list = [min_size, max_size, min_freq, max_freq, min_age, max_age]
                                
                                if self.cache_read_enabled:
                                    stored_value = self.cache_instance.get(scheme_list + [action])
                                    if stored_value != -1:
                                        store_metrics.append((stored_value[1], scheme_list))
                                        continue

                                if type(min_size) == int:
                                    min_size = str(min_size) + "B"
                                if type(max_age) == int:
                                    max_age = str(max_age) + "us"
                                if type(max_size) == int:
                                    max_size = str(max_size) + "B"
                                if type(min_age) == int:
                                    min_age = str(min_age) + "us"
                                scheme = min_size + "\t" + max_size + "\t"
                                scheme += str(min_freq) + "\t" + str(max_freq) + "\t"
                                scheme += min_age + "\t" + max_age + "\t" + action
                                file_name = self.damoos_path + "/scheme_adapters/pso_adapter/scheme" 
                                scheme_file = open(file_name, "w")
                                scheme_file.write(scheme)
                                scheme_file.close()
                                pid = self.run_workload()
                                subprocess.Popen(["sudo", "python3", self.damos_path, "schemes", "--schemes", file_name, str(pid)])    
                                collected_metric = self.get_metric(pid, self.metrics)
                                store_metrics.append((collected_metric, scheme_list))

                                if self.cache_write_enabled:
                                    self.cache_instance.store(scheme_list + [action], collected_metric)

        self.workload_info.append(store_metrics)

    def collect_score(self):
        for value in self.workload_info[1]:
            command = ["bash", self.damoos_path + "/scheme_adapters/pso_adapter/" + self.score_func_path]
            for metric in self.metrics:
                name = metric.split(";")[0]
                command.append(str(self.workload_info[0][name]))
                command.append(str(value[0][name]))
            res = subprocess.check_output(command)
            score =  str(res).split("'")[1][0:-2]
            print("Score:" + score )
            self.scores.append((float(score), value[1]))
    
    def run_best_workload(self, scheme):
        new_scheme = ""
        ind = 0
        for key in self.params:
            if scheme[ind] < 0:
                new_scheme += str(self.convert(self.ranges[key])) + "\t"
            elif "age" in key:
                new_scheme +=  str(round(scheme[ind])) + "us" + "\t"
            elif "size" in key:
                new_scheme += str(round(scheme[ind])) + "B" + "\t"
            else:
                new_scheme += str(round(scheme[ind])) + "\t"
            ind += 1
        new_scheme += self.ranges["action"]
        file_name = self.damoos_path + "/scheme_adapters/pso_adapter/scheme"
        scheme_file = open(file_name, "w")
        scheme_file.write(new_scheme)
        scheme_file.close()
        best_score = 0
        for i in range(3):
            pid = self.run_workload()
            subprocess.Popen(["sudo", "python3", self.damos_path, "schemes", "--schemes", file_name, str(pid)])
            collected = self.get_metric(pid, self.metrics)
            command = ["bash", self.damoos_path + "/scheme_adapters/pso_adapter/" + self.score_func_path]
            for metric in self.metrics:
                name = metric.split(";")[0]
                command.append(str(self.workload_info[0][name]))
                command.append(str(collected[name]))
            res = subprocess.check_output(command)
            score =  str(res).split("'")[1][0:-2]
            best_score += float(score)
        print("Best Score:",best_score/3 )

    def function(self, X):
        result = []
        for x in X:
            min_score = 1000000000000
            min_dist = 1000000000000
            for data in self.scores:
                score = data[0]
                scheme = data[1]
                dist = 0
                for i in range(6):
                    if x[i] < 0:
                        continue
                    else:
                        dist += (x[i] - self.convert(scheme[i]))**2
                dist = math.sqrt(dist)
                if dist < min_dist:
                    min_dist = dist
                    min_score = score
            result.append(-min_score)
        return result

    def fit(self):
        options = {'c1': 0.5, 'c2': 0.3, 'w':0.9}
        max_bound = []
        min_bound = []
        
        for key in self.params:
            value = self.ranges[key]
            if not isinstance(value, list):
                max_bound.append(-1)
                min_bound.append(-1.000001)
            else:
                min_bound.append(self.convert(value[0]))
                max_bound.append(self.convert(value[1]))
        bounds = (min_bound, max_bound)
        optimizer = ps.single.GlobalBestPSO(n_particles=5, dimensions=6, options=options, bounds=bounds)
        cost, pos = optimizer.optimize(self.function, iters=100)
        self.run_best_workload(pos)

    def find_best_scheme(self):
        self.parse_json(self.json_path)
        if self.cache_read_enabled or self.cache_write_enabled:
            self.cache_instance = Cache(self.damoos_path + "/scheme_adapters/pso_adapter/", self.cache_file, self.cache_option)
        self.run_orig()
        self.generate_search_param()
        self.collect_data()
        self.collect_score()
        self.fit()
        subprocess.call(["sudo", "DAMOOS=" + self.damoos_path, "bash", self.damoos_path + "/frontend/cleanup.sh"])

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("-dp", "--damoos_path", required=True, help="DAMOOS path")
    parser.add_argument("-lb", "--lazybox_path", required=True, help="Lazybox path")
    parser.add_argument("-jp", "--json_path", required=True, help="JSON file path")
    parser.add_argument("-dm", "--damos_path", required=True, help="DAMOS path")
    args = vars(parser.parse_args())

    damoos_path = args["damoos_path"]
    lazybox_path = args["lazybox_path"]
    json_path = args["json_path"]
    damos_path = args["damos_path"]
   
    
    psofit = PSO(damoos_path, lazybox_path, damos_path, json_path)
    psofit.find_best_scheme()

if __name__=='__main__':
    main()
