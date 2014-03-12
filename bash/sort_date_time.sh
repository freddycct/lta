#!/bin/bash

max_jobs=6

parallel --no-notice --max-procs ${max_jobs} "zcat ../data/ride_data_{1}.gz | /home/freddy/coreutils/bin/sort -t $'\t' -k3.7,3.10n -k3.4,3.5n -k3.1,3.2n -k4.1,4.2n -k4.4,4.5n -k4.7,4.8n > ../data/date_sorted_{1}" :::: ../data/file_list
#cat ../data/trimmed_ride_data_20111101_20111106 | /home/freddy/coreutils/bin/sort --parallel=6 -t $'\t' -k3.7,3.10n -k3.4,3.5n -k3.1,3.2n -k4.1,4.2n -k4.4,4.5n -k4.7,4.8n > ../data/date_sorted_20111101_20111106
