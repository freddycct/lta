# This script runs the edgebased algorithm on the full data set in order to plot the speeds of each segment

require("edgebased.jl")
require("io.jl")

function main()
	prefix = "../data"
	if isdefined(ARGS, 1)
		date = ascii(ARGS[1])
	else
		date = "20111101"
	end
	learning_rate = 1e-4
	tau = 1e-4
	psi = 0.01
	iterations = 200

	bus_stops, bus_services = read_bus_routes(prefix, date)

	# Now read all records into memory
	records = read_all_records(prefix, date, bus_stops, bus_services)

	init_speed, baseline_train_squared_error, total_distance = baseline(records)
	init_sigma2 = baseline_train_squared_error / total_distance

	baseline2_train_squared_error, bus_services_speed = baseline2(records)

	# Now construct the topology of the network based on the routes that was read in
	create_bus_routes_topology!(bus_services, init_speed)
	
	edgebased_train_squared_error = speed_estimation!(iterations, records, bus_stops, bus_services, learning_rate, tau, 0.0, init_sigma2, total_distance)

	edgebased_train_rmse = sqrt(edgebased_train_squared_error[end, 2] / length(records))
	@printf("Edgebased Train RMSE: %f\n", edgebased_train_rmse)

	init_edges_speed!(bus_stops, init_speed)
	
	smoothed_train_squared_error = speed_estimation!(iterations, records, bus_stops, bus_services, learning_rate, tau, psi, init_sigma2, total_distance)

	smoothed_train_rmse = sqrt(smoothed_train_squared_error[end, 2] / length(records))
	@printf("Smoothed Train RMSE: %f\n", smoothed_train_rmse)
	
	@save @sprintf("%s/%s/jld/time_error.jld", prefix, date) baseline_train_squared_error baseline2_train_squared_error edgebased_train_squared_error smoothed_train_squared_error total_distance
end

main()