# multiD_polyfit_adapter

**multiD_polyfit_adapter** - This adapter uses polyfit_adapter to tune more than one parameter one by one.

**multiD_polyfit_adapter.sh** - This adapter expects the user to write a JSON file in the same format as polyfit adapter but with a default option for the default values of different parameters and add it in the multiD_polyfit_adapter/json_files directory. Then it generates multiple json files based on number of parameters to optimize.

For e.g. if the user wants to tune min_age and min_size and the original JSON file name is sample.json, then this adapter will create two more new JSON files in the polyfit_adapter/json_files directory as follows:

sample_min_age.json

sample_min_size.json

The user needs to specify the search range and other details in a JSON file format as follows:

```
{
    "metrics": [
        "rss;full_avg",
        "runtime;stat"
    ],
    "workload": "dedup",
    "score_function": "sf.sh",
    "num_dimension": 3,
    "default" : {
            "min_size": "4K",
            "max_size": "max",
            "min_age": "5s",
            "max_age": "max",
            "min_freq": "min",
            "max_freq": "min"
    },
    "range": {
        "min_size": ["4K", "30K"],
        "max_size": "max",
        "min_age": [
            "0s",
            "60s"
        ],
        "max_age": "max",
        "min_freq": "min",
        "max_freq": [0,5],
        "action": "pageout"
    },
    "total_runtime": 10000000000000000,
    "num_runs": 10,
    "cache_file": "dedup",
    "read_from_cache": true,
    "write_to_cache": true,
    "cache_option": "check"
}
```
Please read ![polyfit_adapter/README](../polyfit_adapter/README.md) for more details about the JSON file.

The only key-value pairs different in this JSON file from polyfit_adapter is the key named "default". So, when min_age is tuned the range is used from the "range" dictionary and the default values for all other parameters from the "default" dictionary.
Hence, all values in the JSON file other than the "default" and "range" are passed as it is to the polyfit_adapter.

**requirements.txt** - This file stores the inputs required by this scheme. It is used by the main damoos interface to ask the user for inputs.