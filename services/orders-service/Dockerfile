FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .
COPY orders.db .

EXPOSE 5103

CMD ["python", "app.py"]