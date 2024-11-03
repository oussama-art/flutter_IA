from flask import Flask, request, jsonify
from flask_cors import CORS
from transformers import AutoImageProcessor, SegformerForSemanticSegmentation
import numpy as np
from PIL import Image
import torch
import logging


# Configure logging
logging.basicConfig(level=logging.DEBUG)

# Initialize Flask app
app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Load the model and image processor
processor = AutoImageProcessor.from_pretrained("mattmdjaga/segformer_b2_clothes")
model = SegformerForSemanticSegmentation.from_pretrained("mattmdjaga/segformer_b2_clothes")

# Define label mapping
labels = {
    0: "Background", 
    1: "Hat", 
    2: "Hair", 
    3: "Sunglasses", 
    4: "Upper-clothes", 
    5: "Skirt", 
    6: "Pants", 
    7: "Dress", 
    8: "Belt", 
    9: "Left-shoe", 
    10: "Right-shoe", 
    11: "Face", 
    12: "Left-leg", 
    13: "Right-leg", 
    14: "Left-arm", 
    15: "Right-arm", 
    16: "Bag", 
    17: "Scarf"
}

@app.route('/', methods=['GET'])
def home():
    return "Welcome to the Segformer API! Use the /predict endpoint to make predictions."

@app.route('/predict', methods=['POST'])
def predict():
    logging.debug("Received request for prediction.")

    if 'file' not in request.files:
        logging.debug("Request data: %s", request.form)
        logging.warning("No file part in the request.")
        return jsonify({"error": "No file uploaded"}), 400

    file = request.files['file']
    if file.filename == '':
        logging.warning("No selected file.")
        return jsonify({"error": "No selected file"}), 400

    try:
        image = Image.open(file).convert('RGB')
    except Exception as e:
        logging.error("Could not process image: %s", str(e))
        return jsonify({"error": f"Could not process image: {str(e)}"}), 400

    # Preprocess image using the processor
    inputs = processor(images=image, return_tensors="pt")

    # Log input shape
    logging.debug("Input shape for model: %s", inputs['pixel_values'].shape)

    # Run model inference
    with torch.no_grad():
        outputs = model(**inputs)
        logging.debug("Model outputs: %s", outputs)  # Log the outputs

        # Access the logits and get the predicted segmentation
        predictions = outputs.logits.argmax(dim=1).squeeze().cpu().numpy()

    # Count occurrences of each label in the predictions
    unique, counts = np.unique(predictions, return_counts=True)
    label_counts = dict(zip(unique, counts))

    # Find the label with the highest count after the background (label 0)
    label_counts.pop(0, None)  # Remove background label
    if label_counts:
        most_detected_label = max(label_counts, key=label_counts.get)
        detected_label_name = labels[most_detected_label]
        logging.info("Most detected label (after background): %s", detected_label_name)
    else:
        detected_label_name = "None"
        logging.info("No label detected after background.")

    # Send the result to the Flutter app
    return jsonify({"detected_label": detected_label_name})

if __name__ == '__main__':
    app.run(debug=True)
