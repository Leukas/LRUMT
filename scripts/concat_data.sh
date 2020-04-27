# concat_data.sh
# concatenates raw files into one, keeps only sentences with 3-80 words.

data_folder=../data
mono_folder=$data_folder/mono
num_mono=$1

MOSES=../tools/moses
NORM_PUNC=$MOSES/scripts/tokenizer/normalize-punctuation.perl

if [[ $num_mono == *"k" ]]; then
num_mono_number=${num_mono::-1}000
else if [[ $num_mono == *"M" ]]; then
num_mono_number=${num_mono::-1}000000
fi fi 

for lang in {de,en}; do
    concatenated_data=$mono_folder/$num_mono.$lang
    
    # concatenate monolingual data files
    if ! [[ -f "$concatenated_data" ]]; then
    echo "Concatenating monolingual data..."
    cat $(ls $mono_folder/news*$lang* | grep -v gz) | awk '{ if (NF>2 && NF<81) { print } }' | head -n $num_mono_number | $NORM_PUNC -l $lang  > $concatenated_data
    fi
    echo "$lang monolingual data concatenated in: $concatenated_data"
done
