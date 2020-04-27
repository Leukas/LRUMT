import os
import sys
import stanfordnlp
import argparse

parser = argparse.ArgumentParser(description='Dependency parsing with StanfordNLP')
parser.add_argument("filepath", help="File to parse.")
parser.add_argument("--no_pretok", action='store_true', help="No pretokenization.")
parser.add_argument("--lang", type=str, default="",
                    help="Language. If none then it is assumed to be the 2nd value in a period-delimited file. e.g. file.en ")
parser.add_argument("--out_file_ext", type=str, default=".conllu",
                    help="Output file extension.")
parser.add_argument("--paragraph", action='store_true',
                    help="Input file is in paragraphs, rather than 1 sentence per line.")

def dep_parse(model, text, lang, out_file):    

    doc = model(text)

    for sentence in doc.sentences:
        for word in sentence.words:
            line = ['_']*10
            line[0] = str(word.index)
            line[1] = word.text
            line[6] = str(word.governor)
            line[7] = word.dependency_relation

            out_file.write("\t".join(line)+"\n")
        out_file.write("\n")


if __name__ == "__main__":
    args = parser.parse_args()

    filepath = args.filepath
    lang = os.path.basename(filepath).split('.')[1] if len(args.lang)==0 else args.lang

    out_file = open(filepath+args.out_file_ext, 'w')

    nlp = stanfordnlp.Pipeline(
        processors='tokenize,pos,lemma,depparse', 
        lang=lang, 
        tokenize_pretokenized=not args.no_pretok)

    with open(filepath, 'r') as f:
        done = False
        cur_line = ""

        lines_done = 0
        while not done:
            text = []
            cur_len = 0

            if len(cur_line) > 0:
                text.append(cur_line)
                cur_len += len(cur_line)
                cur_line = ""

            while True:
                cur_line = f.readline()

                # keep batches consistent size, < 5000 chars to avoid mem errors
                if cur_line == "": # EOF
                    done = True
                    break
                elif args.paragraph and cur_line == "\n":
                    break
                elif len(cur_line) + cur_len > 5000:
                    break
                else:
                    text.append(cur_line)
                    cur_len += len(cur_line)
                    cur_line = ""
                
                
            num_sen = len(text)

            if args.paragraph:
                text = "".join(text)
            else:
                text = "\n\n".join(text)
            print("Batch length:", len(text), "\t Sentences: ", num_sen, "\tTotal: ", lines_done, flush=True)

            lines_done+=num_sen

            dep_parse(nlp, text, lang, out_file)
    
