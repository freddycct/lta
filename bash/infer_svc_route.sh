#!/bin/bash

max_jobs=6

parallel --no-notice --max-procs ${max_jobs} "cat ../data/20111101_20111106/bus_records/{1}.txt | julia ../julia/infer_svc_route.jl > ../data/20111101_20111106/log/{1}.log" :::: ../data/20111101_20111106/all_service_numbers_data_20111101_20111106

#parallel --no-notice --max-procs ${max_jobs} "cat ../data/20111101/{1}.txt | julia ../julia/infer_svc_route.jl > ../data/20111101/log/{1}.log" :::: ../data/20111101/all_service_numbers_data_20111101
