#!/bin/bash

#plot the routes of each bus service for everyday

max_job=6

#parallel --no-notice --max-procs ${max_job} 'cat ../data/{1}/bus_records/{2}.txt" :::: ../data/file_list

#parallel --no-notice --max-procs 2 --header : parallel --no-notice --max-procs 3 --header : echo ../data/{outer}/bus_records/{inner} ::: inner `cat ../data/{outer}/all` ::: outer `cat ../data/file_list`

rm -f files_to_process

for outer in `cat ../data/file_list`; do
	for inner in `cat ../data/${outer}/all`; do
		echo "cat ../data/${outer}/bus_records/${inner}.txt | julia ../julia/infer_svc_route.jl ../data/${outer}/bus_routes > ../data/${outer}/logs/${inner}" >> files_to_process
	done
done

cat files_to_process | parallel --no-notice --max-procs 6
rm -f files_to_process

