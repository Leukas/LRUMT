# Low-Resource Unsupervised Machine Translation (LRUMT)
This repository contains scripts helpful for reproducing the results in:

Lukas Edman, Antonio Toral, and Gertjan van Noord. 2020. Low-Resource Unsupervised NMT: Diagnosing the Problem and Providing a Linguistically Motivated Solution. *The 22nd Annual Conference of the European Association for Machine Translation (EAMT 2020)*.

### Requirements
- Python 3
- PyTorch (tested on 1.2)
- [Moses](https://github.com/moses-smt/mosesdecoder)
- [fastBPE](https://github.com/glample/fastBPE)
- [UDPipe](http://ufal.mff.cuni.cz/udpipe) (tested on 1.2, with models from [2.4](https://lindat.mff.cuni.cz/repository/xmlui/handle/11234/1-2998))
- [StanfordNLP parser](https://stanfordnlp.github.io/stanfordnlp/)
- [Dependency-based word2vec](https://bitbucket.org/yoavgo/word2vecf/src/default/)
- [fastText](https://github.com/facebookresearch/fastText)
- [VecMap](https://github.com/artetxem/vecmap)
- [UnsupervisedMT](https://github.com/facebookresearch/UnsupervisedMT)

The scripts here assume these are saved (or soft-linked) in the ```tools``` directory on the same level as the ```scripts``` directory, with the following subdirectories:
```
tools/moses/
tools/fastBPE/
tools/udpipe/
tools/word2vecf/
tools/fastText/
tools/vecmap/
tools/unmt/ # points to UnsupervisedMT/NMT/
```
### Example
From the ```scripts``` directory, run: 

```./pipeline.sh normal 1M``` 

This will run all preprocessing steps from downloading the data up to mapping embeddings with vecmap. The "1M" specifies using 1 million sentences per language.

To train the NMT system, run:

```./nmt_system ../data/mono/1M.en ../data/mono/1M.de toku.true.bpe_60000 1M test_run```

This will train an NMT system on 1 million sentences per language, using the pretrained embeddings from the previous step.

### Notes
- Depending on your system, some steps of the preprocessing pipeline may need to be run individually. This is especially the case for the dependency parsing, where we recommended splitting the data into 10000-sentence chunks and dependency parsing the chunks in parallel to speed up the parsing time.
- To evaluate BLI precision at 5 and 10, replace ```eval_translation.py``` from VecMap with our modified version included in ```tools/vecmap/```, and use the flag: ```--p_at 10```. 
