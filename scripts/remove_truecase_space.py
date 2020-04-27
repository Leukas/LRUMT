import sys
from difflib import ndiff

# This fixes an issue with moses truecaser, where it will introduce and/or remove spaces adjacent to a < 
# This only occurs when using a tokenizer besides moses tokenizer


def remove_strange_spaces(input_file, truecased_file, output_file):
    while True:
        il = input_file.readline()
        tl = truecased_file.readline()

        if not il:
            break # EOF

        if il.lower() == tl.lower():
            output_file.write(tl)
        else:
            out = fix(il, tl)
            assert out.lower() == il.lower(), out + "\n" + il
            output_file.write(out)

    print("Done.")
    input_file.close()
    truecased_file.close()
    output_file.close()

def fix(text1, text2):
    output = ""
    i = 0
    j = 0
    while True:
        if i>=len(text1):
            break
        if text1[i].lower() == text2[j].lower():
            output += text2[j]
            j+=1
            i+=1
        elif text1[i] == " ":
            output += " "
            i+=1
        elif text2[j] == " ":
            j+=1
        else:
            assert False, text1[i] + "," + text2[j]
    return output

if __name__ == "__main__":
    print("Fixing truecase spaces...")
    input_file = open(sys.argv[1], 'r')
    truecased_file = open(sys.argv[2], 'r')
    output_file = open(sys.argv[3], 'w')
    remove_strange_spaces(input_file, truecased_file, output_file)
