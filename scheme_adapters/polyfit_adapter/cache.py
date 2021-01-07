# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: GPL-2.0

import pickle5 as pickle
import os


def convert_scheme(scheme):
    key = ""
    for i in range(6):
        if type(scheme[i]) == str:
            key += scheme[i] + " "
        elif type(scheme[i]) == int:
            if i == 0 or i == 1:
                size = round(scheme[i] / 1000)
                key += str(size) + " "
            elif i == 2 or i == 3:
                key += str(scheme[i]) + " "
            elif i == 4 or i == 5:
                age = round(scheme[i] / 1000000)
                key += str(age) + " "
        else:
            raise Exception("Invalid data type.")
    key += scheme[6]
    return key


class Cache:
    def __init__(self, path, cache_name, option):
        self.path = path + "/caches/.cache_" + cache_name
        if option == "force":
            cache = dict()
            with open(self.path, 'wb') as pkl_file:
                pickle.dump(cache, pkl_file, protocol=pickle.HIGHEST_PROTOCOL)
        elif option == "check":
            if os.path.isfile(self.path):
                return
            else:
                cache = dict()
                with open(self.path, 'wb') as pkl_file:
                    pickle.dump(cache, pkl_file, protocol=pickle.HIGHEST_PROTOCOL)
        else:
            raise Exception("Invalid option")

    def store(self, scheme, data):
        with open(self.path, 'rb') as pkl_file:
            cache = pickle.load(pkl_file)
        key = convert_scheme(scheme)
        if key in cache.keys():
            num = cache[key][0]
            old_data = cache[key][1]
            for key, value in old_data.items():
                new_value = (num * value + data[key]) / (num + 1)
                data[key] = new_value
            cache[key] = [num + 1, data]
        else:
            cache[key] = [1, data]
        with open(self.path, 'wb') as pkl_file:
            pickle.dump(cache, pkl_file, protocol=pickle.HIGHEST_PROTOCOL)

    def get(self, scheme):
        key = convert_scheme(scheme)
        with open(self.path, 'rb') as pkl_file:
            cache = pickle.load(pkl_file)
        if key in cache.keys():
            return cache[key]
        else:
            return -1
