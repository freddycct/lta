#!/bin/bash

cat ../data/trimmed_ride_data_20111101_20111106 | sort -t $'\t' -k3.7,3.10n -k3.4,3.5n -k3.1,3.2n -k4.1,4.2n -k4.4,4.5n -k4.7,4.8n > date_sorted_20111101_20111106