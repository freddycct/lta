using HDF5, JLD

require("data_structures.jl")

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
                node = create_node(ascii(tuple[1]), bus_stops, 
                    bus_service.bus_stops[direction])
                
                append!(bus_service, direction, node, distance_to_next)
            end
        end
        close(fid_bus)
    end
    close(fid_success)
    return bus_stops, bus_services
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
            if check_finite!(record, bus_stops, bus_services)
                push!(records, record)
            end
        end
        close(fid_bus)
    end
    close(fid_success)
    return records
end

function save_edge_speeds(bus_stops::Dict{Int64, Bus_Stop}, file_name::ASCIIString)
    edges = Array(Edge, 0)
    for (id, src_bus_stop) in bus_stops
    	if isdefined(src_bus_stop, :edges)
        	for (tar_bus_stop, edge) in src_bus_stop.edges
            	push!(edges, edge)
        	end
        end
    end
    @save file_name edges
end

function load_edge_speeds!(bus_stops::Dict{Int64, Bus_Stop}, file_name::ASCIIString)
	@load(file_name, edges)
	for edge in edges
		src_bus_stop = bus_stops[edge.src]
		tar_bus_stop = bus_stops[edge.tar]

		if !isdefined(src_bus_stop, :edges)
			src_bus_stop.edges = Dict{Bus_Stop, Edge}()
		end
		src_bus_stop.edges[tar_bus_stop] = edge
	end
end

function read_bus_stop_id_mapping!(prefix::ASCIIString, bus_stops::Dict{Int64, Bus_Stop})
    fid = open(@sprintf("%s/bus_stop_id_mapping.txt", prefix), "r")
    while !eof(fid)
        line = readline(fid)
        fields = split(line, ['\t', '\n'], false)
        bus_stop_id = parseint(fields[1])
        bus_stop = get!(bus_stops, bus_stop_id, Bus_Stop(bus_stop_id))
        bus_stop.name = ascii(fields[2])
    end
    close(fid)
end
