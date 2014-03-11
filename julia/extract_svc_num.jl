# small script to extract data for a specific service number

fids = Dict{ASCIIString, IOStream}()

#extract_svc_num = ARGS[1]
#println("Service number to extract: ", extract_svc_num)
# while loop to read in from Standard Input

while !eof(STDIN)
	line = readline(STDIN)
	#print(line)

	# tokenize this line
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
	else
		svc_num = convert(ASCIIString, svc_num)
	end
	#fid = get!(fids, svc_num, open(string(svc_num, ".txt"), "w"))
	fid = open(string(svc_num, ".txt"), "a")
	write(fid, line)
	close(fid)
	# if svc_num == extract_svc_num
	# 	print(line)
	# end
end

# for fid in values(fids)
# 	close(fid)
# end
