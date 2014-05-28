# This file contains the stochastic gradient descent algorithm for inferring the speeds of each segment based on the given data.

require("data_structures.jl")

# Read in data
# Store it in memory

type Record
    bus_no::ASCIIString
    
    datetime_board::TmStruct 
    datetime_alight::TmStruct
    
    origin::Int64
    destination::Int64
    
    direction::Int64
    distance::Float64 #store in meters
    time_taken::Float64 #store in seconds

    hops::Int64

    time_predicted::Float64

    estimated_sigma::Float64
    observed_sigma::Float64

    ratio::Float64

    related_records::Array{Record}
    contain_records::Array{Record}

    function Record(bus_no::ASCIIString, datetime_board::TmStruct, datetime_alight::TmStruct, 
        origin::Int64, destination::Int64, direction::Int64, distance::Float64, time_taken::Float64)
        record = new()
        record.bus_no = bus_no
        record.datetime_board = datetime_board
        record.datetime_alight = datetime_alight
        record.origin = origin
        record.destination = destination
        record.direction = direction
        record.distance = distance
        record.time_taken = time_taken
        record
    end
end

function print_record(record::Record)
    @printf("Bus_no: %s, origin: %d, dest: %d, direction: %d, distance: %f, time_taken: %f, time_predicted: %f, ratio: %f, board: %d:%d, alight: %d:%d\n",
        record.bus_no, record.origin, record.destination, record.direction, 
        record.distance, record.time_taken, record.time_predicted, record.ratio,
        record.datetime_board.hour, record.datetime_board.min,
        record.datetime_alight.hour, record.datetime_alight.min)
end

function get_edge_speeds(bus_stops::Dict{Int64, Bus_Stop}, bus_services::Dict{ASCIIString, Bus_Service})
    
    edge_speeds_dict = Dict{ASCIIString, Array{Array{(Float64, Float64)}}}()

    for (bus_no, bus_service) in bus_services
        edge_speeds = Array(Array{(Float64, Float64)}, 2)
        edge_speeds_dict[bus_no] = edge_speeds

        for direction=1:2
            if !isdefined(bus_service.routes, direction)
                continue
            else
                #@printf("Direction_%d\n", direction)
                edge_speeds[direction] = Array(Float64, 0)
            end

            route = bus_service.routes[direction] # route is List
            node  = route.head # obtained linked list node that contains bus stops

            current_node = node.next
            while current_node != node

                bus_stop_prev = node.bus_stop
                bus_stop_next = current_node.bus_stop

                edge = bus_stop_prev.edges[bus_stop_next]
                push!(edge_speeds[direction], (edge.distance, edge.speed))
            
                #check whether the linkedlist have gone circular
                if current_node == route.head
                    break
                end
            
                node = current_node
                current_node = current_node.next
            end
        end
    end
    return edge_speeds_dict
end

# read the initial speed from the baseline model
function get_initial_speed(prefix::ASCIIString, date::ASCIIString)
    fid_baseline = open(@sprintf("%s/%s/baseline_params.txt", prefix, date), "r")
    line = readline(fid_baseline)
    close(fid_baseline)

    fields = split(line)
    fields = split(fields[3], ':')

    return parsefloat(fields[2])
end

function init_edges_speed!(bus_stops::Dict{Int64, Bus_Stop}, init_speed::Float64)
    for bus_stop in values(bus_stops)
        if isdefined(bus_stop, :edges)
            for edge in values(bus_stop.edges)
                edge.speed = init_speed
            end
        end
    end
end

function create_bus_routes_topology!(bus_services::Dict{ASCIIString, Bus_Service}, 
    init_speed::Float64 = 4.0)
    for bus_service in values(bus_services)
        for direction=1:2
            if !isdefined(bus_service.routes, direction)
                continue
            end
            
            route = bus_service.routes[direction] # route is List
            node = route.head # obtained linked list node that contains bus stops
            
            current_node = node.next
            while current_node != node

                #now create the edges and add it to previous
                #just simply assume that the nodes only have 1 bus stop
                
                bus_stop_prev = node.bus_stop
                bus_stop_next = current_node.bus_stop
                
                if !isdefined(bus_stop_prev, :edges)
                    bus_stop_prev.edges = Dict{Bus_Stop, Edge}()
                end
                
                edge = get!(bus_stop_prev.edges, bus_stop_next, 
                    Edge(bus_stop_prev.id, bus_stop_next.id, node.distance_to_next, init_speed))
                
                #check whether the linkedlist have gone circular
                if current_node == route.head
                    break
                end
                
                node = current_node
                current_node = current_node.next
            end
        end
    end
end

