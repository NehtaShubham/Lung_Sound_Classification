import os
import torch
import torch.nn as nn
import torch.optim as optim
from torchvision import datasets
from torch.utils.data import DataLoader
from torchvision.models import efficientnet_b0, EfficientNet_B0_Weights

from sklearn.metrics import (
    classification_report,
    confusion_matrix,
    ConfusionMatrixDisplay,
    roc_curve,
    auc
)

from sklearn.manifold import TSNE

import matplotlib.pyplot as plt
import numpy as np
from torchinfo import summary

# ==========================================================
# VMD-CWT LUNG SOUND CLASSIFICATION
# ==========================================================
#
# BEFORE RUNNING THIS SCRIPT:
#
# Run the MATLAB preprocessing pipeline:
#
# 1. Downsampling (4 kHz)
# 2. Segmentation
# 3. VMD decomposition
# 4. CWT scalogram generation
#
# Organize generated scalogram as:
# 
# Dataset/
# ├── train/
# │   ├── Chronic/
# │   └── Nonchronic/
# │
# └── test/
#     ├── Chronic/
#     └── Nonchronic/
#
# Change only DATASET_ROOT if necessary.
# ==========================================================

DATASET_ROOT = "Dataset"

train_dir = os.path.join(DATASET_ROOT, "train")
test_dir = os.path.join(DATASET_ROOT, "test")

batch_size = 16
num_epochs = 70
learning_rate = 1e-4

model_save_path = "efficientnet_b0_cwt.pth"

device = torch.device(
    "cuda" if torch.cuda.is_available() else "cpu"
)

# ==========================================================
# DATASET CHECKS
# ==========================================================

if not os.path.isdir(train_dir):
    raise FileNotFoundError(
        f"Training folder not found:\n{train_dir}"
    )

if not os.path.isdir(test_dir):
    raise FileNotFoundError(
        f"Testing folder not found:\n{test_dir}"
    )

print("=" * 60)
print("VMD-CWT Lung Sound Classification")
print("=" * 60)
print(f"Training Folder : {train_dir}")
print(f"Testing Folder  : {test_dir}")
print(f"Device          : {device}")
print("=" * 60)

# ==========================================================
# TRANSFORMS
# ==========================================================

weights = EfficientNet_B0_Weights.DEFAULT
transform = weights.transforms()

# ==========================================================
# LOAD DATASETS
# ==========================================================

train_dataset = datasets.ImageFolder(
    train_dir,
    transform=transform
)

test_dataset = datasets.ImageFolder(
    test_dir,
    transform=transform
)

class_names = train_dataset.classes
num_classes = len(class_names)

print("\nClasses Detected:")
for cls in class_names:
    print(f" - {cls}")

print(f"\nNumber of Classes : {num_classes}")
print(f"Training Images   : {len(train_dataset)}")
print(f"Testing Images    : {len(test_dataset)}")

# ==========================================================
# DATALOADERS
# ==========================================================

train_loader = DataLoader(
    train_dataset,
    batch_size=batch_size,
    shuffle=True
)

test_loader = DataLoader(
    test_dataset,
    batch_size=batch_size,
    shuffle=False
)

# ==========================================================
# MODEL
# ==========================================================

model = efficientnet_b0(weights=weights)

model.classifier[1] = nn.Linear(
    model.classifier[1].in_features,
    num_classes
)

model = model.to(device)

# ==========================================================
# LOSS & OPTIMIZER
# ==========================================================

criterion = nn.CrossEntropyLoss()

optimizer = optim.Adam(
    model.parameters(),
    lr=learning_rate
)

# ==========================================================
# TRAINING
# ==========================================================

print("\nTraining Started...\n")

for epoch in range(num_epochs):

    model.train()

    running_loss = 0.0

    for inputs, labels in train_loader:

        inputs = inputs.to(device)
        labels = labels.to(device)

        optimizer.zero_grad()

        outputs = model(inputs)

        loss = criterion(outputs, labels)

        loss.backward()

        optimizer.step()

        running_loss += loss.item()

    avg_loss = running_loss / len(train_loader)

    print(
        f"Epoch [{epoch+1}/{num_epochs}] "
        f"Loss: {avg_loss:.4f}"
    )

