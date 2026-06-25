FROM python:3.12-slim

WORKDIR /csv-db

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .
COPY shorthand.csv .

EXPOSE 5000

CMD ["python", "app.py"]