function check_finite!(record::Record, bus_stops::Dict{Int64, Bus_Stop}, bus_services::Dict{ASCIIString, Bus_Service})
    bus_no = record.bus_no
    bus_service = bus_services[bus_no]
    
    # get the origin and dest
    origin_id      = record.origin
    destination_id = record.destination
    
    # get the direction
    direction = record.direction
    
    # retrieve the list_nodes associated with them
    bus_stops_dict = bus_service.bus_stops[direction]
    
    #@printf("bus: %s, orig: %d, dest: %d, dir: %d\n", bus_no, origin_id, destination_id, direction)

    if haskey(bus_stops, origin_id)
        bus_stop_origin = bus_stops[origin_id]
    else
        return false
    end

    if haskey(bus_stops, destination_id)
        bus_stop_destination = bus_stops[destination_id]
    else
        return false
    end

    if haskey(bus_stops_dict, bus_stop_origin)
        origin_node = bus_stops_dict[ bus_stops[origin_id] ]

        if haskey(bus_stops_dict, bus_stop_destination)
            destination_node = bus_stops_dict[ bus_stop_destination ]

            # iterate through the segments, must find an easy way of doing this...
            
            record.hops = 0
            current_node = origin_node
            while current_node != destination_node
                current_node = current_node.next
                record.hops += 1
                
                if record.hops > 1000
                    return false
                end
            end # end while loop
            return true
        else
            return false
        end
    else
        return false
    end
end

function print_edge_speeds(sigma2::Float64, bus_stops::Dict{Int64, Bus_Stop}, bus_services::Dict{ASCIIString, Bus_Service}, bus_no::ASCIIString)
    bus_service = bus_services[bus_no]

    for direction=1:2
        if !isdefined(bus_service.routes, direction)
            continue
        else
            @printf("Direction_%d\n", direction)
        end
        
        route = bus_service.routes[direction] # route is List
        node = route.head # obtained linked list node that contains bus stops
        
        current_node = node.next
        while current_node != node

            bus_stop_prev = node.bus_stop
            bus_stop_next = current_node.bus_stop

            edge = bus_stop_prev.edges[bus_stop_next]

            @printf("%d -> %d: d=%f c=%f sigma2=%f\n", bus_stop_prev.id, bus_stop_next.id, edge.distance, edge.speed, edge.distance * sigma2)

            #check whether the linkedlist have gone circular
            if current_node == route.head
                break
            end
            
            node = current_node
            current_node = current_node.next
        end
    end
end

function summation_time(origin_node::List_Node, destination_node::List_Node)
    tmp = 0.0
    current_node = origin_node
    while current_node != destination_node

        src_bus_stop = current_node.bus_stop 
        tar_bus_stop = current_node.next.bus_stop

        edge = src_bus_stop.edges[tar_bus_stop]
        tmp += edge.distance / edge.speed
    
        current_node = current_node.next
    end
    return tmp
end

function calculate_squared_error(records::Array{Record}, 
    bus_stops::Dict{Int64, Bus_Stop}, bus_services::Dict{ASCIIString, Bus_Service})

    squared_error = 0.0
    for record in records
		origin_node, destination_node = get_origin_destination_nodes(record, bus_stops, bus_services)

        # first find the sum of the times
        tmp = summation_time(origin_node, destination_node) #, record.distance)
        
        diff = record.time_taken - tmp

        squared_error += diff * diff
    end # end for loop
    return squared_error
end

function get_origin_destination_nodes(record::Record, 
	bus_stops::Dict{Int64, Bus_Stop}, 
	bus_services::Dict{ASCIIString, Bus_Service})

	# determine the routes
    # get the bus service number
    bus_no = record.bus_no
    bus_service = bus_services[bus_no]
    
    # get the origin and dest
    origin_id = record.origin
    destination_id = record.destination
    
    # distance = record.distance

    # get the direction
    direction = record.direction
    
    # retrieve the list_nodes associated with them
    bus_stops_dict = bus_service.bus_stops[direction]
    
    # @printf("bus: %s, orig: %d, dest: %d, dir: %d\n", bus_no, origin_id, destination_id, direction)

    origin_node      = bus_stops_dict[ bus_stops[origin_id] ]
    destination_node = bus_stops_dict[ bus_stops[destination_id] ]

    return origin_node, destination_node
end

