#!/bin/bash
EXP=$1
NUM=$2
N=$3
if [[ ! $EXP ]]; then
    EXP=medium
fi
INTAR="$SCRATCH/librivox/$EXP.tar"
if [[ $NUM ]]; then
    EXP=$EXP.$NUM
fi
if [[ ! $N ]]; then
    N=1
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

echo "############################"
echo "Step 1. Unpack data" && date
echo "############################"

if [[ -s "$INDIR/$EXP" ]]; then
    echo "$INDIR/$EXP exist, skip tar -xf $INTAR $listfile"
elif [[ -s $INTAR ]]; then
    mkdir -p $INDIR
    if [[ $INLST ]]; then
        # tar goes though the whole file, taking too much time
        tar -C $INDIR -xvf $INTAR `cat $INLST` &
        pid=$!
        sleep 60
        # the tar begin with the original name
        PROCESSED=`find $INDIR/$1 -type d | wc -l`
        REQUIRED=`cat $INLST | wc -l`
        # check whether (almost) all directories are extracted
        while [[ $PROCESSED -lt $REQUIRED ]];do
            sleep 60
            PROCESSED=`find $INDIR/$1 -type d | wc -l`
        done
        # wait 1 more min then kill
        sleep 60 && kill -9 $pid
        mv $INDIR/$1 $INDIR/$EXP
    else
        tar -C $INDIR -xvf $INTAR
    fi
else
    echo "input tar does not exist. abort"
    exit 1
fi


echo "############################"
echo "Step 2. Run command" && date
echo "############################"
if [[ -s $OUTTAR ]] && [[ -s "$OUTDIR/$EXP" ]]; then
    echo "$OUTDIR/$EXP exist, skip tar -xf $OUTTAR"
elif [[ -s $OUTTAR ]]; then
    echo "$OUTAR exist, reuse"
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
	--n_workers=$N"

python cut_by_vad.py\
	--input_dir=$INDIR/$EXP\
	--output_dir=$OUTDIR/$EXP\
	--target_len_sec=30\
	--n_workers=$N
stat=$?

if [[ $stat != 0 ]];then
    echo "Fail to run command, exit $stat"
    exit $stat
fi

if [[ ! -s  $OUTDIR/train.tsv ]] || [[ ! -s $OUTDIR/valid.tsv ]]; then
    python $HOME/fairseq/examples/wav2vec/wav2vec_manifest.py\
        $OUTDIR/$EXP\
        --dest $OUTDIR
    sed -i "s;$prefix;;g" $OUTDIR/{train.valid}.tsv
fi

echo "############################"
echo "Step 3. Pack output" && date
echo "############################"
mkdir -p `dirname $OUTTAR`
cd $OUTDIR
echo tar -cvf $OUTTAR $EXP  {train,valid}.tsv
tar -cvf $OUTTAR $EXP  {train,valid}.tsv

# mark done if finished
echo "############################"
touch $DONE
echo "Finished" && date
echo "############################"
