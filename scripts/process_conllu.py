# Remove entries with non-breaking space
# truecase
# apply BPE
# fix conllu for BPE (add BPE relation)

from collections import defaultdict
import os
import sys
import copy 
import numpy as np

def read_conllu(file, as_string=False):
    """ Reads a sentence in conllu format """
    rows = []
    for i, line in enumerate(file):
        if line.strip() == "":
            break
        elif as_string:
            rows.append(line)
        else: 
            row = line.strip().split("\t")
            rows.append(row)

    if as_string:
        return "".join(rows)
    else:
        return rows


# print(read_conllu(file, as_string=True))


def remove_nbsp(input_file, output_file):
    """ Removes sentences containing words with a non-breaking space """
    num_removed = 0
    while True:
        text = read_conllu(input_file, as_string=True)
        if text == "": #EOF
            break
        elif "\xa0" not in text:
            output_file.write(text+"\n")
        else:
            num_removed+=1

    print(num_removed, "sentences with non-breaking spaces removed.")


def replace_nbsp(input_file, output_file):
    """ Replaces non-breaking spaces with a real space """
    num_replaced = 0
    while True:
        text = read_conllu(input_file, as_string=True)
        if text == "": #EOF
            break
        elif "\xa0" in text:
            text = text.replace("\xa0", " ")
            num_replaced+=1
        output_file.write(text+"\n")

    print(num_replaced, "non-breaking spaces replaced.")


def build_freq_dict(freqs_file):
    freq_dict = defaultdict(int)
    with open(freqs_file, 'r') as f:
        for line in f:
            word, freq = line.split()
            freq_dict[word] = int(freq)
    return freq_dict


def truecase(input_file, truecased_file, output_file):
    con_count = 0
    while True:
        con_count += 1
        if con_count % 10000 == 9999:
            print("Adding BPE dependences to sentence #", con_count+1)
        rows = read_conllu(input_file)
        true_words = read_conllu(truecased_file)    
        if len(true_words)==0: # EOF
            print(con_count)
            break
        
        for i, true_word in enumerate(true_words):
            output_file.write("\t".join([rows[i][0]] + true_word + rows[i][2:]) + "\n")

        output_file.write('\n')

def add_bpe_dep(input_file, bped_file, output_file, method="left", freqs_file=None):
    if method == "none":
        truecase(input_file, bped_file, output_file)
        return

    con_count = 0

    freq_dict = defaultdict(int)
    if method=="frequency":
        if freqs_file is None:
            print("Frequency method requires a frequency file.")
            return
        else:
            freq_dict = build_freq_dict(freqs_file)
            print("Freq dict built.")

    while True:
        con_count += 1
        if con_count % 10000 == 9999:
            print("Adding BPE dependences to sentence #", con_count+1)

        rows = read_conllu(input_file)
        bpes = read_conllu(bped_file)

        if len(bpes)==0: # EOF
            break

        conllu = []
        idx_to_bpe = []
        bpe_count = 1
        for i, bpe in enumerate(bpes):
            
            toks = bpe[0].split(" ")
            if len(toks) > 1:
                # determine root token
                if method == "frequency":
                    tok_freqs = [freq_dict[x] for x in toks]
                    root_idx = np.argmin(tok_freqs)
                elif method == "left":
                    root_idx = 0
                elif method == "right":
                    root_idx = len(toks)-1
                elif method == "longest":
                    tok_lens = [len(x.replace("@@","")) for x in toks]
                    root_idx = np.argmax(tok_lens)

                idx_to_bpe.append(bpe_count+root_idx)

                # connect other tokens to root token
                for j in range(0, len(toks)):
                    if j == root_idx:
                        line = [str(bpe_count+j), toks[root_idx]] + rows[i][2:]
                    else:
                        line = ['_']*10
                        line[0] = str(bpe_count+j)
                        line[1] = toks[j]
                        line[6] = str(bpe_count+root_idx)
                        line[7] = "bpe"

                    conllu.append(line)

                bpe_count+=len(toks)
            else:
                conllu.append([str(bpe_count), bpe[0]] + rows[i][2:])
                idx_to_bpe.append(bpe_count)
                bpe_count+=1

        #resolve references
        res_conllu = copy.deepcopy(conllu)
        for i in idx_to_bpe:
            if int(conllu[i-1][6]) != 0:
                res_conllu[i-1][6] = str(idx_to_bpe[int(conllu[i-1][6])-1])

        for row in res_conllu:
            output_file.write("\t".join(row) + "\n")
        

        output_file.write('\n')





if __name__ == "__main__":
    func = sys.argv[1]


    if func=="remove_nbsp":
        input_file = open(sys.argv[2],'r')
        output_file = open(sys.argv[3],'w')
        remove_nbsp(input_file, output_file)
        input_file.close()
        output_file.close()
    elif func=="add_bpe_dep":
        input_file = open(sys.argv[2],'r')
        bped_file = open(sys.argv[3], 'r')
        output_file = open(sys.argv[4],'w')
        method = sys.argv[5]
        if len(sys.argv) >= 7:
            vocab_file = sys.argv[6]
        else:
            vocab_file = None
        add_bpe_dep(input_file, bped_file, output_file, method=method, freqs_file=vocab_file)
        input_file.close()
        output_file.close()
    else:
        print("ERROR: Choose one: (remove_nbsp/add_bpe_dep)")
