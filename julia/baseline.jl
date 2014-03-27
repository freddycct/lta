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

#go to directory, open the success file

fid_success = open(@sprintf("%s/%s/success", prefix, date), "r")

num_records   = 0
sum_time      = 0.0
sum_distances = 0.0

while !eof(fid_success)
	bus_no = strip(readline(fid_success))

	fid_bus = open(@sprintf("%s/%s/bus_records/%s.txt", prefix, date, bus_no), "r")
	while !eof(fid_bus)
    	line = readline(fid_bus)
    
    	#assume that file does not contain transactions with missing entries
    
    	#obtain the distance traveled and the time taken
    	fields = split(line, ['\t', '\n'], false)
    
	    distance_traveled = parsefloat(fields[14]) * 1000 #store it in meters
    	sum_distances += distance_traveled
    
    	time_taken = parsefloat(fields[15]) * 60 #store it in seconds
    	sum_time += time_taken
    
    	num_records += 1
	end
	close(fid_bus)
end

# now estimate the average speed for every trip.
c = sum_distances / sum_time

@printf("N: %d\n", num_records)
@printf("c: %f\n", c)

# now estimate the sum of squares error

sum_of_squares_error = 0.0

seekstart(fid_success)

while !eof(fid_success)
	bus_no = strip(readline(fid_success))

	fid_bus = open(@sprintf("../data/%s/bus_records/%s.txt", date, bus_no), "r")
	while !eof(fid_bus)
		line = readline(fid_bus)

    	#obtain the distance traveled and the time taken
    	fields = split(line, ['\t', '\n'], false)
    
    	distance_traveled = parsefloat(fields[14]) * 1000 #store it in meters
    	time_taken = parsefloat(fields[15]) * 60 #store it in seconds
    
    	sum_of_squares_error += (time_taken - (distance_traveled / c))^2
	end
	close(fid_bus)
end

sigma2 = sum_of_squares_error / num_records
sigma = sqrt(sigma2)
@printf("sigma: %f\n", sigma)
@printf("rmse: %f\n", sigma)

close(fid_success)
