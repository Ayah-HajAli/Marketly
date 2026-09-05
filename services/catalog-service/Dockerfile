FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .
COPY pgcompat.py .
COPY catalog.db .

EXPOSE 5102

CMD ["python", "app.py"]