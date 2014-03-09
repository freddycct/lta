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
	bus_stop::Bus_Stop

	next::ListNode
	prev::ListNode

	num_next::Int64
	num_prev::Int64

	distance_to_next::Float64
	distance_to_prev::Float64

	function ListNode(bus_stop::Bus_Stop)
		list_node = new()
		list_node.bus_stop = bus_stop
		list_node.next = list_node
		list_node.prev = list_node
		list_node.num_next = -1
		list_node.num_prev = -1
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

function insert_bus_stop(start_node::ListNode, end_node::ListNode, distance::Float64)
	if start_node == end_node
		return
	end

	if start_node.next != start_node
		#println("start_node has next")
		# next has some other bus stop
		# Determine whether end_node is between start_node and start_node.next
		if distance < start_node.distance_to_next
			# end node should be placed between start_node and start_node.next
			# break the edge between start_node and start_node.next
			start_node.next.prev = start_node.next
			insert_bus_stop(end_node, start_node.next, start_node.distance_to_next - distance)

			start_node.next = start_node
			insert_bus_stop(start_node, end_node, distance)
		else
			# end node should be placed after start_node.next
			#println(start_node.next.bus_stop.id, "-", end_node.bus_stop.id, ":", distance - start_node.distance_to_next)
			insert_bus_stop(start_node.next, end_node, distance - start_node.distance_to_next)
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
				insert_bus_stop(end_node.prev, start_node, end_node.distance_to_prev - distance)

				end_node.prev = end_node
				insert_bus_stop(start_node, end_node, distance)
			else
				# start_node should be placed before end_node.prev
				insert_bus_stop(start_node, end_node.prev, distance - end_node.distance_to_prev)
			end
		else
			#println("end_node has no prev")
			# prev is blank, they are adjacent
			place_after_bus_stop(start_node, end_node, distance)
		end
	end
end

function count_node_forward(node::ListNode)
	if node.num_next == -1
		#println(node.bus_stop.id, ", ", node.next.bus_stop.id)
		if node.next != node
			#println("recursion!")
			node.num_next = count_node_forward(node.next)
		else
			node.num_next = 0
		end
	end
	#println(node.num_next)
	return 1 + node.num_next
end

function count_node_backward(node::ListNode)
	if node.num_prev == -1
		if node.prev != node
			node.num_prev = count_node_backward(node.prev)
		else
			node.num_prev = 0
		end
	end
	return 1 + node.num_prev
end

function print_node_forward(node::ListNode)
	#print(node.bus_stop.id, ":", node.num_next, ", ")
	#print(node.bus_stop.id, ", ")
	@printf("%d:%.2f, ", node.bus_stop.id, node.distance_to_next)
	if node.next != node
		print_node_forward(node.next)
	end
end

function print_node_backward(node::ListNode)
	#print(node.bus_stop.id, ":", node.num_prev, ", ")
	#print(node.bus_stop.id, ", ")
	@printf("%d:%.2f, ", node.bus_stop.id, node.distance_to_prev)
	if node.prev != node
		print_node_backward(node.prev)
	end
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
	# 	print_node_backward(end_node)
	# 	println()
	# 	println()
	# end

	insert_bus_stop(start_node, end_node, distance)

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

# Create the Hash Table to store the bus stops
bus_stops = Dict{Int64, Bus_Stop}()

# Create the Hash Table to store the bus services
bus_services = Dict{ASCIIString, Bus_Service}()

# Start reading in the file
while !eof(STDIN)
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

	# save to a file
	fid = open(string(bus_service.svc_num, ".txt"), "w")

	for direction=1:2
		if !isdefined(bus_service.bus_stops, direction)
			continue
		end
		bus_service.routes[direction] = List()
		for dict_pair2 in bus_service.bus_stops[direction]

			node = dict_pair2[2]

			count_node_forward(node)
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

		node = bus_service.routes[direction].head
		write(fid, string("Direction ", direction, ": ", node.bus_stop.id))
		current_node = node.next
		while current_node != node
			write(fid, string(", ", current_node.bus_stop.id))
			node = current_node
			current_node = current_node.next
		end
		write(fid, "\n")
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
