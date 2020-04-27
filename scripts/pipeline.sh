size=$2
lang1=en
lang2=de
md=../data/mono

download () {
    ./download_data.sh
}

concat () {
    ./concat_data.sh $size
}

tokenize () {
    #echo "Tokenizing with Moses..."
    #./tokenize_truecase.sh tokenize $md/$size.$lang1 $lang1
    #./tokenize_truecase.sh tokenize $md/$size.$lang2 $lang2
    # produces .tok 

    echo "Tokenizing with UDPIPE..."
    ./tokenize_udpipe.sh $md/$size.$lang1 $lang1
    ./tokenize_udpipe.sh $md/$size.$lang2 $lang2
    # produces .toku 
}

truecase () {
    echo "Truecasing with Moses..."
    # ./tokenize_truecase.sh truecase $md/$size.$lang1.tok
    # ./tokenize_truecase.sh truecase $md/$size.$lang2.tok
    ./tokenize_truecase.sh truecase $md/$size.$lang1.toku
    ./tokenize_truecase.sh truecase $md/$size.$lang2.toku
    # produces .tok.true, .toku.true, and truecase models, e.g. truecaser.1M.de.toku
}

bpe () {
    echo "Learning and applying BPE..."
    # ./bpe.sh learn $md/$size.$lang1.tok.true $md/$size.$lang2.tok.true
    ./bpe.sh learn $md/$size.$lang1.toku.true $md/$size.$lang2.toku.true
    # produces .tok.true.bpe_60000, bpe_codes_60000.100k.tok.true, and vocab.100k.XX.tok.true.bpe_60000
}

para () {
    echo "Processing parallel data..."
    ./tokenize_truecase.sh tt_para $size
}

word2vec () {
    echo "Learning regular word embeddings..."
    # ./word2vec.sh $md/$size.$lang1.tok.true.bpe_60000
    # ./word2vec.sh $md/$size.$lang2.tok.true.bpe_60000
    ./word2vec.sh $md/$size.$lang1.toku.true.bpe_60000
    ./word2vec.sh $md/$size.$lang2.toku.true.bpe_60000
    # produces .tok.true.bpe_60000.vec
}

vecmap () {
    echo "Vecmapping regular embeddings..."
    # ./vecmap.sh train $md/$size.$lang1.tok.true.bpe_60000.vec $md/$size.$lang2.tok.true.bpe_60000.vec
    ./vecmap.sh train $md/$size.$lang1.toku.true.bpe_60000.vec $md/$size.$lang2.toku.true.bpe_60000.vec
    # produces .tok.true.bpe_60000.vec.map.en-de
}

dep_parse () {
    # for parsing which can finish in less than 24h, such as 100k
    echo "Dependency parsing..."
    # python preprocess_stanford.py $md/$size.$lang1.tok
    # python preprocess_stanford.py $md/$size.$lang2.tok
    python preprocess_stanford.py $md/$size.$lang1.toku
    python preprocess_stanford.py $md/$size.$lang2.toku
    # # produces .tok.conllu

    echo "Processing conllu file..."
    # ./process_conllu.sh $md/$size.$lang1.tok.conllu left
    # ./process_conllu.sh $md/$size.$lang2.tok.conllu left
    ./process_conllu.sh $md/$size.$lang1.toku.conllu left
    ./process_conllu.sh $md/$size.$lang2.toku.conllu left
    # produces .tok.conllu.bpe_left_60000

    echo "Learning DP word embeddings..."
    # ./word2vecf.sh $md/$size.$lang1.tok.conllu.bpe_left_60000 
    # ./word2vecf.sh $md/$size.$lang2.tok.conllu.bpe_left_60000
    ./word2vecf.sh $md/$size.$lang1.toku.conllu.bpe_left_60000
    ./word2vecf.sh $md/$size.$lang2.toku.conllu.bpe_left_60000
    # produces .tok.conllu.bpe_left_60000.vec

    echo "Vecmapping DP embeddings..."
    # ./vecmap.sh train $md/$size.$lang1.tok.conllu.bpe_left_60000.vec $md/$size.$lang2.tok.conllu.bpe_left_60000.vec
    ./vecmap.sh train $md/$size.$lang1.toku.conllu.bpe_left_60000.vec $md/$size.$lang2.toku.conllu.bpe_left_60000.vec
    # produces .tok.conllu.bpe_left_60000.vec.map.en-de
}


