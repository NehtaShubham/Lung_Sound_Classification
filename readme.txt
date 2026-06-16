This repository contains MATLAB and Python implementations for lung sound analysis and classification using Variational Mode Decomposition (VMD), Continuous Wavelet Transform (CWT), and EfficientNet-B0.
Structure
├── dataset_preparation.m 
├── lung_preprocessing.m
├── classifier.py
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