function speed_estimation!(iterations::Int64, records::Array{Record}, 
    bus_stops::Dict{Int64, Bus_Stop}, bus_services::Dict{ASCIIString, Bus_Service}, 
    learning_rate::Float64, tau::Float64, psi::Float64, sigma2::Float64, 
    total_distance::Float64)
    # iteration starts

    # first calculate the total error
    # important to execute this as it will compute and store t_hat in each record
    squared_error = calculate_squared_error(records, bus_stops, bus_services)
    sigma2 = squared_error / total_distance

    time_error = Array(Float64, (iterations + 1, 2))
    time_error[1, :] = [0.0 squared_error]

    for iter=1:iterations
        # shuffle it
        adjusted_learning_rate = learning_rate # / sqrt(iter) # * iter)

        @printf("Iteration: %d/%d", iter, iterations)
        
        tic()
        shuffle!(records) # potentially expensive operation
        shuffle_time_elapsed = toq()
        @printf(", Shuffling: %f (s)", shuffle_time_elapsed)
        flush(STDOUT)

        tic()
        for record in records
            distance = record.distance
			origin_node, destination_node = get_origin_destination_nodes(record, bus_stops, bus_services)

			if origin_node == destination_node
				continue
			end
            
            # stochastic gradient descent of the segment speeds

            # first find the sum of the times
            tmp = summation_time(origin_node, destination_node)

            time_taken = record.time_taken

            current_node = origin_node
            next_node = current_node.next

            src_bus_stop = current_node.bus_stop
            tar_bus_stop = next_node.bus_stop

			next_edge = src_bus_stop.edges[tar_bus_stop]
            while current_node != destination_node
                #get bus stop of node

                edge = next_edge

                dist = edge.distance
                speed = edge.speed

                # deduct from tmp
                tmp2 = tmp - (dist/speed)

                gradient = - ((time_taken-tmp)/(distance*sigma2)) * (dist/(speed*speed)) + (tau/speed)

                # get the speed of next segment
                next_next_node = next_node.next
                if next_node != next_next_node
                    next_edge = next_node.bus_stop.edges[ next_next_node.bus_stop ]
                    gradient -= psi * (speed - next_edge.speed)
                end

                # this is the stochastic gradient descent !!!
                speed += adjusted_learning_rate * gradient

                if speed <= 0.0
                    println("Violate speed constraints!")
                    speed = 0.1
                end
                edge.speed = speed

                # add it back to tmp
                tmp = tmp2 + (dist / speed)

                current_node = next_node
                next_node = next_node.next
            end # end while loop
        end # end for loop
        # calculate the RMSE
        sgd_time_elapsed = toq()
        @printf(", SGD: %f (s)", sgd_time_elapsed)
        
        tic()
        squared_error = calculate_squared_error(records, bus_stops, bus_services)
        time_elapsed = toq()
        @printf(", Sum_Square: %f (s)", time_elapsed)

        time_error[iter + 1, :] = [ (time_error[iter, 1] + shuffle_time_elapsed + sgd_time_elapsed) squared_error ]

        sigma2 = squared_error / total_distance
        @printf(", Error: %e, Sigma2: %f\n", squared_error, sigma2)
        
        flush(STDOUT)
    end # end of this iteration
    return time_error
end

function baseline2(records::Array{Record})

    bus_services_distance = Dict{ASCIIString, Float64}()
    bus_services_time = Dict{ASCIIString, Float64}()

    for record in records
        bus_no = record.bus_no

        dist = get(bus_services_distance, bus_no, 0.0)
        dist += record.distance

        time = get(bus_services_time, bus_no, 0.0)
        time += record.time_taken

        bus_services_time[bus_no]     = time
        bus_services_distance[bus_no] = dist
    end

    bus_services_speed = Dict{ASCIIString, Float64}()
    for tuple in bus_services_distance
        bus_services_speed[ tuple[1] ] = tuple[2] / bus_services_time[ tuple[1] ]
    end

    squared_error = 0.0
    for record in records
        diff = record.time_taken - (record.distance / bus_services_speed[record.bus_no])
        squared_error += diff * diff
    end
    return squared_error, bus_services_speed
end

get_dist(record::Record) = record.distance
get_time(record::Record) = record.time_taken

function get_total_distance(records::Array{Record})
    return mapreduce(get_dist, +, records)
end

function baseline(records::Array{Record})
    sum_distances = mapreduce(get_dist, +, records)
    sum_time = mapreduce(get_time, +, records)

    speed = sum_distances / sum_time

    squared_error = 0.0
    for record in records
        diff = record.time_taken - (record.distance / speed)
        squared_error += diff * diff
    end
    return speed, squared_error, sum_distances
end

function create_k_fold_validation_sets(records::Array{Record}, k_fold::Int64)
    # create the five fold validation sets
    shuffle!(records)
    validation_sets = Array(Array{Record}, k_fold)
    for i=1:k_fold
        validation_sets[i] = Array(Record, 0)
    end

    i = 1
    for record in records
        push!(validation_sets[i], record)
        i = mod(i, k_fold) + 1
    end
    return validation_sets
end
