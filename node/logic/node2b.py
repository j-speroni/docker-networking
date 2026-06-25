"""node2b (branch B): only take first letters, retain punctuation"""

PUNCTUATION = ['.', ',', '!', '?', ':', ';']

def transform(text):
    fin = ""
    words = text.split(" ")
    print(words)
    for word in words:
        if len(word) > 0:
            fin += word[0]
            if word[-1] in PUNCTUATION:
                fin += word[-1]

    return fin
