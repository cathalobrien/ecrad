#! /bin/bash
#SBATCH --job-name=ecrad-nproma-search
#SBATCH --qos=np
#SBATCH --nodes=1
#SBATCH --time=0:20:00
#SBATCH --output=ecrad.%j.out
#SBATCH --error=ecrad.%j.out


#compile step
#what flags am I using?
BINS=("ecrad_ifs") #just test ecrad_ifs bc ecrad doesn't support nproma

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
base_input_file="ecrad_meridian"
INPUT_SIZES=("20000") #just test smallest input size for the impact of NPROMA

#Only 1 task will be used, bc ecrad does not support mpi

#launch the runs
for thread_count in "${NUM_THREADS[@]}"; do
        for input_size in "${INPUT_SIZES[@]}"; do
                input="input_data/${base_input_file}_${input_size}.nc"
                for NP in "${NPROMA_SIZES[@]}"; do
                        for binary in "${BINS[@]}"; do
                                for ((i = 0 ; i < $iterations ; i++)); do
                                        echo "thread_count $thread_count ntasks 1 input_size $input_size nproma $NP code $binary"
                                        srun --hint=nomultithread --cpus-per-task=$thread_count \
                                                --ntasks=1 env OMP_NUM_THREADS=$thread_count env OMP_PLACES=cores \
                                                ../bin/$binary 47r1.nam $input output_data/out.nc $NP
                                done
                        done
                done
        done
done
