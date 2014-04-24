#!/bin/bash

max_jobs=6

parallel --no-notice --max-procs ${max_jobs} "ls -l ../data/{1}/logs/ | julia ../julia/check_merge.jl | sort -n > ../data/{1}/success" :::: ../data/file_list.txt

