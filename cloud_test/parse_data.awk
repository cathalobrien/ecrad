BEGIN 	{ 
	OFS=",";
	ORS=""
	print "Thread_count, input_size, nproma, program, ecrad_runtime, ecrad_ifs_runtime"
	}
$1 ~ /^thread_count/ {
	thread_count = $2;
	input = $6;
	nproma = $8;
	code = $10;
	print "\n" thread_count, input, nproma, code;
	}
$1 ~ /^Time/ {
	runtime = $6
	print "", runtime;
	}
END 	{ 
	print "\n"
	}
