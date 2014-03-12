#!/bin/bash

parallel --no-notice --max-procs ${max_jobs} "cat ../data/{1}/date_sorted | julia ../julia/extract_svc_num.jl" :::: ../data/file_list2