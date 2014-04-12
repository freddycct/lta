# This file contains the stochastic gradient descent algorithm for inferring the speeds of each segment based on the given data.

include("data_structures.jl")

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
            
                #edge = get!(bus_stop_prev.edges, bus_stop_next, Edge(bus_stop_prev, bus_stop_next, node.distance_to_next, init_speed))

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

function read_bus_routes(prefix::ASCIIString, date::ASCIIString)
    # Create the Hash Table to store the bus stops
    bus_stops = Dict{Int64, Bus_Stop}()

    # Create the Hash Table to store the bus services
    bus_services = Dict{ASCIIString, Bus_Service}()

    fid_success = open(@sprintf("%s/%s/success", prefix, date), "r")
    while !eof(fid_success)
        line = readline(fid_success)
        bus_no = strip(line)
        
        # initialize the data structure for storing this route
        bus_service = Bus_Service(bus_no)
        bus_services[bus_no] = bus_service
        
        # now read in the bus routes of bus_no
        fid_bus = open(@sprintf("%s/%s/bus_routes/%s.txt", prefix, date, bus_no), "r")
        while !eof(fid_bus)
            line = readline(fid_bus)
            fields = split(line)
            direction = parseint(split(strip(fields[1], ':'), '_')[2])
            
            # create the data structures to contain this direction
            bus_service.routes[direction]    = List()
            bus_service.bus_stops[direction] = Dict{Bus_Stop, List_Node}()
            
            for i=2:length(fields)
                tuple = split(fields[i], ':')
                
                distance_to_next = parsefloat(tuple[2]) * 1000
                node = create_node(convert(ASCIIString, tuple[1]), bus_stops, bus_service.bus_stops[direction])
                
                append(bus_service, direction, node, distance_to_next)
            end
        end
        close(fid_bus)
    end
    close(fid_success)
    return bus_stops, bus_services
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

function init_edges_speed(bus_stops::Dict{Int64, Bus_Stop}, init_speed::Float64)
    for bus_stop in values(bus_stops)
        if isdefined(bus_stop, :edges)
            for edge in values(bus_stop.edges)
                edge.speed = init_speed
            end
        end
    end
end

function create_bus_routes_topology(bus_services::Dict{ASCIIString, Bus_Service}, init_speed::Float64 = 4.0)
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
                
                #edge = get!(bus_stop_prev.edges, bus_stop_next, Edge(bus_stop_prev, bus_stop_next, node.distance_to_next, init_speed))

                edge = get(bus_stop_prev.edges, bus_stop_next, 
                    Edge(node.distance_to_next, init_speed))

                if !haskey(bus_stop_prev.edges, bus_stop_next)
                    bus_stop_prev.edges[bus_stop_next] = edge
                end
                
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

function check_finite(record::Record, bus_stops::Dict{Int64, Bus_Stop}, bus_services::Dict{ASCIIString, Bus_Service})
    bus_no = record.bus_no
    bus_service = bus_services[bus_no]
    
    # get the origin and dest
    origin_id = record.origin
    destination_id = record.destination
    
    # get the direction
    direction = record.direction
    
    # retrieve the list_nodes associated with them
    bus_stops_dict = bus_service.bus_stops[direction]
    
    #@printf("bus: %s, orig: %d, dest: %d, dir: %d\n", bus_no, origin_id, destination_id, direction)

    bus_stop_origin = bus_stops[origin_id]
    bus_stop_destination = bus_stops[destination_id]

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
            
            #edge = get!(bus_stop_prev.edges, bus_stop_next, Edge(bus_stop_prev, bus_stop_next, node.distance_to_next, init_speed))

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

#<passenger_id> <type> <date_boarded> <time_boarded> <date_alighted> <time_alighted>
#<card> <card> <origin> <dest> <svc_no> <dir> <dir> <distance> <time_taken>

