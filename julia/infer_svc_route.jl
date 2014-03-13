# Create a Hash Table to store the Bus_Stop

# Define the bus stop composite type
type Bus_Stop
	id::Int64
	name::ASCIIString
	latitude::Float64
	longitude::Float64

	Bus_Stop(id::Int64) = (bs = new(); bs.id = id; bs)
end

# Define the doubly linked list to store the routes
type ListNode
	#bus_stop::Bus_Stop
	bus_stops::Dict{Int64, Bus_Stop}

	next::ListNode
	prev::ListNode

	num_next::Int64
	num_prev::Int64

	distance_to_next::Float64
	distance_to_prev::Float64

	function ListNode(bus_stop::Bus_Stop)
		list_node = new()
		#list_node.bus_stop = bus_stop
		list_node.bus_stops = Dict{Int64, Bus_Stop}()
		list_node.bus_stops[bus_stop.id] = bus_stop
		list_node.next = list_node
		list_node.prev = list_node
		list_node.num_next = -1
		list_node.num_prev = -1
		list_node.distance_to_next = 0.0
		list_node.distance_to_prev = 0.0
		list_node
	end
end

type List
	num::Int64
	head::ListNode
	tail::ListNode

	List() = (list = new(); list.num = 0; list)
end

# Define the bus route
type Bus_Service
	svc_num::ASCIIString
	routes::Array
	bus_stops::Array

	function Bus_Service(num::ASCIIString)
		bs = new()
		bs.svc_num = num

		bs.routes = Array(List, 2)
		#bs.routes[1] = List()
		#bs.routes[2] = List()
		
		bs.bus_stops = Array(Dict, 2)
		#bs.bus_stops[1] = Dict{Bus_Stop, ListNode}()
		#bs.bus_stops[2] = Dict{Bus_Stop, ListNode}()
		
		bs
	end
end

function place_after_bus_stop(start_node::ListNode, end_node::ListNode, distance::Float64)
	start_node.next = end_node
	end_node.prev = start_node

	start_node.distance_to_next = distance
	end_node.distance_to_prev = distance
end

function get_id(node::ListNode)
	ids = collect(keys(node.bus_stops))

	len = length(ids)

	if len == 1
		return string(ids[1])
	else
		str = string("(", ids[1])
		for i=2:len-1
			str = string(str, ",", ids[i])
		end
		str = string(str, ",", ids[len], ")")
		return str
	end
end

function merge_nodes(node1::ListNode, node2::ListNode, bus_stops::Dict{Bus_Stop, ListNode})
	# add node2 bus stops to node1
	for dict_pair in node2.bus_stops
		node1.bus_stops[ dict_pair[1] ] = dict_pair[2]
		bus_stops[ dict_pair[2] ] = node1
	end

	if node2.next != node2
		# sever the link between node2 and next
		tmp = node2.next
		tmp.prev = tmp
		tmp.distance_to_prev = 0.0

		node2.next = node2
		tmp_distance = node2.distance_to_next

		node2.distance_to_next = 0.0

		insert_bus_stop(node1, tmp, tmp_distance, bus_stops)
		# I wonder if it is necessary to put node2.next between node1 and node1.next
	end

	if node2.prev != node2
		# sever the link between node2 and prev
		tmp = node2.prev
		tmp.next = tmp
		tmp.distance_to_next = 0.0

		node2.prev = node2
		tmp_distance = node2.distance_to_prev

		node2.distance_to_prev = 0.0

		insert_bus_stop(tmp, node1, tmp_distance, bus_stops)
	end

	# println("After merging")
	# print("Forward: ")
	# print_node_forward(node1)
	# println()
	# print("Backward: ")
	# print_node_backward(node1)
	# println()

	# print("Backward: ")
	# print_node_backward(end_node)
	# println()
	# print("Forward: ")
	# print_node_forward(end_node)
	# println()
	# println()
end

