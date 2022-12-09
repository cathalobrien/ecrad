BEGIN 	{ 
	OFS=",";
	ORS=""
	print "Thread_count, input_size, nproma, program, profile, ecrad_runtime, ecrad_ifs_runtime"
	}
$1 ~ /^thread_count/ {
	thread_count = $2;
	input = $4;
	nproma = $6;
	code = $8;
	profile = $10;
	print "\n" thread_count, input, nproma, code, profile;
	}
$1 ~ /^Time/ {
	runtime = $6
	print "", runtime;
	}
END 	{ 
	print "\n"
	}
