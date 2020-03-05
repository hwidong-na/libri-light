#!/bin/bash
#SBATCH --account=rpp-bengioy            # Yoshua pays for your job
#SBATCH --cpus-per-task=10               # Ask for 10 CPUs
#SBATCH --gres=gpu:1                     # Ask for 1 GPU
#SBATCH --mem=2G                         # Ask for 2 GB of RAM
#SBATCH --time=3:00:00                   # The job will run for 3 hours
#SBATCH --array=0-9%1                    # Run 10 jobs, 1 parallel
#SBATCH -o /scratch/nahwidon/slurm-%j.out# Write the log in $SCRATCH
#SBATCH -e /scratch/nahwidon/slurm-%j.err# Write the err in $SCRATCH

module load python3.6

virtualenv --no-download $SLURM_TMPDIR/env  # SLURM_TMPDIR is on the compute node
source $SLURM_TMPDIR/env/bin/activate

part=$(printf "%01d" $SLURM_ARRAY_TASK_ID)
echo "Running task $SLURM_ARRAY_TASK_ID"
echo "SLURM_TMPDIR: $SLURM_TMPDIR"
echo $HOME/libri-light/data_preparation/cut_by_vad.librivox.sh medium $part
$HOME/libri-light/data_preparation/cut_by_vad.librivox.sh medium $part
