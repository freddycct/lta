include("data_structures.jl")

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

function create_bus_routes_topology(bus_services::Dict{ASCIIString, Bus_Service}, init_speed::Float64)
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
                    #bus_stop_prev.edges = ObjectIdDict()
                    bus_stop_prev.edges = Dict{Bus_Stop, EdgeAbstract}()
                end
                
                #edge = get!(bus_stop_prev.edges, bus_stop_next, Edge(bus_stop_prev, bus_stop_next, node.distance_to_next, init_speed))

                edge = get(bus_stop_prev.edges, bus_stop_next, Edge(bus_stop_prev, bus_stop_next, node.distance_to_next, init_speed))

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
        record.hops = 0
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

#<passenger_id> <type> <date_boarded> <time_boarded> <date_alighted> <time_alighted>
#<card> <card> <origin> <dest> <svc_no> <dir> <dir> <distance> <time_taken>

function read_all_records(prefix::ASCIIString, date::ASCIIString, 
    bus_stops::Dict{Int64, Bus_Stop}, bus_services::Dict{ASCIIString, Bus_Service})

    total_hops = 0
    records = Array(Record, 0)
    fid_success = open(@sprintf("%s/%s/success", prefix, date), "r")
    while !eof(fid_success)
    #for i=1:40
        line = readline(fid_success)
        bus_no = strip(line)
        #bus_no = "7"

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
                total_hops += record.hops
            end
        end
        close(fid_bus)
    end
    close(fid_success)
    return records, total_hops
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
        # determine the routes
        # get the bus service number
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

        origin_node = bus_stops_dict[ bus_stops[origin_id] ]
        destination_node = bus_stops_dict[ bus_stops[destination_id] ]
        
        # first find the sum of the times
        tmp = summation_time(origin_node, destination_node) #, record.distance)
        diff = record.time_taken - tmp

        squared_error += diff * diff
    end # end for loop
    return squared_error
end

function speed_estimation(iterations::Int64, records::Array{Record}, 
    bus_stops::Dict{Int64, Bus_Stop}, bus_services::Dict{ASCIIString, Bus_Service}, 
    eta::Float64, tau::Float64, total_hops::Int64)
    # iteration starts
    for iter=1:iterations
        # shuffle it
        @printf("Iteration: %d/%d", iter, iterations)
        
        tic()
        shuffle!(records) # potentially expensive operation
        time_elapsed = toq()
        @printf(", Shuffling takes: %f secs", time_elapsed)
        flush(STDOUT)

        gc_disable()
        tic()
        for record in records
            # determine the routes
            # get the bus service number
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
       
            origin_node = bus_stops_dict[ bus_stops[origin_id] ]
            destination_node = bus_stops_dict[ bus_stops[destination_id] ]
            
            # stochastic gradient descent of the segment speeds
            # iterate through the segments, must find an easy way of doing this...
            
            # the segments between origin and destination requires SGD update

            # first find the sum of the times
            tmp = summation_time(origin_node, destination_node)
            
            current_node = origin_node
            while current_node != destination_node
                #get bus stop of node
                src_bus_stop = current_node.bus_stop
                tar_bus_stop = current_node.next.bus_stop

                edge = src_bus_stop.edges[tar_bus_stop]

                dist = edge.distance
                speed = edge.speed

                # deduct from tmp
                tmp2 = tmp - (dist/speed)

                # this is the stochastic gradient descent !!!
                speed = speed - eta * ((record.time_taken-tmp)*(dist/(speed*speed))-(tau/speed))
                
                if speed <= 0
                    println("Violate constraints!")
                    edge.speed = 0.1
                    #break
                else
                    edge.speed = speed
                    #println(edge.speed)
                end

                # add it back to tmp
                tmp = tmp2 + (dist / speed)
                current_node = current_node.next
            end # end while loop
        end # end for loop
        # calculate the RMSE
        time_elapsed = toq()
        @printf(", SGD takes: %f secs", time_elapsed)
        #squared_error = calculate_squared_error(records, bus_stops, bus_services)
        #@printf(", per: %f secs\n", time_elapsed / length(records))
        @printf(", per: %e secs\n", time_elapsed / total_hops)
        #@printf(", error: %f\n", squared_error)
        flush(STDOUT)

        gc_enable()
        gc()
    end # end of this iteration
    # loop this iteration
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
    return speed, squared_error
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

function start()
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
        eta = 1e-7
    end

    if isdefined(ARGS, 4)
        tau = parsefloat(ARGS[4])
    else
        tau = 0.1
    end

    if isdefined(ARGS, 5)
        iterations = parseint(ARGS[5])
    else
        iterations = 5
    end

    # first step would be to read in success and store the routes of each bus service in memory
    bus_stops, bus_services = read_bus_routes(prefix, date)

    # Now read all records into memory
    records, total_hops = read_all_records(prefix, date, bus_stops, bus_services)

    println("Number of hops: ", total_hops)

    init_speed, baseline_sum_squared_error = baseline(records)

    println("Initial Speed: ", init_speed)
    println("Baseline Error: ", baseline_sum_squared_error)
    println("Baseline RMSE: ", sqrt(baseline_sum_squared_error / length(records)))

    # get initial speed from baseline
    # init_speed = get_initial_speed(prefix, date)

    # Now construct the topology of the network based on the routes that was read in
    # init_speed = 4.7
    create_bus_routes_topology(bus_services, init_speed)

    speed_estimation(iterations, records, bus_stops, bus_services, eta, tau, total_hops)

    # ta da !
    # calculate the RMSE
    squared_error = calculate_squared_error(records, bus_stops, bus_services)
    rmse = sqrt(squared_error / length(records))
    @printf("RMSE: %f\n", rmse)
end

start()
