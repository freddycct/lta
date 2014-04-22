# This file defines some of the data sructures used in various Julia script. It is usually included or required for many other Julia scripts.

type Edge
	src::Int64
	tar::Int64
	speed::Float64
	distance::Float64
	#intensity::Int64

	function Edge(src::Int64, tar::Int64, distance::Float64, speed::Float64)
		edge = new()
		edge.src = src
		edge.tar = tar
		edge.distance = distance
		edge.speed = speed
		edge
	end
end

type Bus_Stop
	id::Int64
	name::ASCIIString
	latitude::Float64
	longitude::Float64
	edges::Dict{Bus_Stop, Edge}

	Bus_Stop(id::Int64) = (bs = new(); bs.id = id; bs)
end

# Define the doubly linked list to store the routes
type List_Node
	bus_stop::Bus_Stop
	bus_stops::Dict{Int64, Bus_Stop}

	next::List_Node
	prev::List_Node

	num_next::Int64
	num_prev::Int64

	distance_to_next::Float64
	distance_to_prev::Float64

	function List_Node(bus_stop::Bus_Stop)
		list_node = new()
		list_node.bus_stop = bus_stop
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
	head::List_Node
	tail::List_Node

	List() = (list = new(); list.num = 0; list)
end

# Define the bus route
type Bus_Service
	svc_num::ASCIIString
	routes::Array{List}
	bus_stops::Array{Dict{Bus_Stop, List_Node}}

	function Bus_Service(num::ASCIIString)
		bs = new()
		bs.svc_num = num

		bs.routes = Array(List, 2)
		bs.bus_stops = Array(Dict{Bus_Stop, List_Node}, 2)
		bs
	end
end

function place_after_bus_stop(start_node::List_Node, end_node::List_Node, distance::Float64)
	start_node.next = end_node
	end_node.prev = start_node

	start_node.distance_to_next = distance
	end_node.distance_to_prev = distance
end

function get_id(node::List_Node)
	ids = collect(keys(node.bus_stops))

	len = length(ids)

	if len == 1
		str = ids[1]
	else
		str = string("(", ids[1])
		for i=2:len-1
			str = string(str, ",", ids[i])
		end
		str = string(str, ",", ids[len], ")")
	end
	return str
end

function create_node(ids_string::ASCIIString, bus_stops_1::Dict{Int64, Bus_Stop}, 
	bus_stops_2::Dict{Bus_Stop, List_Node})
	#handle the case of multiple bus stops in one node
	bus_stop_ids = split(strip(ids_string, ['(', ')']), ',')
	bus_stop_id = parseint(bus_stop_ids[1])

	bus_stop = get(bus_stops_1, bus_stop_id, Bus_Stop(bus_stop_id))
	if !haskey(bus_stops_1, bus_stop_id)
		bus_stops_1[bus_stop_id] = bus_stop
	end
	
	#removed because v0.2.1 does not have get!
	#bus_stop = get!(bus_stops_1, bus_stop_id, Bus_Stop(bus_stop_id))

	if haskey(bus_stops_2, bus_stop)
		node = get(bus_stops_2, bus_stop)
		return node
	else
		#create the linked list node here
		node = List_Node(bus_stop)
		bus_stops_2[bus_stop] = node

		for i=2:length(bus_stop_ids)
			bus_stop_id = parseint(bus_stop_ids[i])

			#removed because v0.2.1 does not have get!
			#bus_stop = get!(bus_stops_1, bus_stop_id, Bus_Stop(bus_stop_id))

			bus_stop = get(bus_stops_1, bus_stop_id, Bus_Stop(bus_stop_id))
			if !haskey(bus_stops_1, bus_stop_id)
				bus_stops_1[bus_stop_id] = bus_stop
			end

			node.bus_stops[bus_stop_id] = bus_stop
			bus_stops_2[bus_stop] = node
		end
		return node
	end
end

function append(bus_service::Bus_Service, direction::Int64, 
	node::List_Node, distance_to_next::Float64)

	list = bus_service.routes[direction]
	dict = bus_service.bus_stops[direction]

	node.distance_to_next = distance_to_next

	if list.num == 0
		list.head = node
	else
		list.tail.next = node
		node.prev = list.tail
		node.distance_to_prev = list.tail.distance_to_next
	end
	list.tail = node
	list.num += 1
end

function merge_nodes(node1::List_Node, node2::List_Node, bus_stops::Dict{Bus_Stop, List_Node})
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
end

