# small script to extract data for a specific service number

extract_svc_num = ARGS[1]
#println("Service number to extract: ", extract_svc_num)

# while loop to read in from Standard Input
while !eof(STDIN)
	line = readline(STDIN)
	#print(line)

	# tokenize this line
	fields = split(line, '\t')
	svc_num = fields[11]
	
	if svc_num == extract_svc_num
		print(line)
	end
end
