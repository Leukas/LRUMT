# fasttext.sh

file_path=$1

FASTTEXT=../tools/fastText/
dim=$2
window_size=$3

if [[ -z $dim ]]; then
    dim=512
    $FASTTEXT/fasttext skipgram -epoch 10 -minCount 0 -dim $dim -thread 10 -ws 10 -neg 20 -input $file_path -output $file_path.fastn
else 
    if [[ -z $window_size ]]; then
        window_size=5
        $FASTTEXT/fasttext skipgram -epoch 10 -minCount 0 -dim $dim -thread 10 -ws $window_size -neg 10 -input $file_path -output $file_path.fast$dim
    else
        $FASTTEXT/fasttext skipgram -epoch 10 -minCount 0 -dim $dim -thread 10 -ws $window_size -neg 10 -input $file_path -output $file_path.fast$dim_"$window_size"
    fi

fi