function insert_bus_stop(start_node::ListNode, end_node::ListNode, 
	distance::Float64, bus_stops::Dict{Bus_Stop, ListNode})

	if start_node == end_node
		return
	elseif distance < 1e-10 && start_node != end_node
		# the case of two bus stops at the same location
		# try to merge them
		println("Merging ", get_id(start_node), " and ", get_id(end_node))
		# check whether merge is in progress
		merge_nodes(start_node, end_node, bus_stops)
		return
		#println(get_id(start_node), " and ", get_id(end_node), " has to be merged.")
	end

	if start_node.next != start_node
		#println("start_node has next")
		# next has some other bus stop
		# Determine whether end_node is between start_node and start_node.next
		if distance < start_node.distance_to_next
			# end node should be placed between start_node and start_node.next
			# break the edge between start_node and start_node.next
			start_node.next.prev = start_node.next
			start_node.next.distance_to_prev = 0.0
			#println(get_id(end_node), " - ", get_id(start_node.next), " : ", start_node.distance_to_next - distance)
			insert_bus_stop(end_node, start_node.next, start_node.distance_to_next - distance, bus_stops)

			start_node.next = start_node
			start_node.distance_to_next = 0.0
			#println(get_id(start_node), " - ", get_id(end_node), " : ", distance)
			insert_bus_stop(start_node, end_node, distance, bus_stops)
		else
			# end node should be placed after start_node.next
			#println(get_id(start_node.next), " - ", get_id(end_node), " : ", distance - start_node.distance_to_next)
			insert_bus_stop(start_node.next, end_node, distance - start_node.distance_to_next, bus_stops)
		end
	else
		# println("start_node has no next")
		# next is blank
		if end_node.prev != end_node
			#println("end_node has prev")
			# Determine whether start_node is nearer to end_node
			if distance < end_node.distance_to_prev
				#println("place start_node between end_node.prev and end_node")
				# start_node should be placed between end_node.prev and end_node
				end_node.prev.next = end_node.prev
				end_node.prev.distance_to_next = 0.0

				insert_bus_stop(end_node.prev, start_node, end_node.distance_to_prev - distance, bus_stops)

				end_node.prev = end_node
				end_node.distance_to_prev = 0.0

				insert_bus_stop(start_node, end_node, distance, bus_stops)
			else
				# start_node should be placed before end_node.prev
				insert_bus_stop(start_node, end_node.prev, distance - end_node.distance_to_prev, bus_stops)
			end
		else
			#println("end_node has no prev")
			# prev is blank, they are adjacent
			place_after_bus_stop(start_node, end_node, distance)
		end
	end
end

function count_node_forward(node::ListNode, origin_node::ListNode)
	if node.num_next == -1
		if node == origin_node
			# circular linked list detected
			node.num_next = 0
		elseif node.next != node
			node.num_next = count_node_forward(node.next, origin_node)
		else
			node.num_next = 0
		end
	end
	return 1 + node.num_next
end

function count_node_forward(node::ListNode)
	if node.num_next == -1
		#if node.next != node
		node.num_next = count_node_forward(node.next, node)
		#else
		#	node.num_next = 0
		#end
	end
	return 1 + node.num_next
end

function count_node_backward(node::ListNode, origin_node::ListNode)
	if node.num_prev == -1
		if node == origin_node
			# circular linked list detected
			node.num_prev = 0
		elseif node.prev != node
			node.num_prev = count_node_backward(node.prev, origin_node)
		else
			node.num_prev = 0
		end
	end
	return 1 + node.num_prev
end

function count_node_backward(node::ListNode)
	if node.num_prev == -1
		#if node.prev != node
		node.num_prev = count_node_backward(node.prev, node)
		#else
		#	node.num_prev = 0
		#end
	end
	return 1 + node.num_prev
end

function print_node_forward(node::ListNode, origin::ListNode)
	@printf("%s:%.2f, ", get_id(node), node.distance_to_next)
	if node != origin && node.next != node
		print_node_forward(node.next, origin)
	end
