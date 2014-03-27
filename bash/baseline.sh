#!/bin/bash

max_jobs=6

#parallel --no-notice --max-procs ${max_jobs} "julia ../julia/baseline.jl ../data {1} > ../data/{1}/baseline_params.txt" :::: ../data/file_list
parallel --no-notice --max-procs ${max_jobs} "julia ../julia/baseline2.jl ../data {1} > ../data/{1}/baseline2_params.txt" :::: ../data/file_list
