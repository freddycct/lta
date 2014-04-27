# This script is used to infer the route of each bus

include("data_structures.jl")

function main()
	if isdefined(ARGS, 1)
		prefix = ARGS[1]
	else
		prefix = "."
	end

	# Create the Hash Table to store the bus stops
	bus_stops = Dict{Int64, Bus_Stop}()

	# Create the Hash Table to store the bus services
	bus_services = Dict{ASCIIString, Bus_Service}()

	# Start reading in the file
	line_no = 0
	while !eof(STDIN)
		line_no = line_no + 1
		# println(line_no)

	 	line = readline(STDIN)
	 	#print(line)

	 	# tokenize this line
	 	fields = split(line, ['\t', '\n'], false)
		
		svc_num = fields[11]
		if svc_num == "?"
			continue
		else
			svc_num = ascii(svc_num)
		end
		bus_service = get!(bus_services, svc_num, Bus_Service(svc_num))

	 	boarding_loc = fields[9]
	 	if boarding_loc == "?"
	 		continue
	 	else
	 		boarding_loc = parseint(boarding_loc)
	 	end

		alighting_loc = fields[10]
		if alighting_loc == "?"
			continue
		else
			alighting_loc = parseint(alighting_loc)
		end

		if boarding_loc == alighting_loc
			continue
		end

		direction = fields[12]
		if direction == "?"
			continue
		else
			direction = parseint(direction)
		end

		distance = fields[14]
		if distance == "?"
			continue
		else
	 		distance = parsefloat(distance)
	 	end
		
	 	#retrieve Bus_Stop
	 	boarding_bus_stop  = get!(bus_stops, boarding_loc,  Bus_Stop(boarding_loc))
	 	alighting_bus_stop = get!(bus_stops, alighting_loc, Bus_Stop(alighting_loc))

	 	add_tuple!(bus_service, boarding_bus_stop, alighting_bus_stop, direction, distance)
	end

	# now count the next bus stops each bus stop has and select the head/tail

	for dict_pair1 in bus_services
		bus_service = dict_pair1[2]

		for direction=1:2
			if !isdefined(bus_service.bus_stops, direction)
				continue
			end
			bus_service.routes[direction] = List()
			for dict_pair2 in bus_service.bus_stops[direction]

				node = dict_pair2[2]

				#println("counting forward")
				count_node_forward(node)
				#println("counting backward")
				count_node_backward(node)

				if isdefined(bus_service.routes[direction], :head)
					if bus_service.routes[direction].head.num_next < node.num_next
						bus_service.routes[direction].head = node
					end
				else
					bus_service.routes[direction].head = node
				end

				if isdefined(bus_service.routes[direction], :tail)
					if bus_service.routes[direction].tail.num_prev < node.num_prev
						bus_service.routes[direction].tail = node
					end
				else
					bus_service.routes[direction].tail = node
				end
			end
			bus_service.routes[direction].num = count_node_forward(bus_service.routes[direction].head)

		end
		
		# save to a file
		fid = open(string(prefix, "/", bus_service.svc_num, ".txt"), "w")
		#write(fid, "===Start===\n")
		#write(fid, "{\n\t\"service_no\" :  ")
		num_stops = 0

		for direction=1:2
			if !isdefined(bus_service.bus_stops, direction)
				continue
			end
			node = bus_service.routes[direction].head
			@printf(fid, "Direction_%d: %s:%0.2f", direction, get_id(node), node.distance_to_next)
			num_stops = 1
			current_node = node.next
			while (current_node != node) && (num_stops < 1000)
				@printf(fid, " %s:%0.2f", get_id(current_node), current_node.distance_to_next)
				if current_node == bus_service.routes[direction].head
					println("Loop Detected")
					break
				end
				num_stops += 1
				node = current_node
				current_node = current_node.next
			end
			write(fid, "\n")
		end

		if num_stops >= 1000
			rm(string(prefix, "/", bus_service.svc_num, ".txt"))
		end
		close(fid)
	end
end

main()
