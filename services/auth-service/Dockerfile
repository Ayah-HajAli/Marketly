FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .
COPY pgcompat.py .
COPY users.db .

EXPOSE 5101

CMD ["python", "app.py"]