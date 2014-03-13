#!/bin/bash

max_job=6

parallel --no-notice --max-procs ${max_job} "cat ../data/{1}/bus_records/{2}.txt" :::: ../data/file_list :::: ../data/{1}/all