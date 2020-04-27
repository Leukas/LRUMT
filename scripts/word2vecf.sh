# Word2vecf

#-------------------
# Peregrine things
module load Miniconda2
module load numpy
# ------------------

W2VF=../tools/word2vecf

conll_filepath=$1
dim=$2


# name=$(echo "${conll_file%.*}")
parent_folder=$(dirname $conll_filepath)
filename=$(basename $conll_filepath)
imd_folder=$parent_folder/word2vecf
mkdir -p $imd_folder

min_word_freq=1
min_ctx_freq=1


vocab_file=$imd_folder/$filename.w2vocab
context_file=$imd_folder/$filename.w2context
word_count_file=$imd_folder/$filename.wv
context_count_file=$imd_folder/$filename.cv

if [[ -z $dim ]]; then
    dim=512
    vec_output=$parent_folder/$filename.vec
else 
    vec_output=$parent_folder/$filename.vec$dim
fi


cut -f 2 $conll_filepath | python $W2VF/scripts/vocab.py $min_word_freq > $vocab_file
cat $conll_filepath | python $W2VF/scripts/extract_deps.py $vocab_file $min_ctx_freq > $context_file
# vocabulary of about 175,000 words, with over 900,000 distinct syntactic contexts


$W2VF/count_and_filter -train $context_file -cvocab $context_count_file -wvocab $word_count_file -min-count $min_ctx_freq

echo "Training embedding..."
$W2VF/word2vecf -train $context_file -cvocab $context_count_file -wvocab $word_count_file -output $vec_output -size $dim -negative 10 -threads 10 -sample 1e-5 -iters 10

# echo "Converting embedding to npy"
# python $W2VF/scripts/vecs2nps.py $vec_output $parent_folder/$file_no_ext.npy



# mv 1M.fr.wv 1M.fr.wv.50.100
# mv 1M.en.wv 1M.en.wv.50.100
# mv 1M.de.wv 1M.de.wv.50.100

# mv 10M.fr.wv 10M.fr.wv.50.100
# mv 10M.en.wv 10M.en.wv.50.100
# mv 10M.de.wv 10M.de.wv.50.100

# mv 100k.fr.wv 100k.fr.wv.50.100
# mv 100k.en.wv 100k.en.wv.50.100
# mv 100k.de.wv 100k.de.wv.50.100

# mv 1M.fr.cv 1M.fr.cv.50.100
# mv 1M.en.cv 1M.en.cv.50.100
# mv 1M.de.cv 1M.de.cv.50.100

# mv 10M.fr.cv 10M.fr.cv.50.100
# mv 10M.en.cv 10M.en.cv.50.100
# mv 10M.de.cv 10M.de.cv.50.100

# mv 100k.fr.cv 100k.fr.cv.50.100
# mv 100k.en.cv 100k.en.cv.50.100
# mv 100k.de.cv 100k.de.cv.50.100