end

function print_node_forward(node::ListNode)
	#print(node.bus_stop.id, ":", node.num_next, ", ")
	#print(node.bus_stop.id, ", ")
	@printf("%s:%.2f, ", get_id(node), node.distance_to_next)
	#println("!", get_id(node.next))
	#println("@", get_id(node))
	#if node.next != node
	print_node_forward(node.next, node)
	#end
end

function print_node_backward(node::ListNode, origin::ListNode)
	@printf("%s:%.2f, ", get_id(node), node.distance_to_prev)
	if node != origin && node.prev != node
		print_node_backward(node.prev, origin)
	end
end

function print_node_backward(node::ListNode)
	#print(node.bus_stop.id, ":", node.num_prev, ", ")
	#print(node.bus_stop.id, ", ")
	@printf("%s:%.2f, ", get_id(node), node.distance_to_prev)
	#if node.prev != node
	print_node_backward(node.prev, node)
	#end
end

function add_tuple(bus_service::Bus_Service, 
	boarding_bus_stop::Bus_Stop, alighting_bus_stop::Bus_Stop, 
	direction::Int64, distance::Float64)

	if isdefined(bus_service.bus_stops, direction)
		bus_stops = bus_service.bus_stops[direction]
	else
		bus_stops = Dict{Bus_Stop, ListNode}()
		bus_service.bus_stops[direction] = bus_stops
	end

	# retrieve node using direction
	start_node = get!(bus_stops, boarding_bus_stop, ListNode(boarding_bus_stop))
	end_node   = get!(bus_stops, alighting_bus_stop, ListNode(alighting_bus_stop))

	# if direction == 1
	# 	println("Before adding")
	# 	print("Forward: ")
	# 	print_node_forward(start_node)
	# 	println()
	# 	print("Backward: ")
	# 	print_node_backward(start_node)
	# 	println()

	# 	print("Backward: ")
	# 	print_node_backward(end_node)
	# 	println()
	# 	print("Forward: ")
	# 	print_node_forward(end_node)
	# 	println()
	# 	println()
	# end

	insert_bus_stop(start_node, end_node, distance, bus_stops)

	# if direction == 1
	# 	println("After adding")
	# 	print("Forward: ")
	# 	print_node_forward(start_node)
	# 	println()

	# 	print("Backward: ")
	# 	print_node_backward(end_node)
	# 	println()
	# 	println()
	# end
end

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
	#println(line_no)

 	line = readline(STDIN)
 	#print(line)

 	# tokenize this line
 	fields = split(line, '\t')
	
	svc_num = fields[11]
	if svc_num == "?"
		continue
	else
		svc_num = convert(ASCIIString, svc_num)
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

 	add_tuple(bus_service, boarding_bus_stop, alighting_bus_stop, direction, distance)
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
	write(fid, "===Start===\n")

	num_stops = 0

	for direction=1:2
		if !isdefined(bus_service.bus_stops, direction)
			continue
		end
		node = bus_service.routes[direction].head
		write(fid, string("Direction ", direction, ": ", get_id(node)))
		num_stops = 1
		current_node = node.next
		while (current_node != node) && 
			(current_node != bus_service.routes[direction].head) && (num_stops < 1000)
			write(fid, string(", ", get_id(current_node)))
			num_stops = num_stops + 1
			node = current_node
			current_node = current_node.next
		end
		write(fid, "\n")
	end

	if num_stops < 1000
		write(fid, "===End===\n")
	else
		#delete this file
		rm(string(prefix, "/", bus_service.svc_num, ".txt"))
	end
	close(fid)
end

# println("Printing route 1")
# print_node_forward(bus_service.routes[1].head)
# println()
# print_node_backward(bus_service.routes[1].tail)
# println()

# println("Printing route 2")
# print_node_forward(bus_service.routes[2].head)
# println()
# print_node_backward(bus_service.routes[2].tail)
# println()
