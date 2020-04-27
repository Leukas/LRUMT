# combine_embeddings.py
import sys
import numpy as np 

def read_emb(file):
    emb = {}
    with open(file, 'r', encoding='UTF-8') as f:
        for i, line in enumerate(f):
            if i == 0:
                continue
            # print(i, line.strip().split(' '))
            word, vals = line.strip().split(' ', 1)
            vals = np.fromstring(vals, sep=' ').astype(np.float32)
            emb[word] = vals
    
    return emb

def write_emb(emb, out_file):
    with open(out_file, 'w') as f:

        num_words = len(emb)
        emb_dim = len(list(emb.values())[0])
        f.write(str(num_words) + " " + str(emb_dim) + "\n")

        for word in emb:
            st = " ".join([word] + ["%1.8f" % val for val in emb[word]])
            f.write(st +"\n")

def concatenate(emb1, emb2):
    cat_emb = {}

    for word in emb1:
        vals = emb1[word]

        if word in emb2:
            vals = np.concatenate((vals, emb2[word]))
        else:
            vals = np.concatenate((vals, np.zeros(len(vals))))
        
        cat_emb[word] = vals

    for word in emb2:
        if word not in cat_emb:
            vals = np.concatenate((np.zeros(len(emb2[word])), emb2[word]))
            cat_emb[word] = vals

    return cat_emb

def add(emb1, emb2):
    sum_emb = {}

    for word in emb1:
        vals = emb1[word]

        if word in emb2:
            vals += emb2[word]
        
        sum_emb[word] = vals

    for word in emb2:
        if word not in sum_emb:
            sum_emb[word] = emb2[word]

    return sum_emb


if __name__ == "__main__":
    method = sys.argv[1]
    file1 = sys.argv[2]
    file2 = sys.argv[3]
    out_file = sys.argv[4]

    print("Reading embs...")
    emb1 = read_emb(file1)
    print("Emb1 read")
    emb2 = read_emb(file2)
    print("Emb2 read")

    new_emb = None
    if method == "concatenate":
        new_emb = concatenate(emb1, emb2)
    elif method == "add":
        new_emb = add(emb1, emb2)

    write_emb(new_emb, out_file)