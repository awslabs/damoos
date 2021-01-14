import sys
import json
import argparse
import copy
import subprocess

def generate_json(file_name, damoos_path):
    json_file = open(damoos_path + "/scheme_adapters/multiD_polyfit_adapter/json_files/" + file_name, "r")
    json_parsed = json.load(json_file)
    copy_dict = dict()
    for key, value in json_parsed.items():
        if key == "num_dimension":
            copy_dict[key] = 1
        elif key != "default" and key!= "range":
            copy_dict[key] = value
    ranges = json_parsed["range"]
    default = json_parsed["default"]

    parameters = []
    for key, value in ranges.items():
        if isinstance(value, list):
            ranges_dict = dict()
            for k, v in default.items():
                if k != key:
                    ranges_dict[k] = default[k]
            ranges_dict[key] = value
            ranges_dict["action"] = ranges["action"]
            json_dict = copy.deepcopy(copy_dict)
            json_dict["range"] = ranges_dict
            name = file_name.split(".")[0]
            with open(damoos_path + "/scheme_adapters/polyfit_adapter/json_files/" + name + "_" + key + ".json", "w") as targetfile:  
                json.dump(json_dict, targetfile) 
            parameters.append(key)
    return parameters

def generate_best_scheme(file_name, damoos_path, best_points):
    json_file = open(damoos_path + "/scheme_adapters/multiD_polyfit_adapter/json_files/" + file_name, "r")
    json_parsed = json.load(json_file)
    parameters = ["min_size", "max_size", "min_freq", "max_freq", "min_age", "max_age"]
    new_scheme = []
    
    for key in parameters:
        if key in best_points.keys():
            new_scheme.append(int(best_points[key]))
        else:
            new_scheme.append(-1)
    return new_scheme

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

    sys.path.append(damoos_path + '/scheme_adapters/polyfit_adapter')
    from polyfit_adapter import Polyfit
    
    name = json_path.split(".")[0]
    parameters = generate_json(json_path, damoos_path)

    best_points = dict()

    for i in range(len(parameters)):
        polyfit = Polyfit(damoos_path, lazybox_path, damos_path)
        best_fit = polyfit.find_best_scheme(name + "_" + str(parameters[i]) + ".json")
        print("Best ", parameters[i], ":", best_fit)
        best_points[parameters[i]] = best_fit
        if i == len(parameters) - 1:
            new_scheme = generate_best_scheme(json_path, damoos_path, best_points)
            res = polyfit.run_best_workload(new_scheme)
            print("Best score:", res[0], "Best metric:", res[1])

    subprocess.call(["sudo", "DAMOOS=" + damoos_path, "bash", damoos_path + "/frontend/cleanup.sh"])

if __name__ == '__main__':
    main()
