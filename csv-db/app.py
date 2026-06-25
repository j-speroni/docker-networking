# app.py

import csv
from flask import Flask, jsonify, request

app = Flask(__name__)

substitutions = {}

with open("shorthand.csv", newline='', encoding='utf-8') as csvfile:
    reader = csv.DictReader(csvfile)
    for row in reader:
        substitutions[row["word"].lower()] = row["shortened"]


@app.route("/lookup", methods=["POST"])
def lookup():
    data = request.get_json(force=True)

    word = data["word"].lower()

    return jsonify({
        "shortened": substitutions.get(word)
    })


@app.route("/health")
def health():
    return jsonify({"status": "healthy"})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)