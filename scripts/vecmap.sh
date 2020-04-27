#!/bin/bash
#SBATCH --time=16:00:00
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --mem=8GB

# module load CUDA/10.0.130
# module load cuDNN
# module load NCCL


src_emb=$2
tgt_emb=$3




vecmap_folder=../tools/vecmap

train () {
    src_filename=$(basename $src_emb)
    src_no_vec=$(echo "${src_filename%.*}")
    src_lang=$(echo $src_no_vec | cut -d. -f2)
    # "${src_no_vec##*.}"

    tgt_filename=$(basename $tgt_emb)
    tgt_no_vec=$(echo "${tgt_filename%.*}")
    tgt_lang=$(echo $tgt_no_vec | cut -d. -f2)

    python $vecmap_folder/map_embeddings.py --unsupervised $src_emb $tgt_emb $src_emb.map.$src_lang-$tgt_lang $tgt_emb.map.$src_lang-$tgt_lang --cuda -v --batch_size 5000
}


train_and_eval () {
    train
    python $vecmap_folder/eval_translation.py $src_emb.map.en-de $tgt_emb.map.en-de -d $vecmap_folder/data/dictionaries/en-de.test.txt.true --p_at 10 # --lower    
}

evaluate () {
    src_filename=$(basename $src_emb)
    lang_pair="${src_filename##*.}"
    python $vecmap_folder/eval_translation.py $src_emb $tgt_emb -d $vecmap_folder/data/dictionaries/$lang_pair.test.txt.true --p_at 10 # --lower
} 

"$@"