fast_train () {
    ./fasttext.sh ../data/mono/$size.$lang1.toku.true
    ./fasttext.sh ../data/mono/$size.$lang2.toku.true
    ./fasttext.sh ../data/mono/$size.$lang1.toku.true 256
    ./fasttext.sh ../data/mono/$size.$lang2.toku.true 256
    ./fasttext.sh ../data/mono/$size.$lang1.toku.true.bpe_60000
    ./fasttext.sh ../data/mono/$size.$lang2.toku.true.bpe_60000
    ./fasttext.sh ../data/mono/$size.$lang1.toku.true.bpe_60000 256
    ./fasttext.sh ../data/mono/$size.$lang2.toku.true.bpe_60000 256
}

fast_cat_bli () {
    # testing 256/256 concatenation of Fast+DP/Fast+Reg embeddings for BLI

    python combine_embeddings.py concatenate \
         $md/$size.$lang1.toku.true.fast256.vec \
         $md/$size.$lang1.toku.conllu.true.vec256 \
         $md/$size.$lang1.toku.true.fast_conllu.vec
    python combine_embeddings.py concatenate \
         $md/$size.$lang2.toku.true.fast256.vec \
         $md/$size.$lang2.toku.conllu.true.vec256 \
         $md/$size.$lang2.toku.true.fast_conllu.vec

    python combine_embeddings.py concatenate \
         $md/$size.$lang1.toku.true.fast256.vec \
         $md/$size.$lang1.toku.true.vec256 \
         $md/$size.$lang1.toku.true.fast_reg.vec
    python combine_embeddings.py concatenate \
         $md/$size.$lang2.toku.true.fast256.vec \
         $md/$size.$lang2.toku.true.vec256 \
         $md/$size.$lang2.toku.true.fast_reg.vec

    ./vecmap.sh train \
         $md/$size.$lang1.toku.true.fast_conllu.vec \
         $md/$size.$lang2.toku.true.fast_conllu.vec
    ./vecmap.sh train \
         $md/$size.$lang1.toku.true.fast_reg.vec \
         $md/$size.$lang2.toku.true.fast_reg.vec

    ./vecmap.sh evaluate \
         $md/$size.$lang1.toku.true.fast_conllu.vec.map.en-de \
         $md/$size.$lang2.toku.true.fast_conllu.vec.map.en-de
    ./vecmap.sh evaluate \
         $md/$size.$lang1.toku.true.fast_reg.vec.map.en-de \
         $md/$size.$lang2.toku.true.fast_reg.vec.map.en-de

}


fast_cat_nmt () {
    # testing 256/256 concatenation of Fast+DP/Fast+Reg embeddings for NMT

    python combine_embeddings.py concatenate \
         $md/$size.$lang1.toku.true.bpe_60000.fast256.vec \
         $md/$size.$lang1.toku.conllu.bpe_left_60000.vec256 \
         $md/$size.$lang1.toku.true.bpe_60000.fast_conllu.vec
    python combine_embeddings.py concatenate \
         $md/$size.$lang2.toku.true.bpe_60000.fast256.vec \
         $md/$size.$lang2.toku.conllu.bpe_left_60000.vec256 \
         $md/$size.$lang2.toku.true.bpe_60000.fast_conllu.vec

    python combine_embeddings.py concatenate \
         $md/$size.$lang1.toku.true.bpe_60000.fast256.vec \
         $md/$size.$lang1.toku.true.bpe_60000.vec256 \
         $md/$size.$lang1.toku.true.bpe_60000.fast_reg.vec
    python combine_embeddings.py concatenate \
         $md/$size.$lang2.toku.true.bpe_60000.fast256.vec \
         $md/$size.$lang2.toku.true.bpe_60000.vec256 \
         $md/$size.$lang2.toku.true.bpe_60000.fast_reg.vec

    ./vecmap.sh train \
         $md/$size.$lang1.toku.true.bpe_60000.fast_conllu.vec \
         $md/$size.$lang2.toku.true.bpe_60000.fast_conllu.vec
    ./vecmap.sh train \
         $md/$size.$lang1.toku.true.bpe_60000.fast_reg.vec \
         $md/$size.$lang2.toku.true.bpe_60000.fast_reg.vec
}

normal () {
    download
    concat
    tokenize
    truecase
    bpe
    word2vec
    vecmap
    para
    dep_parse
}

fast () {
    fast_train
    fast_cat_bli
    fast_cat_nmt
}


"$@"

