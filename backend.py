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
from dotenv import load_dotenv  # Load environment variables

# Load environment variables from .env file
load_dotenv()

# Configure Flask & CORS
app = Flask(__name__)
CORS(app)

# 🛠️ Set up Tesseract dynamically
TESSERACT_PATH = os.getenv("TESSERACT_PATH", "/usr/bin/tesseract")  # Use default for Linux
TESSDATA_PATH = os.getenv("TESSDATA_PATH", "/usr/share/tesseract-ocr/4.00/tessdata")

pytesseract.pytesseract.tesseract_cmd = TESSERACT_PATH
os.environ["TESSDATA_PREFIX"] = TESSDATA_PATH

# 📌 Load YOLO Model dynamically
MODEL_PATH = os.getenv("MODEL_PATH", "assets/trained_model.pt")
model = YOLO(MODEL_PATH)

# 📌 Load API Key from environment variables
API_KEY = os.getenv("API_KEY")

# Create a folder for processed images
PROCESSED_FOLDER = "outputs"
os.makedirs(PROCESSED_FOLDER, exist_ok=True)
