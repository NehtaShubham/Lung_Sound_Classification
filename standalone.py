import torch
import numpy as np
import matplotlib.pyplot as plt
from PIL import Image, ImageTk
from torchvision import transforms
import os
import tkinter as tk
from tkinter import filedialog, messagebox
from ssqueezepy import cwt
import scipy.io.wavfile as wavfile
import time

# Load model
model = torch.jit.load("put_your_Saved_model_here", map_location='cpu')
model.eval()

# Class labels
class_names = ['chronic', 'nonchronic']

# Image transform
transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406],
                         std=[0.229, 0.224, 0.225])
])

# CWT image generation using ssqueezepy
def wav_to_cwt_image(wav_path, output_path='temp_scalogram.png'):
    fs, data = wavfile.read(wav_path)
    
    # Convert to mono if stereo
    if len(data.shape) > 1:
        data = data.mean(axis=1)

    data = data[:8000].astype(np.float32)
    data /= np.max(np.abs(data))  # Normalize

    Wx, _ = cwt(data, wavelet='morlet', scales='log', nv=12)
    Wx_abs = np.abs(Wx)

    # Normalize to 0–1
    Wx_norm = (Wx_abs - Wx_abs.min()) / (Wx_abs.max() - Wx_abs.min())

    # Apply gamma correction (gamma=1 here, tweakable)
    Wx_gamma = np.power(Wx_norm, 1)

    # Scale to 0–255 and convert to uint8
    Wx_rescaled = Wx_gamma * 255
    Wx_uint8 = np.uint8(np.round(Wx_rescaled))

    # Apply jet colormap
    cmap = plt.get_cmap('jet', 128)
    Wx_rgb = cmap(Wx_uint8)[:, :, :3]
    Wx_rgb = (Wx_rgb * 255).astype(np.uint8)

    # Save image using PIL
    Image.fromarray(Wx_rgb).save(output_path)

    return output_path

# Classification with timing
def classify_wav(wav_path):
    start_time = time.time()

    image_path = wav_to_cwt_image(wav_path)
    img = Image.open(image_path).convert('RGB')
    input_tensor = transform(img).unsqueeze(0)

    with torch.no_grad():
        output = model(input_tensor)
        probs = torch.softmax(output, dim=1)
        pred = torch.argmax(probs, dim=1).item()
        conf = probs[0][pred].item()

    os.remove(image_path)

    elapsed_time = time.time() - start_time
    return class_names[pred], conf, image_path, elapsed_time

# GUI
def browse_file():
    file_path = filedialog.askopenfilename(filetypes=[("WAV files", "*.wav")])
    if file_path:
        label_result.config(text="Classifying...")
        root.update()
        try:
            label, confidence, img_path, elapsed_time = classify_wav(file_path)
            label_result.config(
                text=f"Prediction: {label} ({confidence*100:.2f}%)\nProcessing Time: {elapsed_time:.2f} sec"
            )

            # Show image
            img = Image.open(wav_to_cwt_image(file_path))
            img = img.resize((200, 200))
            img_tk = ImageTk.PhotoImage(img)
            image_label.config(image=img_tk)
            image_label.image = img_tk
        except Exception as e:
            messagebox.showerror("Error", str(e))

# Create window
root = tk.Tk()
root.title("Lung Sound Classifier")
root.geometry("300x400")

btn_browse = tk.Button(root, text="Select WAV File", command=browse_file)
btn_browse.pack(pady=10)

label_result = tk.Label(root, text="Prediction will appear here", wraplength=250)
label_result.pack(pady=10)

image_label = tk.Label(root)
image_label.pack(pady=10)

root.mainloop()
