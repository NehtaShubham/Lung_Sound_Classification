This repository contains MATLAB and Python implementations for lung sound analysis and classification using Variational Mode Decomposition (VMD), Continuous Wavelet Transform (CWT), and EfficientNet-B0.
Structure
├── dataset_preparation.m 
├── lung_preprocessing.m
├── classifier.py
deployment/ │ 
            ├── webserver.py │ 
            ├── Efficientnet_standalone.py │ 
            ├── requirements.txt │ 
            └── templates/ │ 
                           └── index.html
└── README.md
Script Descriptions
1. dataset_preparation.m
This MATLAB script provides utilities for organizing the ICBHI respiratory sound database.
Features:
Reads patient diagnosis information from patient_diagnosis.csv
Groups audio recordings according to disease conditions
Creates condition-wise folders automatically
Generates condition-wise file count summaries
Creates COPD and Non-COPD datasets
2. lung_preprocessing.m
This MATLAB script performs preprocessing and time-frequency representation generation.
Processing steps:
Downsampling to 4 kHz
Signal segmentation
Variational Mode Decomposition (VMD)
Continuous Wavelet Transform (CWT)
Scalogram image generation
3. classifier.py
This Python script performs classification of lung sound scalograms.
Features:
EfficientNet-B0 transfer learning
Automatic dataset loading
Training and testing
Confusion matrix generation
Classification report generation
ROC curve visualization
t-SNE feature visualization
Model summary generation
Trained model saving
**Requirements**
MATLAB
Required toolboxes:
Signal Processing Toolbox
Wavelet Toolbox
Variational Mode Decomposition (VMD) support
Python
Recommended:
Python 3.9+
CUDA-enabled GPU (optional)
Install dependencies:
pip install torch torchvision
pip install numpy
pip install matplotlib
pip install scikit-learn
pip install torchinfo
*****************************
#Raspberry Pi 5 Deployment
*****************************
The trained TorchScript model was deployed on a Raspberry Pi 5 using both a standalone desktop application and a Flask-based web interface.
*Deployment Features
**Edge AI inference on Raspberry Pi 5
**Flask-based web application
**Standalone Tkinter GUI
**Real-time respiratory sound classification
**Chronic / Non-Chronic prediction
**webserver.py**
The deep learning model was trained using scalogram images generated through a Variational Mode Decomposition (VMD) and Continuous Wavelet Transform (CWT) framework. After training, the learned model parameters were exported as a TorchScript (.pt) file and deployed on a Raspberry Pi 5 using a Flask-based web application. During deployment, the trained model performs real-time inference on uploaded respiratory sound recordings and provides Chronic or Non-Chronic predictions through a browser-based interface, enabling edge-AI respiratory disease screening without cloud connectivity.
