require("data_structures.jl")

function get_index(tuples::Array{(Float64, Float64)}, index::Int64)
    arr = Array(Float64, 0)
    for tuple in tuples
        push!(arr, tuple[index])
    end
    return arr
end

function get_index(tuples::Array{(Float64, Float64)})
    arr = Array(Float64, 0)
    for tuple in tuples
        push!(arr, tuple[1] / tuple[2])
    end
    return arr
end

function get_sigma(tuples::Array{(Float64, Float64)}, sigma2)
    arr = Array(Float64, 0)
    for (dist, speed) in tuples
        push!(arr, sqrt(dist * sigma2))
    end
    return arr
end

function plot_edge_speeds(bus_no::ASCIIString, direction::Int64, 
    speed_dict_1::Dict{ASCIIString, Array{Array{(Float64, Float64)}}}, 
    speed_dict_2::Dict{ASCIIString, Array{Array{(Float64, Float64)}}},
    bus_stops::Dict{Int64, Bus_Stop}, bus_services::Dict{ASCIIString, Bus_Service}, 
    sigma2_1::Float64, sigma2_2::Float64, fontsize::Float64)

    bus_service = bus_services[bus_no]

    # check whether direction is valid for this bus service
    if !isdefined(bus_service.routes, direction)
        return
    end

    # first get the list of bus stops
    bus_stop_names = Array(ASCIIString, 0)

    route = bus_service.routes[direction] # route is List
    node = route.head # obtained linked list node that contains bus stops
    
    push!(bus_stop_names, node.bus_stop.name)

    while node != node.next
        node = node.next
        push!(bus_stop_names, node.bus_stop.name)
    end

    assert(length(bus_stop_names) == length(speed_dict_1[bus_no][direction]) + 1)
    assert(length(speed_dict_1[bus_no][direction]) == length(speed_dict_2[bus_no][direction]))

    figure()

    plot([1:length(speed_dict_1[bus_no][direction])] .+ 0.5, 
        get_index(speed_dict_1[bus_no][direction], 2), "ro-")
    plot([1:length(speed_dict_2[bus_no][direction])] .+ 0.5, 
        get_index(speed_dict_2[bus_no][direction], 2), "bx--")

    locs = [1:length(bus_stop_names)]
    xticks(locs, bus_stop_names, fontsize=fontsize, rotation=45, ha="right")
    xlim(1, length(bus_stop_names))
    
    grid(true, axis="x")

    #legend(("Edgebased", "Smoothed"))
    ylabel("Speed of Segments (m/s)")
    xlabel("Bus Stops")
    title(@sprintf("Speeds inferred for Bus %s in Direction %d", bus_no, direction))
    tight_layout()
    file_name = @sprintf("%s/%s/bus_speed_%s_%d.pdf", prefix, date, bus_no, direction)
    savefig(file_name, transparent=true)

    figure()

    plot([1:length(speed_dict_1[bus_no][direction])] .+ 0.5, 
        get_index(speed_dict_1[bus_no][direction], 1), "o-")

    locs = [1:length(bus_stop_names)]
    xticks(locs, bus_stop_names, fontsize=fontsize, rotation=45, ha="right")
    xlim(1, length(bus_stop_names))
    
    grid(true, axis="x")

    ylabel("Distance of Segments (m)")
    xlabel("Bus Stops")
    title(@sprintf("Distance of Segments for Bus %s in Direction %d", bus_no, direction))
    tight_layout()
    file_name = @sprintf("%s/%s/bus_dist_%s_%d.pdf", prefix, date, bus_no, direction)
    savefig(file_name, transparent=true)

    figure()

    errorbar([1:length(speed_dict_1[bus_no][direction])] .+ 0.5, 
        get_index(speed_dict_1[bus_no][direction]), 
        yerr=get_sigma(speed_dict_1[bus_no][direction], sigma2_1), color="red")
    errorbar([1:length(speed_dict_2[bus_no][direction])] .+ 0.5, 
        get_index(speed_dict_2[bus_no][direction]), 
        yerr=get_sigma(speed_dict_2[bus_no][direction], sigma2_2), color="blue")

    locs = [1:length(bus_stop_names)]
    xticks(locs, bus_stop_names, fontsize=fontsize, rotation=45, ha="right")
    xlim(1, length(bus_stop_names))
    
    grid(true, axis="x")

    legend(("Edgebased", "Smoothed"))
    ylabel("Time Required for Segments (s)")
    xlabel("Bus Stops")
    title(@sprintf("Time of Segments for Bus %s in Direction %d", bus_no, direction))
    tight_layout()
    file_name = @sprintf("%s/%s/bus_time_%s_%d.pdf", prefix, date, bus_no, direction)
    savefig(file_name, transparent=true)
end
