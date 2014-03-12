date = ""

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

	datefields = split(date, '/')
	println(datefields[3], datefields[2], datefields[1])
end