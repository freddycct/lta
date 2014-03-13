#!/bin/bash

#from the daily records, extract the records for each bus service

max_jobs=6

parallel --no-notice --max-procs ${max_jobs} "cat ../data/{1}/date_sorted | julia ../julia/extract_svc_num.jl" :::: ../data/file_list2

parallel --no-notice --max-procs ${max_jobs} "ls ../data/{1}/bus_records/*.txt | xargs -n 1 basename | cut -d '.' -f 1 | sort -n > ../data/{1}/all" :::: ../data/file_list
