#!/bin/bash

max_jobs=6

parallel --no-notice --max-procs ${max_jobs} "zcat ../data/ride_data_20111101_20111106.gz | julia extract_svc_num.jl {1} > ../data/20111101_20111106/{1}.txt" :::: ../data/20111101_20111106/all_service_numbers_data_20111101_20111106
