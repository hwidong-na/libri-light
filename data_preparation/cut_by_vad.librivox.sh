#!/bin/bash
EXP=$1
NUM=$2
if [[ ! $EXP ]]; then
    EXP=medium
fi
INTAR="$SCRATCH/librivox/$EXP.tar"
if [[ $NUM ]]; then
    EXP=$EXP.$NUM
fi
# it might be too large to solve at once
# in that case split audio sources
INLST=
if [[ -s "$SCRATCH/librivox/split/$EXP" ]]; then
    INLST="$SCRATCH/librivox/split/$EXP"
fi
OUTTAR="$SCRATCH/librivox-cut/$EXP.tar"

echo "in  : $INTAR"
echo "out : $OUTTAR"

# interactive
if [[ ! $SLURM_TMPDIR ]]; then
SLURM_TMPDIR=/localscratch
fi
df -h $SLURM_TMPDIR

INDIR="$SLURM_TMPDIR/librivox"
OUTDIR="$SLURM_TMPDIR/librivox-cut"
# check if finished
DONE="$SCRATCH/librivox-cut/$EXP.done"
if [[ -s "$DONE" ]] && [[ -s $OUTTAR ]];then
    echo "it seems to be done. terminate"
    exit 0
fi

if [[ -s "$INDIR/$EXP" ]]; then
    echo "$INDIR/$EXP exist, skip tar -xf $INTAR $listfile"
elif [[ -s $INTAR ]]; then
    mkdir -p $INDIR
    if [[ $INLST ]]; then
        tar -C $INDIR -xvf $INTAR `cat $INLST`
        # the tar begin with the original name
        mv $INDIR/$1 $INDIR/$EXP
    else
        tar -C $INDIR -xvf $INTAR
    fi
else
    echo "input tar does not exist. abort"
    exit 1
fi

if [[ -s $OUTTAR ]] && [[ -s "$OUTDIR/$EXP" ]]; then
    echo "$OUTDIR/$EXP exist, skip tar -xf $OUTTAR"
elif [[ -s $OUTTAR ]]; then
    mkdir -p $OUTDIR/$EXP
    cd $OUTDIR/$EXP
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
	--n_workers=10

cd $OUTDIR/$EXP
echo tar -cvf $OUTTAR ./
tar -cvf $OUTTAR ./

# mark done if finished
touch $DONE
