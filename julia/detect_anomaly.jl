# This script is meant to detect anomalies in the traffic patterns

include("edgebased.jl")
using HDF5, JLD

begin
	prefix = "../data"
	date = "20111101"
	learning_rate = 2e-3
	tau = 1e-4
	iterations = 100

	bus_stops, bus_services = read_bus_routes(prefix, date)

	# Now read all records into memory
	records = read_all_records(prefix, date, bus_stops, bus_services)

	init_speed, baseline_train_squared_error, total_distance = baseline(records)
	init_sigma2 = baseline_train_squared_error / total_distance

	# Now construct the topology of the network based on the routes that was read in
	create_bus_routes_topology(bus_services, init_speed)

	edgebased_train_squared_error = speed_estimation(iterations, records, bus_stops, 
		bus_services, learning_rate, tau, 0.0, init_sigma2, total_distance)

	edgebased_train_rmse = sqrt(edgebased_train_squared_error / length(records))
	@printf("Edgebased Train RMSE: %f\n", edgebased_train_rmse)

	@save sprintf("%s/%s/jld/edgebased.jld", prefix, date) bus_stops, bus_services
end