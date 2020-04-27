# Remove entries with non-breaking space
# truecasee
# apply BPE
# fix conllu for BPE (add BPE relation)

file=$1
method=$2 # left, right, frequency, longest, or none (only truecase)
vocab_file=$3 # only needed if method==frequency
filepath=$(dirname $file)
filename=$(basename $file)
lang=$(echo $filename | cut -d. -f2)
size=$(echo $filename | cut -d. -f1)

size_lang_tok=$(echo $filename | cut -d. -f1,2,3 ) # e.g. 1M.de.tok
truecase_model=$filepath/truecaser.$size_lang_tok

echo "Processing conllu..."
cut -f2 < $file | tr '\n' ' ' | sed 's/  /\n/g'  > $file.temp
cat $filepath/$size_lang_tok.true > $file.temp_true
python remove_truecase_space.py $file.temp $file.temp_true $file.temp_fixed
cat $file.temp_fixed | sed 's/$/\n/' | tr ' ' '\n' > $file.temp2

if [[ $method == "none" ]]; then
    python process_conllu.py add_bpe_dep $file $file.temp2 $file.true $method $vocab_file
else
    ./bpe.sh apply $file.temp2 $filepath/bpe_codes_60000.$size.toku.true
    python process_conllu.py add_bpe_dep $file $file.temp2.bpe_60000.$size $file.bpe_"$method"_60000 $method $vocab_file
fi 
rm $file.temp
rm $file.temp_true
rm $file.temp_fixed
rm $file.temp2
