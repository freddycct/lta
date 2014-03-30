include("data_structures.jl")

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

# first step would be to read in success and store the routes of each bus service in memory

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

# Now construct the topology of the network based on the routes that was read in

# read the initial speed from the baseline model
init_speed = 4.0 

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

# now read in the data and estimate the speed of each edge
