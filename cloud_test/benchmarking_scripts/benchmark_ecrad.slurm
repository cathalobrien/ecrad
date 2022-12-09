#! /bin/bash
#SBATCH --job-name=ecrad-numa-socket-node-bm
#SBATCH --qos=np
#SBATCH --nodes=1
#SBATCH --time=0:2:00
#SBATCH --output=ecrad.%j.out
#SBATCH --error=ecrad.%j.out

export OMP_SCHEDULE=dynamic #does this work for ecrad too?, anyway I'll put it in bc should help with load balancing of day/night cols

#this file contains many variables which define the paramters of this benchmarking run
if [ -z "$1" ]; then #check if config file has been given, if not do a toy run
	echo "usage: sbatch benchmark_ecrad.slurm [bm_config.env]"
	echo "no config provided so doing a simple demo run (see .demo.env)"
	source .demo.env
else #load the provided config file
	source $1
fi

cd /ec/res4/hpcperm/naco/moria/ecrad/cloud_test/ #just makes the addressing slightly shorter

#print a summary of this benchmarking session
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
