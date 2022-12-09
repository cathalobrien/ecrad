#! /bin/bash
#SBATCH --job-name=ecrad-numa-socket-node-bm
#SBATCH --qos=np
#SBATCH --nodes=1
#SBATCH --time=0:20:00
#SBATCH --output=ecrad.%j.out
#SBATCH --error=ecrad.%j.out


#compile step
#list of profiles (compilers + flags) which will be benchmarked
PROFILE_LIST=("gfortran" "intel" "intel_heap" "intel_opt")
PRGENV_LIST=("gnu" "intel" "intel" "intel") #list dictates which compiler should be used for each profile
BINS=("ecrad_ifs") #list of binaries to be tested

cd /ec/res4/hpcperm/naco/moria/ecrad/cloud_test/

#define some parameters of the machine you're running on. will have be changed for other processors
CPUS_PER_NUMA_REGION=16
CPUS_PER_SOCKET=64
CPUS_PER_NODE=128
NUM_THREADS=($CPUS_PER_NUMA_REGION $CPUS_PER_SOCKET $CPUS_PER_NODE)

#set some runtime parameters
export OMP_SCHEDULE=dynamic #does this work for ecrad too?, anyway I'll put it in bc should help with load balancing of day/night cols
NPROMA_SIZES=(8) #start off with a single NPROMA size to compare node performance
iterations=3
base_input_file="ecrad_meridian"
INPUT_SIZES=("20000" "30000" "40000")
namelist="47r1.nam"

#Only 1 task will be used, bc ecrad does not support mpi

#print a summary of the benchmarking runs
echo "Benchmarking the following profiles: ${PROFILE_LIST[*]}"
echo "Benchmarking the following binaries: ${BINS[*]}"
echo "Benchmarking the following number of CPUs: ${NUM_THREADS[*]}"
echo "Benchmarking the following number of NPROMA values: ${NPROMA_SIZES[*]}"
echo "Benchmarking the following number of input sizes: ${INPUT_SIZES[*]}"
total_runs=$((${#PROFILE_LIST[@]} * ${#BINS[@]} * ${#NUM_THREADS[@]} * ${#NPROMA_SIZES[@]} * ${#INPUT_SIZES[@]}  * $iterations))
echo "Performing each configuration $iterations times, for a total of $total_runs runs"

#launch the runs
for ((profile_id = 0 ; profile_id < ${#PROFILE_LIST[@]} ; profile_id++)); do
	#load the right modules and select the correct build directory for the current profile
	profile=${PROFILE_LIST[$profile_id]}
	prgenv="prgenv/${PRGENV_LIST[$profile_id]}"
	module load $prgenv netcdf4
        build_dir="build/$profile"
        for thread_count in "${NUM_THREADS[@]}"; do
                for input_size in "${INPUT_SIZES[@]}"; do
                        input="input_data/${base_input_file}_${input_size}.nc"
                        for NP in "${NPROMA_SIZES[@]}"; do
                                for binary in "${BINS[@]}"; do
                                        for ((i = 0 ; i < $iterations ; i++)); do
                                                echo "thread_count $thread_count input_size $input_size nproma $NP code $binary profile $profile"
                                                srun --hint=nomultithread --cpus-per-task=$thread_count \
							--ntasks=1 env OMP_NUM_THREADS=$thread_count env OMP_PLACES=cores \
                                                        $build_dir/$binary $namelist $input output_data/out.nc
					done
				done
			done
		done
	done
done
