while !eof(STDIN)
	line = readline(STDIN)

	fields = split(line, ['\t', '\n'], false)

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

	boarding_date = fields[3]
	if boarding_date == "?"
		continue
	end

	boarding_time = fields[4]
	if boarding_time == "?"
		continue
	end

	boarding_tm = strptime("%d/%m/%Y %H:%M:%S", string(boarding_date, ' ', boarding_time))

	alighting_date = fields[5]
	if alighting_date == "?"
		continue
	end

	alighting_time = fields[6]
	if alighting_time == "?"
		continue
	end

	alighting_tm = strptime("%d/%m/%Y %H:%M:%S", string(alighting_date, ' ', alighting_time))

	boarding_sec = boarding_tm.hour * 3600 + boarding_tm.min * 60 + boarding_tm.sec
	alighting_sec = alighting_tm.hour * 3600 + alighting_tm.min * 60 + alighting_tm.sec

	println(boarding_loc, '\t', boarding_sec)
	println(alighting_loc, '\t', alighting_sec)
end