function read_all_records(prefix::ASCIIString, date::ASCIIString, 
    bus_stops::Dict{Int64, Bus_Stop}, bus_services::Dict{ASCIIString, Bus_Service})

    records = Array(Record, 0)
    fid_success = open(@sprintf("%s/%s/success", prefix, date), "r")
    
    while !eof(fid_success)
    #for i=1:10
        line = readline(fid_success)
        bus_no = strip(line)

        fid_bus = open(@sprintf("%s/%s/bus_records/%s.txt", prefix, date, bus_no), "r")
        while !eof(fid_bus)
            line = readline(fid_bus)
            #print(line)

            fields = split(line, ['\t', '\n'], false)
            
            datetime_board = strptime("%d/%m/%Y %H:%M:%S", string(fields[3], ' ', fields[4]))
            datetime_alight = strptime("%d/%m/%Y %H:%M:%S", string(fields[5], ' ', fields[6]))
            
            # get origin, destination
            origin = parseint(fields[9])
            destination = parseint(fields[10])

            # get direction
            direction = parseint(fields[12])

            # get distance
            distance = parsefloat(fields[14]) * 1000

            # get time taken
            time_taken = parsefloat(fields[15]) * 60
            
            record = Record(bus_no, datetime_board, datetime_alight, origin, destination, direction, distance, time_taken)

            # check to ensure that this record terminates, does not go infinite loop
            if check_finite(record, bus_stops, bus_services)
                push!(records, record)
            end
        end
        close(fid_bus)
    end
    close(fid_success)
    return records
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

# function coordinate_descent(iterations::Int64, records::Array{Record},
#     bus_stops::Dict{Int64, Bus_Stop}, bus_services::Dict{ASCIIString, Bus_Service},
#     total_distance::Float64)
    
#     # the coordinate descent algorithm proceeds as follows
    
#     # first create a dictionary containing the edge -> Array of records
#     edge_records_dict = Dict{Edge, Array{Record}}()
#     for record in records
#         bus_no = record.bus_no
#         bus_service = bus_services[bus_no]
            
#         # get the origin and dest
#         origin_id = record.origin
#         destination_id = record.destination
            
#         # get the direction
#         direction = record.direction
            
#         # retrieve the list_nodes associated with them
#         bus_stops_dict = bus_service.bus_stops[direction]
            
#         origin_node = bus_stops_dict[ bus_stops[origin_id] ]
#         destination_node = bus_stops_dict[ bus_stops[destination_id] ]

#         current_node = origin_node
#         while current_node != destination_node

#             src_bus_stop = current_node.bus_stop
#             tar_bus_stop = current_node.next.bus_stop

#             edge = src_bus_stop.edges[tar_bus_stop]

#             edge_records_array = get!(edge_records_dict, edge, Array(Record, 0))
#             push!(edge_records_array, record)

#             current_node = current_node.next
#         end
#     end

#     #@printf("edges: %d\n", length(edge_records_dict))
    
#     squared_error = 0.0
#     for iter=1:iterations

#         @printf("Iteration: %d/%d", iter, iterations)
#         flush(STDOUT)

#         tic()
#         # iterate through all possible edges, this is the core computation of coordinate descent
#         for (edge, edge_records_array) in edge_records_dict
            
#             # for each edge, iterate through all records that goes through the edge    
#             # numerator = number of records that contain edge * distance of edge

#             sum_distances = 0.0 #length(edge_records_array) * edge.distance

#             # denominator = time spent on edge
#             sum_time = 0.0
#             for record in edge_records_array
#                 bus_no = record.bus_no
#                 bus_service = bus_services[bus_no]
                    
#                 # get the origin and dest
#                 origin_id = record.origin
#                 destination_id = record.destination
                    
#                 # get the direction
#                 direction = record.direction
                    
#                 # retrieve the list_nodes associated with them
#                 bus_stops_dict = bus_service.bus_stops[direction]
                    
