FROM python:3.11-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       build-essential \
       wget \
       ca-certificates \
       tesseract-ocr \
       libtesseract-dev \
       libleptonica-dev \
       pkg-config \
       libgl1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt /app/
RUN python3 -m pip install --no-cache-dir -r requirements.txt

COPY . /app

RUN mkdir -p /app/outputs

EXPOSE 5000
ENV PORT=5000

CMD ["gunicorn", "backend:app", "--bind", "0.0.0.0:5000", "--workers", "1"]