# ==========================================================
# SAVE MODEL
# ==========================================================

torch.save(
    model.state_dict(),
    model_save_path
)

print(f"\nModel saved as: {model_save_path}")

# ==========================================================
# EVALUATION
# ==========================================================

model.eval()

all_preds = []
all_labels = []
all_probs = []

with torch.no_grad():

    for inputs, labels in test_loader:

        inputs = inputs.to(device)

        outputs = model(inputs)

        probs = torch.softmax(outputs, dim=1)

        preds = torch.argmax(probs, dim=1)

        all_preds.extend(
            preds.cpu().numpy()
        )

        all_labels.extend(
            labels.numpy()
        )

        all_probs.extend(
            probs.cpu().numpy()
        )

# ==========================================================
# CONFUSION MATRIX
# ==========================================================

cm = confusion_matrix(
    all_labels,
    all_preds
)

disp = ConfusionMatrixDisplay(
    confusion_matrix=cm,
    display_labels=class_names
)

disp.plot(cmap=plt.cm.Blues)

plt.title("Confusion Matrix")

plt.savefig(
    "confusion_matrix.png",
    dpi=300,
    bbox_inches="tight"
)

plt.show()

# ==========================================================
# CLASSIFICATION REPORT
# ==========================================================

report = classification_report(
    all_labels,
    all_preds,
    target_names=class_names
)

print("\nClassification Report:\n")
print(report)

with open(
    "classification_report.txt",
    "w"
) as f:
    f.write(report)

# ==========================================================
# ROC CURVES
# ==========================================================

if num_classes == 2:

    fpr1, tpr1, _ = roc_curve(
        all_labels,
        [p[1] for p in all_probs]
    )

    roc_auc1 = auc(
        fpr1,
        tpr1
    )

    inv_labels = [1 - l for l in all_labels]
    inv_probs = [p[0] for p in all_probs]

    fpr0, tpr0, _ = roc_curve(
        inv_labels,
        inv_probs
    )

    roc_auc0 = auc(
        fpr0,
        tpr0
    )

    plt.figure()

    plt.plot(
        fpr1,
        tpr1,
        color="darkorange",
        label=f"{class_names[1]} (AUC = {roc_auc1:.2f})"
    )

    plt.plot(
        fpr0,
        tpr0,
        color="green",
        label=f"{class_names[0]} (AUC = {roc_auc0:.2f})"
    )

    plt.plot(
        [0, 1],
        [0, 1],
        color="navy",
        linestyle="--"
    )

    plt.xlabel("False Positive Rate")
    plt.ylabel("True Positive Rate")
    plt.title("ROC Curve")

    plt.legend(loc="lower right")

    plt.grid(False)

    plt.savefig(
        "roc_curve.png",
        dpi=300,
        bbox_inches="tight"
    )

    plt.show()

# ==========================================================
# t-SNE VISUALIZATION
# ==========================================================

features = []
labels_tsne = []

with torch.no_grad():

    for inputs, labels in test_loader:

        inputs = inputs.to(device)

        outputs = model.features(inputs)

        outputs = torch.flatten(
            outputs,
            start_dim=1
        )

        features.extend(
            outputs.cpu().numpy()
        )

        labels_tsne.extend(
            labels.numpy()
        )

features = np.array(features)
labels_tsne = np.array(labels_tsne)

tsne = TSNE(
    n_components=2,
    random_state=42
)

features_2d = tsne.fit_transform(
    features
)

plt.figure(figsize=(6, 6))

for idx, class_name in enumerate(class_names):

    plt.scatter(
        features_2d[
            labels_tsne == idx, 0
        ],
        features_2d[
            labels_tsne == idx, 1
        ],
        label=class_name,
        alpha=0.7,
        s=6
    )

plt.legend()

plt.title(
    "t-SNE Plot of Feature Representations"
)

plt.savefig(
    "tsne_plot.png",
    dpi=300,
    bbox_inches="tight"
)

plt.show()

# ==========================================================
# MODEL SUMMARY
# ==========================================================

print("\nModel Summary\n")

summary(
    model,
    input_size=(1, 3, 224, 224),
    device=device
)
