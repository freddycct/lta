require("io.jl")
require("anomaly.jl")

function main()
	prefix = "../data"
	if isdefined(ARGS, 1)
		date = ascii(ARGS[1])
	else
		date = "20111101"
	end

	bus_stops, bus_services = read_bus_routes(prefix, date)

	# Now read all records into memory
	records = read_all_records(prefix, date, bus_stops, bus_services)
	
	load_edge_speeds!(bus_stops, @sprintf("%s/%s/jld/edgebased_edges.jld", prefix, date))

	sum_squared_errors = calculate_squared_error(records, bus_stops, bus_services)
	println("sum_squared_errors: ",  sum_squared_errors)
	total_distance = get_total_distance(records)
	sigma2 = sum_squared_errors / total_distance

	compute_std_ratio!(records, bus_stops, bus_services, sigma2)

	sort!(records, lt=cmp_record, rev=true)

	#top_point_5_percent = int(round(0.005 * length(records)))
	top_1_percent = int(round(0.01 * length(records)))

	# this is to relate the abnormal records to one another
	for i=1:top_1_percent
		r1 = records[i]
		r1.related_records = Array(Record, 0)
		r1_origin, r1_destination = get_origin_destination_nodes(r1, bus_stops, bus_services)
		for j=1:top_1_percent
			if i == j
				continue
			end
			r2 = records[j]
			if is_inside(r1, r2, r1_origin, r1_destination, bus_stops, bus_services)
				push!(r1.related_records, r2)
			end
		end
	end

	abnormal_records = records[1:top_1_percent]
	sort!(abnormal_records, lt=cmp_record_related_length, rev=true)

	read_bus_stop_id_mapping!(prefix, bus_stops)
	fid = open(@sprintf("%s/%s/anomalies.txt", prefix, date), "w")
	for (i, record) in enumerate(abnormal_records)
		write(fid, string(i, 
			",bus_no=", record.bus_no, 
			",|R_", i, "|=", length(record.related_records), 
			",origin=", bus_stops[record.origin].name, 
			",destination=", bus_stops[record.destination].name, 
			",distance=", record.distance, 
			",start_time=", strftime(record.datetime_board), 
			",end_time=",   strftime(record.datetime_alight), 
			",expected=", record.time_predicted/60, 
			",observed=", record.time_taken/60, 
			",est_sigma=", record.estimated_sigma,
			",obs_sigma=", record.observed_sigma,
			",ratio=", record.ratio, 
			"\n")
		)
	end
	close(fid)
end

main()