#! /bin/bash
#SBATCH --job-name=ecrad-nproma-search
#SBATCH --qos=np
#SBATCH --nodes=1
#SBATCH --time=0:20:00
#SBATCH --output=ecrad.%j.out
#SBATCH --error=ecrad.%j.out

#compile step
#what flags am I using?

cd /ec/res4/hpcperm/naco/moria/ecrad/cloud_test/

#define some parameters of the machine you're running on. will have be changed for other processors
CPUS_PER_NUMA_REGION=16
CPUS_PER_SOCKET=64
CPUS_PER_NODE=128
NUM_THREADS=($CPUS_PER_NUMA_REGION $CPUS_PER_SOCKET $CPUS_PER_NODE)

#set some runtime parameters
export OMP_SCHEDULE=dynamic #does this work for ecrad too?
NPROMA_SIZES=(1 4 12 32 64 128 256) #how many chunks to break the total workload into
iterations=3
#INPUTS=("era5slice_20000.nc" "era5slice_30000.nc" "era5slice_40000.nc")
INPUTS=("era5slice_20000.nc") #just use the smallest input while searching for optimal NPROMA, performance diff likely to scale linearly over larger inputs anyway

#Only 1 task will be used, bc ecrad does not support mpi

#launch the runs
for thread_count in "${NUM_THREADS[@]}"; do
	for input_data in "${INPUTS[@]}"; do
		for NP in "${NPROMA_SIZES[@]}"; do
			for ((i = 0 ; i < $iterations ; i++)); do
				#test ecrad
				echo "thread_count $thread_count ntasks 1 input $input_data nproma $NP code ecrad"
				srun --hint=nomultithread --cpus-per-task=$thread_count \
					--ntasks=1 env OMP_NUM_THREADS=$thread_count env OMP_PLACES=cores \
					bin/ecrad config_cpu.nam input_data/$input_data output_data/out.nc
				#test ecrad_ifs
				echo "thread_count $thread_count ntasks 1 input $input_data nproma $NP code ecrad_ifs"
				srun --hint=nomultithread --cpus-per-task=$thread_count \
					--ntasks=1 env OMP_NUM_THREADS=$thread_count env OMP_PLACES=cores \
					bin/ecrad config_cpu.nam input_data/$input_data output_data/out.nc
			done
		done
	done
done
