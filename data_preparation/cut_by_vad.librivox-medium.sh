#!/bin/bash
#SBATCH --account=rpp-bengioy            # Yoshua pays for your job
#SBATCH --cpus-per-task=10               # Ask for 10 CPUs
#SBATCH --gres=gpu:1                     # Ask for 1 GPU
#SBATCH --mem=2G                         # Ask for 2 GB of RAM
#SBATCH --time=3:00:00                   # The job will run for 3 hours
#SBATCH -o /scratch/nahwidon/slurm-%j.out# Write the log in $SCRATCH

source $HOME/python3.8/bin/activate

EXP=medium
INTAR="$SCRATCH/librivox/$EXP.tar"
OUTTAR="$SCRATCH/librivox-cut/$EXP.tar"

# interactive
if [[ ! $SLURM_TMPDIR ]]; then
SLURM_TMPDIR=/localscratch
fi
df -h $SLURM_TMPDIR

INDIR="$SLURM_TMPDIR/librivox"
if [[ -s "$INDIR/$EXP" ]]; then
    echo "$INDIR/$EXP exist, skip tar -xf $INTAR"
elif [[ -s $INTAR ]]; then
    mkdir -p $INDIR
    cd $INDIR
    tar -xvf $INTAR
    cd -
fi
OUTDIR="$SLURM_TMPDIR/librivox-cut"
if [[ -s $OUTTAR ]] && [[ -s "$OUTDIR/$EXP" ]]; then
    echo "$OUTDIR/$EXP exist, skip tar -xf $OUTTAR"
elif [[ -s $OUTTAR ]]; then
    mkdir -p $OUTDIR
    cd $OUTDIR
    tar -xvf $OUTTAR
    cd -
fi

cd $HOME/libri-light/data_preparation
echo "\
python cut_by_vad.py\\
	--input_dir=$INDIR/$EXP\\
	--output_dir=$OUTDIR/$EXP\\
	--target_len_sec=30\\
	--n_workers=10"

python cut_by_vad.py\
	--input_dir=$INDIR/$EXP\
	--output_dir=$OUTDIR/$EXP\
	--target_len_sec=30\
	--n_workers=10 &
pid=$!

#copy model files every 10 min whlie the process is running
#prevent any loss due to time limit
while ps -p $pid > /dev/null; do
    sleep 600
    cd $OUTDIR
    tar -uvf $OUTTAR $EXP
    cd -
done

kill -9 $pid
