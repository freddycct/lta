# This baseline assumes constant speed for each bus at all times

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

# Go to directory, open the success file

fid_success = open(@sprintf("%s/%s/success", prefix, date), "r")

num_records   = 0

speed_dict = Dict{ASCIIString, Float64}()

while !eof(fid_success)
	bus_no = strip(readline(fid_success))

	sum_time      = 0.0
	sum_distances = 0.0

	fid_bus = open(@sprintf("%s/%s/bus_records/%s.txt", prefix, date, bus_no), "r")
	while !eof(fid_bus)
    	line = readline(fid_bus)
    
    	# Assume that file does not contain transactions with missing entries
    
    	# Obtain the distance traveled and the time taken
    	fields = split(line, ['\t', '\n'], false)
    
	    distance_traveled = parsefloat(fields[14]) * 1000 #store it in meters
    	sum_distances += distance_traveled
    
    	time_taken = parsefloat(fields[15]) * 60 #store it in seconds
    	sum_time += time_taken
    
    	num_records += 1
	end
	close(fid_bus)

	# Now estimate the average speed for every bus
	c = sum_distances / sum_time
	speed_dict[bus_no] = c
end

# @printf("N: %d\n", num_records)
# @printf("c: %f\n", c)

# now estimate the sum of squares error

sum_of_squares_error = 0.0

seekstart(fid_success)
while !eof(fid_success)
	bus_no = strip(readline(fid_success))

	fid_bus = open(@sprintf("../data/%s/bus_records/%s.txt", date, bus_no), "r")

	num_records_bus = 0
	sum_of_squares_error_bus = 0.0

	c = get(speed_dict , bus_no, nan(Float64))
	while !eof(fid_bus)
		line = readline(fid_bus)

    	#obtain the distance traveled and the time taken
    	fields = split(line, ['\t', '\n'], false)
    
    	distance_traveled = parsefloat(fields[14]) * 1000 #store it in meters
    	time_taken = parsefloat(fields[15]) * 60 #store it in seconds
    
		sum_of_squares_error_bus += (time_taken - (distance_traveled / c))^2
    	num_records_bus += 1
	end
	close(fid_bus)
	sum_of_squares_error += sum_of_squares_error_bus

	sigma = sqrt(sum_of_squares_error_bus / num_records_bus)
	@printf("%s: N:%d c:%f sigma:%f\n", bus_no, num_records_bus, c, sigma)
end
close(fid_success)

sigma2 = sum_of_squares_error / num_records
sigma = sqrt(sigma2)

@printf("\nrmse: %f\n", sigma)


