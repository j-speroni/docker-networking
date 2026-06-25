"""node2a (branch A): cut vowels."""

VOWELS = ['a', 'e', 'i', 'o', 'u']

def transform(text):
    fin = ""
    for char in text:
        if char not in VOWELS:
            fin += char

    return fin
