# Currency OCR backend

Minimal Docker quickstart — what the Docker image contains:

- Python runtime and required packages from `requirements.txt`.
- Tesseract OCR and native libraries needed by OpenCV and the model.
- The app runs with Gunicorn serving the Flask API on port 5000.

Before running

- Copy `.env.example` to `.env` and edit values (set `MODEL_PATH` or `API_KEY` if needed):
	```bash
	cp .env.example .env
	# edit .env
	```
- Place the YOLO model file in `assets/` or update `MODEL_PATH` in `.env` to point to it.
- Create outputs folder to persist processed images:
	```bash
	mkdir -p outputs
	```

Run with Docker (single container)

```bash
docker build -t currency-ocr-backend:latest .
docker run --rm -p 5000:5000 \
	--env-file .env \
	-v "$(pwd)/assets:/app/assets" \
	-v "$(pwd)/outputs:/app/outputs" \
	currency-ocr-backend:latest
```

Run with Docker Compose (backend + nginx frontend)

```bash
docker compose up --build
```

Access the app

- Frontend (simple upload UI): http://localhost/ (served by nginx in compose) or http://localhost:5000/ when running single container.
- API: POST `/process_image` with form `image=@file` and optional `currency` field.

Notes

- Do not commit `.env` with secrets. Use an env file or runtime environment variables.
- Large model files are best mounted as volumes instead of baking into the image.

