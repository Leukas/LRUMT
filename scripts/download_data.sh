# downloads, unzips, and assembles monolingual data for english and german.


data_folder=../data
mono_folder=$data_folder/mono
para_folder=$data_folder/para


mkdir -p $data_folder
mkdir -p $mono_folder
mkdir -p $para_folder

MOSES=../tools/moses
INPUT_FROM_SGM=$MOSES/scripts/ems/support/input-from-sgm.perl
REM_NON_PRINT_CHAR=$MOSES/scripts/tokenizer/remove-non-printing-char.perl
NORM_PUNC=$MOSES/scripts/tokenizer/normalize-punctuation.perl


# download monolingual data
for lang in {de,en}; do
    for year in {2007..2010}; do 
        if [ ! -f $mono_folder/news.$year.$lang.shuffled ]; then
            wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.$year.$lang.shuffled.gz -P $mono_folder;
        else 
            echo "$mono_folder/news.$year.$lang.shuffled already downloaded."
        fi
    done
done

# unzip monolingual data
for FILENAME in $mono_folder/news*gz; do
  OUTPUT="${FILENAME::-3}"
  if [ ! -f "$OUTPUT" ]; then
    echo "Decompressing $FILENAME..."
    gunzip $FILENAME
  else
    echo "$OUTPUT already decompressed."
  fi
done


for num_mono in {10M,1M,100k}; do 
    # convert 100k to 100000 etc. 
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
        # cat $(ls $mono_folder/news*$lang* | grep -v gz) | sed '/^.\{10000\}./d' | head -n $num_mono_number | $NORM_PUNC -l $lang  > $concatenated_data
        cat $(ls $mono_folder/news*$lang* | grep -v gz) | awk '{ if (NF>2 && NF<81) { print } }' | head -n $num_mono_number | $NORM_PUNC -l $lang  > $concatenated_data
        # cat $(ls $mono_folder/news*$lang* | grep -v gz) | head -n $num_mono_number > $concatenated_data
        fi
        echo "$lang monolingual data concatenated in: $concatenated_data"
    done
done


# download parallel data for NMT testing
wget -c http://data.statmt.org/wmt17/translation-task/dev.tgz -P $para_folder

# unzip parallel data
if [ ! -d "$para_folder/dev" ]; then 
  tar -xzf $para_folder/dev.tgz
fi 

# move and rename en-de data
$INPUT_FROM_SGM < $para_folder/dev/newstest2015-deen-ref.en.sgm | $NORM_PUNC -l en | $REM_NON_PRINT_CHAR > $para_folder/newstest2015-ende.en 
$INPUT_FROM_SGM < $para_folder/dev/newstest2015-deen-src.de.sgm | $NORM_PUNC -l de | $REM_NON_PRINT_CHAR > $para_folder/newstest2015-ende.de
$INPUT_FROM_SGM < $para_folder/dev/newstest2016-deen-ref.en.sgm | $NORM_PUNC -l en | $REM_NON_PRINT_CHAR > $para_folder/newstest2016-ende.en
$INPUT_FROM_SGM < $para_folder/dev/newstest2016-deen-src.de.sgm | $NORM_PUNC -l de | $REM_NON_PRINT_CHAR > $para_folder/newstest2016-ende.de
