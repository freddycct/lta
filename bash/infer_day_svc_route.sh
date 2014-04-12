#!/bin/bash

#plot the routes of each bus service for everyday

max_job=6

rm -f files_to_process

for outer in `cat ../data/file_list.txt`; do
	for inner in `cat ../data/${outer}/all`; do
		echo "cat ../data/${outer}/bus_records/${inner}.txt | julia ../julia/infer_svc_route.jl ../data/${outer}/bus_routes > ../data/${outer}/logs/${inner}" >> files_to_process
	done
done

cat files_to_process | parallel --no-notice --max-procs 6
rm -f files_to_process

