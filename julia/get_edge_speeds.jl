include("edgebased.jl")
using HDF5, JLD

begin
	prefix = "../data"
	date = "20111101"
	eta = 2e-3
	tau = 1e-4
	psi = 0.0
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

	edgebased_train_squared_error = speed_estimation(iterations, records, bus_stops, bus_services, eta, tau, psi, init_sigma2, total_distance)
	edgebased_train_rmse = sqrt(edgebased_train_squared_error / length(records))
	@printf("Edgebased Train RMSE: %f\n", edgebased_train_rmse)

	#sigma2 = edgebased_train_squared_error / total_distance
	edgebased_speeds = get_edge_speeds(bus_stops, bus_services)

	init_edges_speed(bus_stops, init_speed)

	smoothed_train_squared_error = speed_estimation(iterations, records, bus_stops, bus_services, eta, tau, 0.01, init_sigma2, total_distance)
	smoothed_train_rmse = sqrt(smoothed_train_squared_error / length(records))
	@printf("Smoothed Train RMSE: %f\n", smoothed_train_rmse)

	smoothed_speeds = get_edge_speeds(bus_stops, bus_services)

	@save "edge_speeds.jld" edgebased_speeds smoothed_speeds edgebased_train_squared_error smoothed_train_squared_error total_distance
end