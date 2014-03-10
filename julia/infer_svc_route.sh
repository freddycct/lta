#!/bin/bash

max_jobs=6

parallel --no-notice --max-procs ${max_jobs} "cat ../data/20111101_20111106/{1}.txt | julia infer_svc_route.jl > ../data/20111101_20111106/log/{1}.log" :::: ../data/20111101_20111106/all_service_numbers_data_20111101_20111106