#                 origin_node = bus_stops_dict[ bus_stops[origin_id] ]
#                 destination_node = bus_stops_dict[ bus_stops[destination_id] ]

#                 time = record.time_taken

#                 current_node = origin_node
#                 while current_node != destination_node
#                     src_bus_stop = current_node.bus_stop
#                     tar_bus_stop = current_node.next.bus_stop

#                     inner_edge = src_bus_stop.edges[tar_bus_stop]
#                     if inner_edge != edge
#                         time -= (inner_edge.distance / inner_edge.speed)
#                     end

#                     if time <= 0.0
#                         break
#                     end

#                     current_node = current_node.next
#                 end
#                 if time > 0.0
#                     sum_distances += edge.distance
#                     sum_time += time
#                 end
#             end

#             speed = sum_distances / sum_time
#             if speed <= 0.0
#                println("Violate speed constraints!")
#                speed = 0.1
#             end
#             edge.speed = speed
#         end
#         time_elapsed = toq()
#         @printf(", CD: %f (s)", time_elapsed)

#         tic()
#         squared_error = calculate_squared_error(records, bus_stops, bus_services)
#         time_elapsed = toq()
#         @printf(", Sum_Square: %f (s)", time_elapsed)

#         sigma2 = squared_error / total_distance
#         @printf(", Error: %e, Sigma2: %f\n", squared_error, sigma2)
        
#         flush(STDOUT)
#     end
#     return squared_error
# end

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
    
    distance = record.distance

    # get the direction
    direction = record.direction
    
    # retrieve the list_nodes associated with them
    bus_stops_dict = bus_service.bus_stops[direction]
    
    # @printf("bus: %s, orig: %d, dest: %d, dir: %d\n", bus_no, origin_id, destination_id, direction)

    origin_node = bus_stops_dict[ bus_stops[origin_id] ]
    destination_node = bus_stops_dict[ bus_stops[destination_id] ]

    return origin_node, destination_node
end

function speed_estimation(iterations::Int64, records::Array{Record}, 
    bus_stops::Dict{Int64, Bus_Stop}, bus_services::Dict{ASCIIString, Bus_Service}, 
    learning_rate::Float64, tau::Float64, psi::Float64, sigma2::Float64, total_distance::Float64)
    # iteration starts

    # first calculate the total error
    # important to execute this as it will compute and store t_hat in each record
    squared_error = calculate_squared_error(records, bus_stops, bus_services)
    sigma2 = squared_error / total_distance

    for iter=1:iterations
        # shuffle it
        adjusted_learning_rate = learning_rate / sqrt(iter) # * iter)

        @printf("Iteration: %d/%d", iter, iterations)
        
        tic()
        shuffle!(records) # potentially expensive operation
        time_elapsed = toq()
        @printf(", Shuffling: %f (s)", time_elapsed)
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
                speed = speed + adjusted_learning_rate * gradient

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
        time_elapsed = toq()
        @printf(", SGD: %f (s)", time_elapsed)
        
        tic()
        squared_error = calculate_squared_error(records, bus_stops, bus_services)
        time_elapsed = toq()
        @printf(", Sum_Square: %f (s)", time_elapsed)

        sigma2 = squared_error / total_distance
        @printf(", Error: %e, Sigma2: %f\n", squared_error, sigma2)
        
        flush(STDOUT)
    end # end of this iteration
    return squared_error
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

function baseline(records::Array{Record})
    sum_time      = 0.0
    sum_distances = 0.0
    for record in records
        sum_distances += record.distance
        sum_time += record.time_taken
    end
    speed = sum_distances / sum_time

    squared_error = 0.0
    for record in records
        diff = record.time_taken - (record.distance / speed)
        squared_error += diff * diff
    end
    return speed, squared_error, sum_distances
end

macro nogc(ex)
  quote
    try
      gc_disable()
      local val = $(esc(ex))
    finally
      gc_enable()
    end
    val
  end
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
