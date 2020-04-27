# tokenizes and truecases a file


filepath=$1
lang=$2
N_THREADS=12
MOSES=../tools/moses

TOKENIZER=$MOSES/scripts/tokenizer/tokenizer.perl
NORM_PUNC=$MOSES/scripts/tokenizer/normalize-punctuation.perl
TRUECASE_TRAINER=$MOSES/scripts/recaser/train-truecaser.perl
TRUECASER=$MOSES/scripts/recaser/truecase.perl

tokenize () {
    file=$1
    lang=$2
    if ! [[ -f "$file.tok" ]]; then
        cat $file | $NORM_PUNC -l $lang | $TOKENIZER -l $lang -no-escape -threads $N_THREADS > $file.tok
    fi
}

truecase () {
    file_tok=$1
    file_dir="$(dirname "$file_tok")"
    file_name="$(basename "$file_tok")"
    truecase_model=$2
    # Truecase data
        # echo "Training truecasers..."
    if [[ -z "$truecase_model" ]]; then 
        $TRUECASE_TRAINER --model $file_dir/truecaser.$file_name --corpus $file_tok
        $TRUECASER --model $file_dir/truecaser.$file_name < $file_tok > $file_tok.true
    else
        $TRUECASER --model $truecase_model < $file_tok > $file_tok.true
    fi 
}

tt_mono () {
    for num_mono in {100k,1M}; do
        for lang in {de,en}; do
            tokenize ../data/mono/$num_mono.$lang
            truecase ../data/mono/$num_mono.$lang.tok
        done
    done
}

tt_para () {
    size=$1
    # en-de 
    for year in {2015,2016}; do
        for lang in {en,de}; do
            # tokenize ../data/para/newstest$year-ende.$lang 
            ./tokenize_udpipe.sh ../data/para/newstest$year-ende.$lang $lang
            truecase ../data/para/newstest$year-ende.$lang.toku ../data/mono/truecaser.$size.$lang.toku
            ./bpe.sh apply_para ../data/para/newstest$year-ende.$lang.toku.true ../data/mono/bpe_codes_60000.$size.toku.true
        done
    done
}


"$@"
