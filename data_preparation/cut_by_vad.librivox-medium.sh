#!/bin/bash
#SBATCH --job-name=cut_by_vad
#SBATCH --account=def-bengioy            # Yoshua pays for your job
#SBATCH --nodes=1                        # Ask for a whole node
#SBATCH --ntasks=1                       # Ask for 24 CPUs
#SBATCH --cpus-per-task=24               # Ask for 24 CPUs
#SBATCH --mem-per-cpu=1G                 # Ask for 24 GB of RAM
#SBATCH --time=3:00:00                   # The job will run for 3 hours
#SBATCH --array=0-9%4                    # Run 4 jobs in parallel
#SBATCH -o /scratch/nahwidon/slurm-%j.out# Write the log in $SCRATCH
#SBATCH -e /scratch/nahwidon/slurm-%j.err# Write the err in $SCRATCH

source $HOME/python3.6/bin/activate

part=$(printf "%05d" $SLURM_ARRAY_TASK_ID)
echo "Running task $SLURM_ARRAY_TASK_ID"
echo "SLURM_TMPDIR: $SLURM_TMPDIR"
echo $HOME/libri-light/data_preparation/cut_by_vad.librivox.sh medium $part 24
$HOME/libri-light/data_preparation/cut_by_vad.librivox.sh medium $part 24
