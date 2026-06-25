"""node1 (origin): normalize the input — trim and lowercase."""

import requests
import re

def transform(text):
    stripped = text.strip()

    # Split into words and non-words
    tokens = re.findall(r'\w+|[^\w\s]+|\s+', stripped)

    result = []

    for token in tokens:
        # Only attempt replacement on words
        if token.isalnum():
            response = requests.post(
                "http://csv-db:5000/lookup",
                json={"word": token},
                timeout=1
            )

            replacement = response.json()["shortened"]

            if replacement:
                # Preserve capitalization
                if token.isupper():
                    replacement = replacement.upper()
                elif token.istitle():
                    replacement = replacement.capitalize()

                result.append(replacement)
            else:
                result.append(token)
        else:
            result.append(token)

    return ''.join(result)