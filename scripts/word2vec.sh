# word2vec.sh
# Regular word2vec

file_path=$1

W2V=../tools/word2vecf/
dim=$2
window_size=$3

if [[ -z $dim ]]; then
    dim=512
    $W2V/word2vec -train $file_path -output $file_path.veco -size $dim -negative 10 -threads 10 -sample 1e-5 -iters 1 -window 10 -min-count 1
else 
    if [[ -z $window_size ]]; then
        window_size=5
        $W2V/word2vec -train $file_path -output $file_path.vec$dim -size $dim -negative 10 -threads 10 -sample 1e-5 -iters 10 -window 10 -min-count 1

    else
        $W2V/word2vec -train $file_path -output $file_path.vec$dim_"$window_size" -size $dim -negative 10 -threads 10 -sample 1e-5 -iters 10 -window $window_size -min-count 1
    fi
fi

# $W2V/word2vec -train $file_path -output $file_path.vec10 -size $dim -negative 10 -threads 10 -sample 1e-5 -iters 10 -window 10 -min-count 1
# $W2V/word2vec -train $file_path -output $file_path.vec1 -size $dim -negative 10 -threads 10 -sample 1e-5 -iters 10 -window 1 -min-count 1
# $W2V/word2vec -train $file_path -output $file_path.veclil -size $dim -negative 10 -threads 10 -sample 1e-5 -iters 10 -window 10 -min-count 5
