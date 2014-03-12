#!/bin/bash

max_jobs=6

parallel --no-notice --max-procs ${max_jobs} "zcat ../data/{1}.gz | julia ../julia/extract_day_records.jl" :::: ../data/file_list