function insert_bus_stop(start_node::List_Node, end_node::List_Node, 
	distance::Float64, bus_stops::Dict{Bus_Stop, List_Node})

	if start_node == end_node
		return false
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
			# println(get_id(end_node), " !- ", get_id(start_node.next), " : ", start_node.distance_to_next - distance)
			insert_bus_stop(end_node, start_node.next, start_node.distance_to_next - distance, bus_stops)

			start_node.next = start_node
			start_node.distance_to_next = 0.0

			# println(get_id(start_node), " @- ", get_id(end_node), " : ", distance)
			insert_bus_stop(start_node, end_node, distance, bus_stops)
		else
			# end node should be placed after start_node.next
			# println(get_id(start_node.next), " #- ", get_id(end_node), " : ", distance - start_node.distance_to_next)
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

				# println(get_id(end_node.prev), " !-! ", get_id(start_node), " : ", end_node.distance_to_prev - distance)
				insert_bus_stop(end_node.prev, start_node, end_node.distance_to_prev - distance, bus_stops)

				end_node.prev = end_node
				end_node.distance_to_prev = 0.0

				# after previous insert_bus_stop, the nodes might have merged, so we need to 
				# retrive start_node again.
				start_node = bus_stops[ start_node.bus_stop ]

				# println(get_id(start_node), " *- ", get_id(end_node), " : ", distance)
				insert_bus_stop(start_node, end_node, distance, bus_stops)
			else
				# start_node should be placed before end_node.prev
				# println(get_id(end_node), " *here* ", get_id(end_node.prev))
				# println(get_id(start_node), " ^- ", get_id(end_node.prev), " : ", distance - end_node.distance_to_prev)
				insert_bus_stop(start_node, end_node.prev, distance - end_node.distance_to_prev, bus_stops)
			end
		else
			#println("end_node has no prev")
			# prev is blank, they are adjacent
			place_after_bus_stop(start_node, end_node, distance)
		end
	end
end

function count_node_forward(node::List_Node, origin_node::List_Node)
	if node.num_next == -1
		if node == origin_node
			# circular linked list detected
			# println("Loop detected")
			node.num_next = 0
		elseif node.next != node
			node.num_next = count_node_forward(node.next, origin_node)
		else
			node.num_next = 0
		end
	end
	return 1 + node.num_next
end

function count_node_forward(node::List_Node)
	if node.num_next == -1
		node.num_next = count_node_forward(node.next, node)
	end
	return 1 + node.num_next
end

function count_node_backward(node::List_Node, origin_node::List_Node)
	if node.num_prev == -1
		if node == origin_node
			node.num_prev = 0
		elseif node.prev != node
			node.num_prev = count_node_backward(node.prev, origin_node)
		else
			node.num_prev = 0
		end
	end
	return 1 + node.num_prev
end

function count_node_backward(node::List_Node)
	if node.num_prev == -1
		node.num_prev = count_node_backward(node.prev, node)
	end
	return 1 + node.num_prev
end

function print_node_forward(node::List_Node, origin::List_Node)
	@printf("%s:%.2f, ", get_id(node), node.distance_to_next)
	if node != origin && node.next != node
		print_node_forward(node.next, origin)
	end
end

function print_node_forward(node::List_Node)
	@printf("%s:%.2f, ", get_id(node), node.distance_to_next)
	if node.next != node
		print_node_forward(node.next, node)
	end
end

function print_node_backward(node::List_Node, origin::List_Node)
	@printf("%s:%.2f, ", get_id(node), node.distance_to_prev)
	if node != origin && node.prev != node
		print_node_backward(node.prev, origin)
	end
end

function print_node_backward(node::List_Node)
	@printf("%s:%.2f, ", get_id(node), node.distance_to_prev)
	if node.prev != node
		print_node_backward(node.prev, node)
	end
end

function add_tuple(bus_service::Bus_Service, 
	boarding_bus_stop::Bus_Stop, alighting_bus_stop::Bus_Stop, 
	direction::Int64, distance::Float64)

	if isdefined(bus_service.bus_stops, direction)
		bus_stops = bus_service.bus_stops[direction]
	else
		bus_stops = Dict{Bus_Stop, List_Node}()
		bus_service.bus_stops[direction] = bus_stops
	end

	# retrieve node using direction

	#removed because v0.2.1 does not have get!
	#start_node = get!(bus_stops, boarding_bus_stop, List_Node(boarding_bus_stop))
	#end_node   = get!(bus_stops, alighting_bus_stop, List_Node(alighting_bus_stop))

	start_node = get(bus_stops, boarding_bus_stop, List_Node(boarding_bus_stop))
	if !haskey(bus_stops, boarding_bus_stop)
		bus_stops[boarding_bus_stop] = start_node
	end

	end_node   = get(bus_stops, alighting_bus_stop, List_Node(alighting_bus_stop))
	if !haskey(bus_stops, alighting_bus_stop)
		bus_stops[alighting_bus_stop] = end_node
	end

	insert_bus_stop(start_node, end_node, distance, bus_stops)
end
