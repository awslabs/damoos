# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: GPL-2.0

import numpy as np
import json
import argparse
import subprocess
import time
import pickle5 as pickle
import random
import warnings
import re
from cache import Cache

class Polyfit:
    def __init__(self, damoos_path, lazybox_path, damos_path):
        self.orig_metric_values = []
        self.metrics = []
        self.workload = ""
        self.orig_repeat = 2
        self.explore_factor = 0.6
        self.workload_info = []
        self.score_func_path = ""
        self.scores = []
        self.ranges = dict()
        self.num_runs = 0
        self.total_runs = 0
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
        self.conversion_factor = {"us": 1, "ms": 1000, "s": 1000000, "m": 60000000, "h": 3600000000, "d": 86400000000,
                                  "B": 1, "K": 1024, "M": 1048576, "G": "1073741824", "T": 1099511627776}
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
        file = open(self.damoos_path + "/scheme_adapters/polyfit_adapter/json_files/" + file_name, "r")
        json_parsed = json.load(file)

        self.num_dim = json_parsed["num_dimension"]
        if type(self.num_dim) != int:
            raise Exception("Integer expected.")
        elif self.num_dim != 1:
            raise Exception("Only 1 dimension allowed.")

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

        self.total_runs = json_parsed["num_runs"]
        if type(self.total_runs) != int:
            raise Exception("Integer expected.")
        self.num_runs = int(self.total_runs * self.explore_factor)

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
        command = ["sudo", "DAMOOS=" + self.damoos_path, "bash", self.damoos_path + "/frontend/run_workloads.sh",
                   self.workload]
        for metric in self.metrics:
            command.append(metric.split(";")[0])
        ret = subprocess.call(command)
        if ret == 0:
            pid = open(self.damoos_path + "/results/pid").readline()
            pid = pid.strip()
            return pid
        else:
            raise Exception("Unable to run the workload")

    def get_metric(self, pid, metric_list):
        subprocess.call(
            ["sudo", "DAMOOS=" + self.damoos_path, "bash", self.damoos_path + "/frontend/wait_for_process.sh",
             str(pid)])
        wait_command = ["sudo", "DAMOOS=" + self.damoos_path, "bash",
                        self.damoos_path + "/frontend/wait_for_metric_collector.sh", str(pid)]
        for metric in metric_list:
            name = metric.split(";")[0]
            wait_command.append(name)
        subprocess.call(wait_command)
        workload_metrics = dict()
        for metric in metric_list:
            name = metric.split(";")[0]
            collect_type = metric.split(";")[1]
            counter = 0
            while counter < 5:
                if (subprocess.call(
                        ["sudo", "DAMOOS=" + self.damoos_path, "bash", self.damoos_path + "/frontend/get_metric.sh",
                         str(pid), name, collect_type]) != 0):
                    time.sleep(1)
                    counter += 1
                    continue
                else:
                    fil1 = open(self.damoos_path + "/results/" + name + "/" + str(pid) + "." + collect_type, "r")
                    result = float(str(fil1.readlines()).split("'")[1][0:-2])
                    workload_metrics[name] = result
                    break
        return workload_metrics

    def run_orig(self):
        orig_stat = dict()
        for i in range(self.orig_repeat):
            pid = self.run_workload()
            temp_list = self.metrics[:]
            if "runtime;stat" not in temp_list:
                temp_list.append("runtime;stat")
            res = self.get_metric(pid, temp_list)
            for key, value in res.items():
                if key not in orig_stat.keys():
                    orig_stat[key] = value
                else:
                    orig_stat[key] += value

        for key, value in orig_stat.items():
            orig_stat[key] = value / self.orig_repeat
        print("Original Statistics for Workload without scheme applied:", orig_stat)
        self.workload_info.append(orig_stat)

    def convert(self, value):
        if type(value) == int:
            return value
        try:
            return int(value)
        except:
            pass

        if value == "max" or value == "min":
            return value

        unit = " ".join(re.findall("[a-zA-Z]+", value))
        num = int(" ".join(re.findall("[0-9]+", value)))
        return self.conversion_factor[unit] * num

    def find_key_dim(self, num_runs):
        curr_dim = self.num_dim
        curr_left = num_runs
        key_dim = []
        while curr_dim > 0:
            key_dim.append(int(curr_left ** (1 / float(curr_dim))))
            curr_left = int(curr_left / key_dim[-1])
            curr_dim -= 1
        return key_dim

    def generate_search_param(self):
        num = self.total_runtime / self.workload_info[0]["runtime"]
        self.num_runs = max(5, min(self.num_runs, num))

        key_dim = self.find_key_dim(self.num_runs)
        key_index = 0
        for key, value in self.ranges.items():
            if isinstance(value, list):
                range_diff = self.convert(value[1]) - self.convert(value[0])
                num_runs = key_dim[key_index]
                key_index += 1
                num_runs = min(num_runs, range_diff + 1)
                num_regions = max(1, int(num_runs / 5))
                region_size = int(range_diff / num_regions)
                self.search_param[key] = [self.convert(value[0])]
                num_left = num_runs - (num_regions + 1)
                num_samples = int(num_left / num_regions)
                remainder = num_left % num_regions
                for i in range(num_regions):
                    self.search_param[key].append((i + 1) * region_size)
                    numbers = num_samples + (1 if i < remainder else 0)
                    random_list = random.sample(range((i * region_size) + 1, (i + 1) * region_size), numbers)
                    self.search_param[key] += random_list
            else:
                self.search_param[key] = [value]

    def collect_data(self, search_space):
        subprocess.call(["sudo", "bash", self.lazybox_path + "/scripts/zram_swap.sh", "4G"])
        store_metrics = []
        action = search_space["action"][0]

        for min_size in search_space["min_size"]:
            for max_size in search_space["max_size"]:
                for min_freq in search_space["min_freq"]:
                    for max_freq in search_space["max_freq"]:
                        for min_age in search_space["min_age"]:
                            for max_age in search_space["max_age"]:
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
                                scheme = subprocess.check_output(
                                        ["python3", self.damos_path,
                                            "translate_damos", scheme]).decode()

                                file_name = self.damoos_path + "/scheme_adapters/polyfit_adapter/scheme"
                                scheme_file = open(file_name, "w")
                                scheme_file.write(scheme)
                                scheme_file.close()
                                pid = self.run_workload()
                                subprocess.Popen(
                                    ["sudo", "python3", self.damos_path, "schemes", "--schemes", file_name, str(pid)])
                                collected_metric = self.get_metric(pid, self.metrics)
                                store_metrics.append((collected_metric, scheme_list))
                                if self.cache_write_enabled:
                                    self.cache_instance.store(scheme_list + [action], collected_metric)
        return store_metrics

    def collect_score(self, data, option):
        for value in data:
            command = ["bash", self.damoos_path + "/scheme_adapters/polyfit_adapter/" + self.score_func_path]
            for metric in self.metrics:
                name = metric.split(";")[0]
                command.append(str(self.workload_info[0][name]))
                command.append(str(value[0][name]))
            res = subprocess.check_output(command)
            score = str(res).split("'")[1][0:-2]
            if option == "append":
                self.scores.append((float(score), value[1]))
            elif option == "return":
                return score
            else:
                raise Exception("collect_score: Invalid option.")

    def exploit_best_region(self):
        scores = self.scores[:]
        scores.sort()
        scores.reverse()
        num_points = max(0.1 * self.num_runs, 2)
        runs_left = self.total_runs - self.num_runs
        data_dict = dict()
        if runs_left <= 0:
            return data_dict

        for i in range(0, num_points, 1):
            for j in range(len(self.params)):
                if isinstance(self.ranges[self.params[j]], list):
                    point = scores[i][1][j]
                    min_range = self.convert(self.ranges[self.params[j]][0])
                    max_range = self.convert(self.ranges[self.params[j]][1])
                    range_diff = max_range - min_range
                    lower_bound = max(point - int(0.1 * range_diff), min_range)
                    upper_bound = min(point + int(0.1 * range_diff), max_range)
                    num_samples = int(runs_left / (num_points - i))
                    num_samples = min(num_samples, upper_bound - lower_bound)
                    runs_left -= num_samples
                    random_list = random.sample(range(lower_bound, upper_bound), num_samples)
                    if self.params[j] in data_dict.keys():
                        data_dict[self.params[j]] += random_list
                    else:
                        data_dict[self.params[j]] = random_list
                else:
                    data_dict[self.params[j]] = [scores[i][1][j]]
        data_dict["action"] = [self.ranges["action"]]
        return data_dict

    def run_best_workload(self, scheme):
        new_scheme = ""
        ind = 0
        for key in self.params:
            if scheme[ind] < 0:
                scheme[ind] = (self.convert(self.ranges[key]))
            if scheme[ind] == "min" or scheme[ind] == "max":
                new_scheme += str(scheme[ind]) + "\t"
            elif "age" in key:
                new_scheme += str(round(scheme[ind])) + "us" + "\t"
            elif "size" in key:
                new_scheme += str(round(scheme[ind])) + "B" + "\t"
            else:
                new_scheme += str(round(scheme[ind])) + "\t"
            ind += 1
        new_scheme += self.ranges["action"]
        file_name = self.damoos_path + "/scheme_adapters/polyfit_adapter/scheme"
        scheme_file = open(file_name, "w")
        scheme_file.write(new_scheme)
        scheme_file.close()
        best_score = 0
        avg_metric = dict()
        for i in range(3):
            pid = self.run_workload()
            subprocess.Popen(["sudo", "python3", self.damos_path, "schemes", "--schemes", file_name, str(pid)])
            collected = self.get_metric(pid, self.metrics)
            command = ["bash", self.damoos_path + "/scheme_adapters/polyfit_adapter/" + self.score_func_path]
            for metric in self.metrics:
                name = metric.split(";")[0]
                if name not in avg_metric.keys():
                    avg_metric[name] = collected[name]
                else:
                    avg_metric[name] += collected[name]

                command.append(str(self.workload_info[0][name]))
                command.append(str(collected[name]))
            res = subprocess.check_output(command)
            score = str(res).split("'")[1][0:-2]
            best_score += float(score)
        for key, value in avg_metric.items():
            avg_metric[key] = value / 3
        return best_score / 3, avg_metric

    def polynomial_fit(self, x, y, min_range, max_range, degree):
        x, y = zip(*sorted(zip(x, y)))
        x = list(x)
        y = list(y)
        mini = 10000000
        for el in y:
            if el != -1000 and mini > el:
                mini = el

        for i in range(len(y)):
            if y[i] == -1000:
                y[i] = mini
        with warnings.catch_warnings():
            warnings.simplefilter('ignore', np.RankWarning)
            poly = np.poly1d(np.polyfit(x, y, degree))
            poly_coeff = np.polyfit(x, y, degree)
            num = int(len(poly_coeff))
            derivative = []
            for exp in range(0, len(poly_coeff) - 1, 1):
                num = num - 1
                derivative.append(poly_coeff[exp] * num)
            roots = np.roots(derivative)
            roots = np.append(roots, min_range)
            roots = np.append(roots, max_range)
            best_val = -10000000000
            best_point = -1
            for el in roots:
                if np.iscomplex(el):
                    continue
                if max_range >= el >= min_range:
                    if best_val < poly(el):
                        best_val = max(best_val, poly(el))
                        best_point = np.absolute(el)
            print("Best point:", best_point)
        return best_val, best_point

    def fit(self, arg):
        if type(arg) == str:
            filename = arg
            pickled_file = self.damoos_path + "/scheme_adapters/polyfit_adapter/store/" + filename
            with open(pickled_file, 'rb') as handle:
                data = pickle.load(handle)
            xx = data["variable"]
            yy = data["score"]
            x = []
            y = []
            for i in range(0, 61, 6):
                x.append(xx[i])
                y.append(yy[i])
            self.polynomial_fit(x, y, x[0], x[-1], min(len(x) / 3, 10))
        else:
            best_scheme = []
            degree = min(int(self.total_runs / 3), 10)
            for key in self.params:
                value = self.search_param[key]
                if len(value) > 1:
                    x = value[:] + arg[key][:]
                    y = []
                    for scores in self.scores:
                        y.append(scores[0])
                    min_range = self.convert(self.ranges[key][0])
                    max_range = self.convert(self.ranges[key][1])
                    best_val, best_point = self.polynomial_fit(x, y, min_range, max_range, degree)
                    best_scheme.append(round(best_point))
                else:
                    best_scheme.append(-1)
            self.run_best_workload(best_scheme)
            print("Best Point:", best_point, "Best Value:", best_val)
            return best_point

    def find_best_scheme(self, json_path):
        self.parse_json(json_path)
        print("Optimizing " + self.workload + "...")
        if self.cache_read_enabled or self.cache_write_enabled:
            self.cache_instance = Cache(self.damoos_path + "/scheme_adapters/polyfit_adapter/", self.cache_file,
                                        self.cache_option)
        self.run_orig()
        self.generate_search_param()
        res1 = self.collect_data(self.search_param)
        self.collect_score(res1, "append")
        res = self.exploit_best_region()
        res2 = self.collect_data(res)
        self.collect_score(res2, "append")
        res3 = res1 + res2
        self.workload_info.append(res3)
        best_point = self.fit(res)
        print("Best point:", best_point)
        subprocess.call(["sudo", "DAMOOS=" + self.damoos_path, "bash", self.damoos_path + "/frontend/cleanup.sh"])
        return best_point

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("-dp", "--damoos_path", required=True, help="DAMOOS path")
    parser.add_argument("-pfn", "--pickle_file_name", required=False, help="Pickle file name")
    parser.add_argument("-lb", "--lazybox_path", required=True, help="Lazybox path")
    parser.add_argument("-jp", "--json_path", required=True, help="JSON file path")
    parser.add_argument("-dm", "--damos_path", required=True, help="DAMOS path")

    args = vars(parser.parse_args())
    damoos_path = args["damoos_path"]
    lazybox_path = args["lazybox_path"]
    json_path = args["json_path"]
    damos_path = args["damos_path"]

    try:
        file_name = args["pickle_file_name"]
        polyfit = Polyfit(damoos_path, lazybox_path, damos_path)
        polyfit.fit(file_name)
        return 0
    except:
        pass

    polyfit = Polyfit(damoos_path, lazybox_path, damos_path)
    polyfit.find_best_scheme(json_path)

if __name__ == '__main__':
    main()
