# This script runs the edgebased algorithm on the full data set in order to plot the speeds of each segment

include("edgebased.jl")
using HDF5, JLD

begin
	prefix = "../data"
	date = "20111101"
	learning_rate = 2e-3
	tau = 1e-4
	psi = 0.01
	iterations = 100

	bus_stops, bus_services = read_bus_routes(prefix, date)

	# Now read all records into memory
	records = read_all_records(prefix, date, bus_stops, bus_services)

	init_speed, baseline_train_squared_error, total_distance = baseline(records)
	init_sigma2 = baseline_train_squared_error / total_distance

	baseline_train_rmse = sqrt(baseline_train_squared_error / length(records))
	@printf("Baseline Train RMSE: %f\n", baseline_train_rmse)

	# Now construct the topology of the network based on the routes that was read in
	create_bus_routes_topology(bus_services, init_speed)

	edgebased_train_squared_error = speed_estimation(iterations, records, bus_stops, bus_services, learning_rate, tau, 0.0, init_sigma2, total_distance)
	edgebased_train_rmse = sqrt(edgebased_train_squared_error / length(records))
	@printf("Edgebased Train RMSE: %f\n", edgebased_train_rmse)

	#sigma2 = edgebased_train_squared_error / total_distance
	edgebased_speeds = get_edge_speeds(bus_stops, bus_services)

	init_edges_speed(bus_stops, init_speed)

	smoothed_train_squared_error = speed_estimation(iterations, records, bus_stops, bus_services, learning_rate, tau, psi, init_sigma2, total_distance)
	smoothed_train_rmse = sqrt(smoothed_train_squared_error / length(records))
	@printf("Smoothed Train RMSE: %f\n", smoothed_train_rmse)

	smoothed_speeds = get_edge_speeds(bus_stops, bus_services)

	@save @sprintf("%s/%s/jld/edge_speeds.jld", prefix, date) edgebased_speeds smoothed_speeds edgebased_train_squared_error smoothed_train_squared_error total_distance
end