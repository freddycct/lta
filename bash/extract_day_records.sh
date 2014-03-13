#!/bin/bash

# extract the daily records from the sorted big files

max_jobs=6

parallel --no-notice --max-procs ${max_jobs} "zcat ../data/{1}.gz | julia ../julia/extract_day_records.jl" :::: ../data/file_list

