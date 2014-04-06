include("edgebased.jl")

if isdefined(ARGS, 1)
    prefix = convert(ASCIIString, ARGS[1])
else
    prefix = "../data"
end

if isdefined(ARGS, 2)
    date = convert(ASCIIString, ARGS[2])
else
    date = "20111101"
end

if isdefined(ARGS, 3)
    eta = parsefloat(ARGS[3])
else
    eta = 2e-3
end

if isdefined(ARGS, 4)
    tau = parsefloat(ARGS[4])
else
    tau = 1e-4
end

if isdefined(ARGS, 5)
	psi = parsefloat(ARGS[5])
else
	psi = 0.0
end

if isdefined(ARGS, 6)
    iterations = parseint(ARGS[6])
else
    iterations = 2
end

bus_stops, bus_services = read_bus_routes(prefix, date)

# Now read all records into memory
println("Reading records...")
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

init_edges_speed(bus_stops, init_speed)

smoothed_train_squared_error = speed_estimation(iterations, records, bus_stops, bus_services, eta, tau, 0.01, init_sigma2, total_distance)
smoothed_train_rmse = sqrt(smoothed_train_squared_error / length(records))
@printf("Smoothed Train RMSE: %f\n", smoothed_train_rmse)

init_edges_speed(bus_stops, init_speed)

cd_train_squared_error = coordinate_descent(iterations, records, bus_stops, bus_services, total_distance)
cd_train_rmse = sqrt(cd_train_squared_error / length(records))
@printf("Coordinate Descent Train RMSE: %f\n", cd_train_rmse)

