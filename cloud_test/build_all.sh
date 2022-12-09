#! /bin/bash
#script which takes a list of profiles (different flag + module configurations) and builds each one
#binaries are stored in a directory tree at . whith each subdirectory containing the name of its profile

cd .. #move into the above directory for the makefile (I should probably change this to absolute referencing as opposed to relative)

PROFILE_LIST=("gfortran" "intel" "intel_heap" "intel_opt")
PRGENV_LIST=("gnu" "intel" "intel" "intel") #list dictates which compiler should be used for each profile
len=${#PROFILE_LIST[@]}
for ((i = 0 ; i < $len ; i++)); do
	profile=${PROFILE_LIST[$i]}
	prgenv="prgenv/${PRGENV_LIST[$i]}"
	printf "\n\n\nBuilding profile $profile with $prgenv\n\n\n"

	#load required modules
	module load $prgenv netcdf4

	#build the requested profile
	make clean
	make PROFILE=${profile}

	#move binaries to profile subdirectory
	mkdir -p cloud_test/build/${profile}
	mv bin/ecrad* cloud_test/build/${profile}/
done
