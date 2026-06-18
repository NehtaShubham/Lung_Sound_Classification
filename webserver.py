from flask import Flask, request, render_template, send_from_directory
import torch
from PIL import Image
import os
import numpy as np
import matplotlib.pyplot as plt
from ssqueezepy import cwt
import scipy.io.wavfile as wavfile
from torchvision import transforms

app = Flask(__name__)
UPLOAD_FOLDER = 'static'
SCALOGRAM_PATH = os.path.join(UPLOAD_FOLDER, 'scalogram.png')
model = torch.jit.load("Put_Trained_model_here", map_location='cpu')
model.eval()

class_names = ['chronic', 'nonchronic']
transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406],
                         std=[0.229, 0.224, 0.225])
])

def wav_to_cwt_image(wav_path, output_path=SCALOGRAM_PATH):
    fs, data = wavfile.read(wav_path)

    # Convert stereo to mono
    if len(data.shape) > 1:
        data = data.mean(axis=1)

    # Trim and normalize
    data = data[:8000].astype(np.float32)
    data /= np.max(np.abs(data))


    # Perform CWT
    Wx, _ = cwt(data, wavelet='morlet', scales='log', nv=12)
    Wx_abs = np.abs(Wx)

    # Normalize to 0–1
    Wx_norm = (Wx_abs - Wx_abs.min()) / (Wx_abs.max() - Wx_abs.min())

    # Gamma correction
    Wx_gamma = np.power(Wx_norm, 1.0)  # gamma = 1 (can adjust for contrast)

    # Scale to 0–255
    Wx_rescaled = Wx_gamma * 255
    Wx_uint8 = np.uint8(np.round(Wx_rescaled))

    # Apply jet colormap (128 steps)
    cmap = plt.get_cmap('jet', 128)
    Wx_rgb = cmap(Wx_uint8)[:, :, :3]  # drop alpha
    Wx_rgb = (Wx_rgb * 255).astype(np.uint8)

    # Save 224x224 image
    img = Image.fromarray(Wx_rgb)
    img_resized = img.resize((224, 224), Image.BICUBIC)
    img_resized.save(output_path)



def classify_wav(wav_path):
    wav_to_cwt_image(wav_path)
    img = Image.open(SCALOGRAM_PATH).convert('RGB')
    input_tensor = transform(img).unsqueeze(0)
    with torch.no_grad():
        output = model(input_tensor)
        probs = torch.softmax(output, dim=1)
        pred = torch.argmax(probs, dim=1).item()
        conf = probs[0][pred].item()
    return class_names[pred], conf

@app.route('/', methods=['GET', 'POST'])
def index():
    prediction = None
    confidence = None
    if request.method == 'POST':
        file = request.files['file']
        if file and file.filename.endswith('.wav'):
            file_path = os.path.join(UPLOAD_FOLDER, 'input.wav')
            file.save(file_path)
            prediction, confidence = classify_wav(file_path)
    return render_template('index.html', prediction=prediction, confidence=confidence)

if __name__ == '__main__':
    os.makedirs(UPLOAD_FOLDER, exist_ok=True)
    app.run(host='0.0.0.0', port=5000)
