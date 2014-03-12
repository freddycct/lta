current_date = ""

while !eof(STDIN)
	line = readline(STDIN)

	fields = split(line, '\t')
	
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
	end

	date = fields[3]

	if date != current_date

		datefields = split(date, '/')
		year = datefields[3]
		month = datefields[2]
		day = datefields[1]

		current_date = date

		if isdefined(Main, :fid)
			close(fid)
		end

		mkdir(string("../data/", year, month, day), 0o755)
		mkdir(string("../data/", year, month, day, "/bus_records/"), 0o755)
		mkdir(string("../data/", year, month, day, "/bus_routes/"), 0o755)
		mkdir(string("../data/", year, month, day, "/logs/"), 0o755)
		
		fid = open(string("../data/", year, month, day, "/date_sorted"), "w")
	end
	write(fid, line)
end

if isdefined(Main, :fid)
	close(fid)
end
