# small script to extract data for a specific service number

#fids = Dict{ASCIIString, IOStream}()

#extract_svc_num = ARGS[1]
#println("Service number to extract: ", extract_svc_num)
# while loop to read in from Standard Input

begin
	while !eof(STDIN)
		line = readline(STDIN)
		#print(line)

		# tokenize this line
		fields = split(line, ['\t', '\n'], false)
		
	 	boarding_loc = fields[9]
	 	if boarding_loc == "?"
	 		continue
	 	end

		alighting_loc = fields[10]
		if alighting_loc == "?"
			continue
		end

		direction = fields[12]
		if direction == "?"
			continue
		end

		distance = fields[14]
		if distance == "?"
			continue
	 	end

		svc_num = fields[11]
		if svc_num == "?"
			continue
		else
			svc_num = convert(ASCIIString, svc_num)
		end

		if fields[7] == "Cash"
			continue
		end

		#time taken
		if parsefloat(fields[15]) <= 0.0
			continue
		end

		date = fields[3]
		datefields = split(date, '/')
		year = datefields[3]
		month = datefields[2]
		day = datefields[1]

		#fid = get!(fids, svc_num, open(string(svc_num, ".txt"), "w"))

		fid = open(string("../data/", year, month, day, "/bus_records/", svc_num, ".txt"), "a")
		#fid = open(string(svc_num, ".txt"), "a")
		write(fid, line)
		close(fid)
		# if svc_num == extract_svc_num
		# 	print(line)
		# end
	end
end
