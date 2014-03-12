#!/bin/bash

max_jobs=6

parallel --no-notice --max-procs ${max_jobs} "cat ../data/{1}.txt | julia ../julia/extract_day_records.jl" :::: ../data/file_list

