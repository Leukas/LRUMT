UDPIPE_DIR=../tools/udpipe/udpipe-1.2.0-bin/bin-linux64

file=$1
lang=$2

model=""
if [[ $lang == 'de' ]]; then
	model=german-gsd-ud-2.4-190531.udpipe 
else
	model=english-ewt-ud-2.4-190531.udpipe
fi

$UDPIPE_DIR/udpipe --tokenizer=presegmented --output horizontal $UDPIPE_DIR/udpipe_models/$model $1 | cut -f2 > $1.toku
# $UDPIPE_DIR/udpipe --tokenize --output horizontal $UDPIPE_DIR/udpipe_models/$model $1 | cut -f2


