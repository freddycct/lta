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
                
                distance_to_next = parsefloat(tuple[2])
                node = create_node(tuple[1], bus_stops, bus_service.bus_stops[direction])
                
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
    readline(fid_baseline)
    line = readline(fid_baseline)
    fields = split(line)
    close(fid_baseline)
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
                
                bus_stop_prev = first(values(node.bus_stops))
                bus_stop_next = first(values(current_node.bus_stops))
                
                if !isdefined(bus_stop_prev, :edges)
                    bus_stop_prev.edges = Dict{Bus_Stop, EdgeAbstract}()
                end
                
                edge = get!(bus_stop_prev.edges, bus_stop_next, Edge(bus_stop_prev, bus_stop_next, node.distance_to_next, init_speed))
                
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
    
    origin::Uint16
    destination::Uint16
    
    direction::Uint8
    distance::Float64 #store in meters
    time_taken::Float64 #store in seconds
end

#<passenger_id> <type> <date_boarded> <time_boarded> <date_alighted> <time_alighted>
#<card> <card> <origin> <dest> <svc_no> <dir> <dir> <distance> <time_taken>

function read_all_records(prefix::ASCIIString, date::ASCIIString)
    records = Array(Record, 0)
    fid_success = open(@sprintf("%s/%s/success", prefix, date), "r")
    while !eof(fid_success)
        line = readline(fid_success)
        bus_no = strip(line)
        #bus_no = "7"

        fid_bus = open(@sprintf("%s/%s/bus_records/%s.txt", prefix, date, bus_no), "r")
        while !eof(fid_bus)
            line = readline(fid_bus)
            fields = split(line, ['\t', '\n'], false)
            
            datetime_board = strptime("%d/%m/%Y %H:%M:%S", string(fields[3], ' ', fields[4]))
            datetime_alight = strptime("%d/%m/%Y %H:%M:%S", string(fields[5], ' ', fields[6]))
            
            # get origin, destination
            origin = parseint(fields[9])
            destination = parseint(fields[10])

            # get direction
            direction = parseint(fields[12])

            # get distance
            distance = parsefloat(fields[14])

            # get time taken
            time_taken = parsefloat(fields[15])
            
            record = Record(bus_no, datetime_board, datetime_alight, origin, destination, direction, distance, time_taken)
            push!(records, record)
        end
        close(fid_bus)
    end
    close(fid_success)
    return records
end

function sum_time(origin_node::List_Node, destination_node::List_Node)
    tmp = 0.0
    current_node = origin_node
    while current_node != destination_node
        #get bus stop of node
        src_bus_stop = first(values(current_node.bus_stops))
        tar_bus_stop = first(values(current_node.next.bus_stops))

        edge = src_bus_stop.edges[tar_bus_stop]
        tmp += edge.distance / edge.speed

        current_node = current_node.next
    end
    return tmp
end

function calculate_squared_error(records::Array{Record}, bus_services::Dict{ASCIIString, Bus_Service})
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

        origin_node = bus_stops_dict[ bus_stops[convert(Int64, origin_id)] ]
        destination_node = bus_stops_dict[ bus_stops[convert(Int64, destination_id)] ]
        
        # first find the sum of the times
        tmp = sum_time(origin_node, destination_node)
        diff = record.time_taken - tmp
        diff = diff * diff

        squared_error += diff
    end # end for loop
    return squared_error
end

function speed_estimation(iterations::Int64, records::Array{Record}, 
    bus_services::Dict{ASCIIString, Bus_Service}, eta::Float64, tau::Float64)
    # iteration starts
    for iter=1:iterations
        # shuffle it
        @printf("Iteration: %d/%d", iter, iterations)
        
        tic()
        shuffle!(records) # potentially expensive operation
        
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
       
            origin_node = bus_stops_dict[ bus_stops[convert(Int64, origin_id)] ]
            destination_node = bus_stops_dict[ bus_stops[convert(Int64, destination_id)] ]
            
            # stochastic gradient descent of the segment speeds
            # iterate through the segments, must find an easy way of doing this...
            
            # the segments between origin and destination requires SGD update

            # first find the sum of the times
            tmp = sum_time(origin_node, destination_node)

            current_node = origin_node
            while current_node != destination_node
                #get bus stop of node
                src_bus_stop = first(values(current_node.bus_stops))
                tar_bus_stop = first(values(current_node.next.bus_stops))

                edge = src_bus_stop.edges[tar_bus_stop]                

                # deduct from tmp
                tmp2 = tmp - edge.distance / edge.speed

                # this is the stochastic gradient descent !!!
                edge.speed = edge.speed - eta * ( 2.0 * ( record.time_taken - tmp ) 
                    * ( edge.distance / ( edge.speed * edge.speed ) ) - (tau / edge.speed) )
                
                if edge.speed < 0
                    println("Violate constraints!")
                    edge.speed = 1.0
                    #break
                else
                    #println(edge.speed)
                end

                # add it back to tmp
                tmp = tmp2 + edge.distance / edge.speed

                current_node = current_node.next
            end # end while loop
        end # end for loop
        # calculate the RMSE
        time_elapsed = toq()
        @printf(", time elasped: %f", time_elapsed)
        squared_error = calculate_squared_error(records, bus_services)
        @printf(", error: %f\n", squared_error)
    end # end of this iteration
    # loop this iteration
end

if isdefined(ARGS, 1)
    prefix = ARGS[1]
else
    prefix = "../data"
end

if isdefined(ARGS, 2)
    date = ARGS[2]
else
    date = "20111101"
end

if isdefined(ARGS, 3)
    eta = parsefloat(ARGS[3])
else
    eta = 1e-5
end

if isdefined(ARGS, 4)
    tau = parsefloat(ARGS[4])
else
    tau = 0.0
end

# first step would be to read in success and store the routes of each bus service in memory
bus_stops, bus_services = read_bus_routes(prefix, date)

# get initial speed from baseline
init_speed = get_initial_speed(prefix, date)

# Now construct the topology of the network based on the routes that was read in
create_bus_routes_topology(bus_services, init_speed)

# Now read all records into memory
records = read_all_records(prefix, date)

speed_estimation(10, records, bus_services, eta, tau)

# ta da !
# calculate the RMSE
squared_error = calculate_squared_error(records, bus_services)
rmse = sqrt(squared_error / length(records))
@printf("RMSE: %f\n", rmse)