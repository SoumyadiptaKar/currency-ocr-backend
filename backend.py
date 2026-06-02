from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import cv2
import re
import pytesseract
import requests
from ultralytics import YOLO
import os
import numpy as np
import logging
from dotenv import load_dotenv  # For loading environment variables

# Load environment variables from .env file (if running locally)
load_dotenv()

# Configure Flask & CORS
app = Flask(__name__)
CORS(app)

# 🛠️ Set up Tesseract dynamically (no hardcoded paths)
TESSERACT_PATH = os.getenv("TESSERACT_PATH", "/usr/bin/tesseract")  # Default for Linux on Render
TESSDATA_PATH = os.getenv("TESSDATA_PATH", "/usr/share/tesseract-ocr/4.00/tessdata")

pytesseract.pytesseract.tesseract_cmd = TESSERACT_PATH
os.environ["TESSDATA_PREFIX"] = TESSDATA_PATH

# 📌 Load YOLO Model dynamically
MODEL_PATH = os.getenv("MODEL_PATH", "assets/trained_model_100epochs_on_pretrained_model_50epochs.pt")  # Default model path
if not os.path.exists(MODEL_PATH):
    MODEL_URL = os.getenv("MODEL_URL")  # Optional: Load model from a URL if needed
    if MODEL_URL:
        os.system(f"wget {MODEL_URL} -O {MODEL_PATH}")

model = YOLO(MODEL_PATH)

# 📌 Load API Key from environment variables
API_KEY = os.getenv("API_KEY")

# Create a folder for processed images
PROCESSED_FOLDER = "outputs"
os.makedirs(PROCESSED_FOLDER, exist_ok=True)

def fetch_exchange_rates():
    """Fetch the latest exchange rates from API."""
    # Prefer a configured API that may require a key
    if API_KEY:
        url = f"https://v6.exchangerate-api.com/v6/{API_KEY}/latest/USD"
        try:
            response = requests.get(url, timeout=10)
            response.raise_for_status()
            data = response.json()
            return data.get("conversion_rates", {})
        except Exception as e:
            print(f"⚠️ Error fetching exchange rates from exchangerate-api: {e}")

    # Fallback to a free provider that requires no API key
    try:
        resp = requests.get("https://api.exchangerate.host/latest?base=USD", timeout=10)
        resp.raise_for_status()
        data = resp.json()
        # exchangerate.host returns rates under 'rates'
        return data.get("rates", {})
    except Exception as e:
        print(f"⚠️ Error fetching exchange rates from fallback provider: {e}")
        return None

def preprocess_for_ocr(image):
    """Preprocess the image to improve OCR accuracy."""
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    blurred = cv2.GaussianBlur(gray, (5, 5), 0)
    _, binary = cv2.threshold(blurred, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    return binary

def run_ocr(image, price_boxes):
    """Extracts text from detected price regions."""
    extracted_prices = []
    for (x_min, y_min, x_max, y_max, conf) in price_boxes:
        x_min, y_min, x_max, y_max = int(x_min), int(y_min), int(x_max), int(y_max)
        cropped_price = image[y_min:y_max, x_min:x_max]

        if cropped_price.size == 0:
            print(f"⚠️ Empty crop for bounding box: {(x_min, y_min, x_max, y_max)}")
            continue

        processed = preprocess_for_ocr(cropped_price)
        text = pytesseract.image_to_string(processed, config="--psm 6").strip()
        print(f"OCR detected: {text}")
        extracted_prices.append((text, (x_min, y_min, x_max, y_max)))

    return extracted_prices

def filter_prices(extracted_prices):
    """Filters extracted text to retain valid price values."""
    return [(price, bbox) for (price, bbox) in extracted_prices if re.match(r"[\$€₹£¥]?\d+(?:\.\d{1,2})?", price)]

def convert_currency(price, target_currency, exchange_rates):
    """Converts extracted price to the target currency."""
    numeric_value = float(re.sub(r"[^\d.]", "", price))
    if exchange_rates and target_currency in exchange_rates:
        converted_value = numeric_value * exchange_rates[target_currency]
        return f"{converted_value:.2f} {target_currency}"
    else:
        return price  # Return original price if conversion fails

def overlay_converted_prices(image_rgb, price_boxes, target_currency, exchange_rates):
    """Overlay converted prices on image and return updated image."""
    updated_image = image_rgb.copy()
    for (price, (x_min, y_min, x_max, y_max)) in price_boxes:
        converted_price = convert_currency(price, target_currency, exchange_rates)
        cv2.rectangle(updated_image, (x_min, y_min), (x_max, y_max), (255, 255, 255), -1)
        font = cv2.FONT_HERSHEY_SIMPLEX
        font_scale = 0.7
        font_thickness = 2
        text_size = cv2.getTextSize(converted_price, font, font_scale, font_thickness)[0]
        text_x = x_min + (x_max - x_min - text_size[0]) // 2
        text_y = y_min + (y_max - y_min + text_size[1]) // 2
        cv2.putText(updated_image, converted_price, (text_x, text_y), font, font_scale, (0, 0, 0), font_thickness)
    return updated_image

@app.route("/process_image", methods=["POST"])
def process_image():
    """Handles image upload, detection, OCR, currency conversion, and returns updated image."""
    if "image" not in request.files:
        return jsonify({"error": "No image provided"}), 400

    file = request.files["image"]
    target_currency = request.form.get("currency", "INR")

    # Read and preprocess image
    image = cv2.imdecode(np.frombuffer(file.read(), np.uint8), cv2.IMREAD_COLOR)
    image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

    # Run YOLO Detection
    results = model(image)
    price_boxes = []
    for result in results:
        for box in result.boxes.data:
            x_min, y_min, x_max, y_max, conf, cls = map(float, box.tolist())
            class_name = model.names[int(cls)]
            print(f"Detected class: {class_name} at ({x_min}, {y_min}, {x_max}, {y_max}) with confidence {conf:.2f}")
            if class_name == "price_basic":
                price_boxes.append((x_min, y_min, x_max, y_max, conf))

    # Run OCR
    extracted_prices = run_ocr(image, price_boxes)
    valid_prices = filter_prices(extracted_prices)

    # Fetch exchange rates
    exchange_rates = fetch_exchange_rates()

    # Overlay converted prices
    updated_image = overlay_converted_prices(image_rgb, valid_prices, target_currency, exchange_rates)

    # Save the updated image
    output_path = os.path.join(PROCESSED_FOLDER, file.filename)
    cv2.imwrite(output_path, cv2.cvtColor(updated_image, cv2.COLOR_RGB2BGR))
    print(f"✅ Processed image saved at {output_path}")

    # Prepare converted prices and boxes for the response to match the overlaid image
    converted_prices = []
    boxes = []
    for (price, (x_min, y_min, x_max, y_max)) in valid_prices:
        converted = convert_currency(price, target_currency, exchange_rates)
        converted_prices.append(converted)
        boxes.append({
            "price": converted,
            "bbox": [int(x_min), int(y_min), int(x_max), int(y_max)]
        })

    return jsonify({
        "image_url": f"/processed/{file.filename}",
        "prices": converted_prices,
        "boxes": boxes
    })


@app.route("/", methods=["GET"])
def index():
    """Serve the simple frontend."""
    return send_file(os.path.join("static", "index.html"))

@app.route("/processed/<filename>", methods=["GET"])
def get_processed_image(filename):
    """Serves processed image."""
    return send_file(os.path.join(PROCESSED_FOLDER, filename), mimetype="image/jpeg")

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))  # Use Render's assigned port
    app.run(host="0.0.0.0", port=port, debug=True)
