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
    iterations = parseint(ARGS[5])
else
    iterations = 2
end

# first step would be to read in success and store the routes of each bus service in memory
bus_stops, bus_services = read_bus_routes(prefix, date)

# Now read all records into memory
println("Reading records...")
records = read_all_records(prefix, date, bus_stops, bus_services)

k_fold = 5
validation_sets = create_k_fold_validation_sets(records, k_fold)

baseline_train_rmse = Array(Float64, 5)
baseline_test_rmse  = Array(Float64, 5)

baseline2_train_rmse = Array(Float64, 5)
baseline2_test_rmse  = Array(Float64, 5)

edgebased_train_rmse = Array(Float64, 5)
edgebased_test_rmse  = Array(Float64, 5)

for k=1:k_fold
    @printf("Fold %d\n", k)

    # create the training set
    train_set = Array(Record, 0)
    #k is the test set
    for kk=1:k_fold
        if k == kk
            continue
        end
        
        for record in validation_sets[kk]
            push!(train_set, record)
        end
    end

    # create the testing set
    test_set = validation_sets[k]

    #println(length(train_set))

    # Start of Baseline

    init_speed, baseline_train_squared_error, total_distance = baseline(train_set)
    init_sigma2 = baseline_train_squared_error / total_distance
    
    baseline_train_rmse[k] = sqrt(baseline_train_squared_error / length(train_set))
    @printf("Baseline Train RMSE: %f\n", baseline_train_rmse[k])

    baseline_test_squared_error = 0
    for record in test_set
        baseline_test_squared_error += (record.time_taken - (record.distance / init_speed))^2
    end
    baseline_test_rmse[k] = sqrt(baseline_test_squared_error / length(test_set))
    @printf("Baseline Test RMSE: %f\n", baseline_test_rmse[k])
    println()
    
    # End of Baseline

    # Start of Baseline2

    baseline2_train_squared_error, bus_services_speed = baseline2(train_set)
    baseline2_train_rmse[k] = sqrt(baseline2_train_squared_error / length(train_set))
    @printf("Baseline2 Train RMSE: %f\n", baseline2_train_rmse[k])

    baseline2_test_squared_error = 0
    for record in test_set
        if !haskey(bus_services_speed, record.bus_no)
            continue
        end
        baseline2_test_squared_error += (record.time_taken - (record.distance / bus_services_speed[record.bus_no]))^2
    end
    baseline2_test_rmse[k] = sqrt(baseline2_test_squared_error / length(test_set))
    @printf("Baseline2 Test RMSE: %f\n", baseline2_test_rmse[k])
    println()

    # End of Baseline2

    # Start of EdgeBased method

    init_edges_speed(bus_stops, init_speed)
    
    edgebased_train_squared_error = speed_estimation(iterations, train_set, bus_stops, bus_services, eta, tau, init_sigma2, total_distance)
    edgebased_train_rmse[k] = sqrt(edgebased_train_squared_error / length(train_set))
    @printf("Edgebased Train RMSE: %f\n", edgebased_train_rmse[k])
    
    edgebased_test_squared_error = calculate_squared_error(test_set, bus_stops, bus_services)
    edgebased_test_rmse[k] = sqrt(edgebased_test_squared_error / length(test_set))
    @printf("Edgebased Test RMSE: %f\n", edgebased_test_rmse[k])
    println()

    # End of EdgeBased method
end


