#This script is used to check which bus number has no merges

begin
	readline(STDIN)

	while !eof(STDIN)
		line = readline(STDIN)
		
		fields = split(line)

		size = parseint(fields[5])
		svc_num = fields[9]

		if size <= 0
			println(svc_num)
		end
	end
end

