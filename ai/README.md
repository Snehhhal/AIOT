# AI & Machine Learning Subsystem

## Overview
This subsystem develops, trains, and evaluates:
1. **Tabular Leakage Classifier:** Multi-sensor risk classification model (Random Forest / XGBoost).
2. **Computer Vision (YOLOv8):** Detects water puddles around pole bases, human proximity, and loose sagging cables.

## Directory Layout
* `models/`: Trained model binaries (`.joblib` for ML, `.pt` for YOLO).
* `notebooks/`: Exploratory data analysis (EDA), synthetic dataset generation, model cross-validation.
* `src/`: Reusable inference and feature engineering scripts:
  - `feature_pipeline.py`: Scaling and validation of input sensors.
  - `train_classifier.py`: Training pipeline with cross-validation.
  - `vision_detector.py`: YOLO inference and proximity distance calculations.

## Dependencies
Install dedicated AI dependencies via `ai/requirements.txt`.
