init () {
    filepath=$(dirname $file)
    filename=$(basename $file)

    fast_bpe=../tools/fastBPE/fast 
    num_codes=60000

    size=$(basename $file | cut -d. -f1)
    rest=$(basename $file | cut -d. -f 3-)
}

learn () {
    file=$1
    file2=$2
    init

    echo "Learning BPE codes for $file..."
    $fast_bpe learnbpe $num_codes $file $file2 > $filepath/bpe_codes_$num_codes.$size.$rest
    
    $fast_bpe applybpe $file.bpe_$num_codes $file $filepath/bpe_codes_$num_codes.$size.$rest 
    $fast_bpe applybpe $file2.bpe_$num_codes $file2 $filepath/bpe_codes_$num_codes.$size.$rest 

    get_vocab $file.bpe_$num_codes
    get_vocab $file2.bpe_$num_codes
}

learn_mono () {
    file=$1
    init 

    echo "Learning BPE codes for $file..."
    $fast_bpe learnbpe $num_codes $file > $filepath/bpe_codes_$num_codes.$size.$rest
}

apply () {
    file=$1
    bpe_code_file=$2
    init

    if [[ -z $bpe_code_file ]]; then
        echo "Applying BPE codes to $file..."
        $fast_bpe applybpe $file.bpe_$num_codes $file $filepath/bpe_codes_$num_codes.$size.$rest 
    else
        echo "Applying BPE codes from $bpe_code_file to $file..."
        $fast_bpe applybpe $file.bpe_$num_codes.$size $file $bpe_code_file 
    fi 
}

apply_para () {
    file=$1
    bpe_code_file=$2
    init

    size=$(basename $bpe_code_file | cut -d. -f2)


    echo "Applying BPE codes from $bpe_code_file to $file..."
    $fast_bpe applybpe $file.bpe_$num_codes.$size $file $bpe_code_file 
}

get_vocab () {
    file=$1
    init 

	$fast_bpe getvocab $file > $filepath/vocab.$filename
}

"$@"
