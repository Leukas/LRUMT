
unmt_folder=../tools/unmt/

src=$1
tgt=$2
emb_ext=$3 # extension for embedding, e.g. tok.true.bpe_60000
emb_size=$4
exp_name=$5
exp_id=$6

size=$(basename $src | cut -d. -f1)
src_lang=$(basename $src | cut -d. -f2)
tgt_lang=$(basename $tgt | cut -d. -f2)

src_emb=$emb_size.$src_lang.$emb_ext
tgt_emb=$emb_size.$tgt_lang.$emb_ext

tok_type=$(echo $emb_ext | cut -d. -f1)
src_tok=$src.$tok_type.true.bpe_60000
tgt_tok=$tgt.$tok_type.true.bpe_60000

folder=$(dirname $src)
src_base=$(basename $src)
tgt_base=$(basename $tgt)

src_vocab=$folder/vocab.$emb_size.$src_lang.$tok_type.true.bpe_60000
tgt_vocab=$folder/vocab.$emb_size.$tgt_lang.$tok_type.true.bpe_60000

para_path=../data/para
if [[ $src_lang == "en" ]] && [[ $tgt_lang == "de" ]]; then
    src_valid=$para_path/newstest2015-ende.en.$tok_type.true.bpe_60000.$size
    tgt_valid=$para_path/newstest2015-ende.de.$tok_type.true.bpe_60000.$size
    valid_data=$para_path/newstest2015-ende
    src_test=$para_path/newstest2016-ende.en.$tok_type.true.bpe_60000.$size
    tgt_test=$para_path/newstest2016-ende.de.$tok_type.true.bpe_60000.$size
    test_data=$para_path/newstest2016-ende
fi


preprocess () {
    # Generate vocab and pth files (if needed) necessary for running the nmt system 

    if ! [[ -f "$src_vocab" ]]; then
        echo "No vocab files!"
        exit 1

        # echo "Generating vocab files..."
        # cut -d" " -f1 $folder/$src_emb.vec.map.$src_lang-$tgt_lang | sed '1d' | sed "s/$/ 1/" > $src_vocab
        # cut -d" " -f1 $folder/$tgt_emb.vec.map.$src_lang-$tgt_lang | sed '1d' | sed "s/$/ 1/" > $tgt_vocab
    fi

    if ! [[ -f "$src_tok.pth" ]]; then 
        echo "Preprocessing training data..."
        $unmt_folder/preprocess.py $src_vocab $src_tok
        $unmt_folder/preprocess.py $tgt_vocab $tgt_tok
    fi
    if ! [[ -f "$src_valid.pth" ]]; then 
        echo "Preprocessing valid data..."
        $unmt_folder/preprocess.py $src_vocab $src_valid
        $unmt_folder/preprocess.py $tgt_vocab $tgt_valid
    fi
    if ! [[ -f "$src_test.pth" ]]; then 
        echo "Preprocessing test data..."
        $unmt_folder/preprocess.py $src_vocab $src_test
        $unmt_folder/preprocess.py $tgt_vocab $tgt_test
    fi
}


train () {
    if [[ -z $exp_name ]]; then
        exp_name="exp"
    fi
    if ! [[ -z $exp_id ]]; then 
        exp_id="--exp_id "$exp_id
    fi

    lang1=$src_lang
    lang2=$tgt_lang
    # figure out which lang comes first alphabetically:
    if [[ $src_lang > $tgt_lang ]]; then
        src_lang=$lang2
        tgt_lang=$lang1

        swap=$src
        src=$tgt
        tgt=$swap

        src_tok=$src.$tok_type.true.bpe_60000
        tgt_tok=$tgt.$tok_type.true.bpe_60000

        src_emb=$emb_size.$src_lang.$emb_ext
        tgt_emb=$emb_size.$tgt_lang.$emb_ext
    fi

    # determine embedding dimension
    declare -i emb_dim
    emb_dim=$(awk 'NR==2{print NF; exit}' $folder/$src_emb.vec.map.$lang1-$lang2)-1

    python $unmt_folder/main.py --exp_name $exp_name $exp_id --transformer True --batch_size 32 \
    --share_enc 3 --share_dec 3 --share_lang_emb False --share_output_emb False --langs "$src_lang,$tgt_lang" --n_mono -1 \
    --mono_dataset "$src_lang:$src_tok.pth,,;$tgt_lang:$tgt_tok.pth,," \
    --para_dataset "$src_lang-$tgt_lang:,$valid_data.XX.$tok_type.true.bpe_60000.$size.pth,$test_data.XX.$tok_type.true.bpe_60000.$size.pth" \
    --mono_directions "$src_lang,$tgt_lang" --word_shuffle 3 --word_dropout 0.1 --word_blank 0.2 \
    --pivo_directions "$tgt_lang-$src_lang-$tgt_lang,$src_lang-$tgt_lang-$src_lang" \
    --pretrained_emb "$folder/$src_emb.vec.map.$lang1-$lang2,$folder/$tgt_emb.vec.map.$lang1-$lang2" \
    --pretrained_out True --lambda_xe_mono "0:1,100000:0.1,300000:0" --emb_dim $emb_dim \
    --lambda_xe_otfd 1 --otf_num_processes 10 --otf_sync_params_every 1000 --enc_optimizer adam,lr=0.0001 --epoch_size 500000 \
    --stopping_criterion bleu_en_de_valid,10 --lambda_dis 0 --n_dis 0
}

preprocess 
train
