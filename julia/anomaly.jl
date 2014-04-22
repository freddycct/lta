require("edgebased.jl")
require("data_structures.jl")

function cmp_record(r1::Record, r2::Record)
    return isless(r1.ratio, r2.ratio)
end

function cmp_record_related_length(r1::Record, r2::Record)
    return isless(length(r1.related_records), length(r2.related_records))
end

function compute_std_ratio!(records::Array{Record}, sigma2::Float64)
    # now determine which are the anomalies
    for record in records
        origin_node, destination_node = get_origin_destination_nodes(record, bus_stops, bus_services)
        record.time_predicted = summation_time(origin_node, destination_node)

        record.estimated_sigma = sqrt(sigma2 * record.distance)
        record.observed_sigma = abs(record.time_taken - record.time_predicted)

        record.ratio = record.observed_sigma / record.estimated_sigma
        if record.time_taken < record.time_predicted
            record.ratio = - record.ratio
        end
    end
end

function is_inside(r1::Record, r2::Record, r1_origin::List_Node, r1_destination::List_Node)
    # tests whether r1 is inside r2
    if r1.hops >= r2.hops
        # simple test
        return false
    elseif time(r1.datetime_board) < time(r2.datetime_board) || time(r1.datetime_alight) > time(r2.datetime_alight)
        # test the time
        return false
    end
    
    # now test whether the route of r1 is inside the route of r2
    seen_r1_origin = false
    seen_r1_dest = false
    
    r2_origin, r2_destination = get_origin_destination_nodes(r2, bus_stops, bus_services)
    current_node = r2_origin
    
    while current_node != r2_destination

        if !seen_r1_origin
            seen_r1_origin = current_node == r1_origin
        end
        
        if !seen_r1_dest
            seen_r1_dest = current_node == r1_destination
        end
        
        if seen_r1_origin && seen_r1_dest
            return true
        end
    
        current_node = current_node.next
    end
    
    if !seen_r1_origin
        seen_r1_origin = current_node == r1_origin
    end
        
    if !seen_r1_dest
        seen_r1_dest = current_node == r1_destination
    end
    
    return seen_r1_origin && seen_r1_dest
end
