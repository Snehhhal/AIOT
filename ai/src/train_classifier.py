"""
Machine Learning Training Pipeline for Electric Pole Hazard Classification
==========================================================================
Conforms to strict ML best practices:
- Strict featurization ordering (train/test split BEFORE fitting preprocessors).
- Multi-model evaluation (Baseline Logistic Regression vs. Random Forest).
- Stratified 5-Fold Cross Validation.
- Comprehensive evaluation metrics (Precision, Recall, F1-Score, Confusion Matrix).
- Complete pipeline serialization to .joblib with reproducible metadata.
"""

import json
import os
import time
from typing import Any, Dict, Tuple

import joblib
import numpy as np
import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score
from sklearn.model_selection import StratifiedKFold, cross_val_score, train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler

# Path setup
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_PATH = os.path.join(BASE_DIR, "data", "pole_safety_dataset.csv")
MODELS_DIR = os.path.join(BASE_DIR, "models")
MODEL_PATH = os.path.join(MODELS_DIR, "leakage_classifier.joblib")
METADATA_PATH = os.path.join(MODELS_DIR, "model_metadata.json")

# Feature definitions
NUMERICAL_FEATURES = [
    "leakage_current_ma",
    "touch_voltage_v",
    "tilt_angle_deg",
    "vibration_g",
    "temperature_c",
    "humidity_pct",
]
BINARY_FEATURES = ["rain_detected"]
ALL_FEATURES = NUMERICAL_FEATURES + BINARY_FEATURES
TARGET_COLUMN = "risk_class"
CLASS_ORDER = ["NORMAL", "ADVISORY", "HIGH_RISK", "CRITICAL"]


def load_and_validate_data(csv_path: str = DATA_PATH) -> Tuple[pd.DataFrame, pd.Series]:
    """Loads dataset and performs data hygiene verification."""
    if not os.path.exists(csv_path):
        from ai.src.generate_dataset import generate_synthetic_data, save_dataset
        print(f"[*] Dataset not found at {csv_path}. Generating on-the-fly...")
        df = generate_synthetic_data(num_samples=4000)
        save_dataset(df, csv_path)
    else:
        df = pd.read_csv(csv_path)

    # Check missing values
    null_counts = df[ALL_FEATURES + [TARGET_COLUMN]].isnull().sum()
    if null_counts.any():
        print(f"[!] Warning: Missing values found. Dropping {null_counts.sum()} rows.")
        df = df.dropna(subset=ALL_FEATURES + [TARGET_COLUMN])

    X = df[ALL_FEATURES]
    y = df[TARGET_COLUMN]

    print(f"[*] Loaded dataset with {len(df)} samples across {len(ALL_FEATURES)} features.")
    print(f"[*] Class counts:\n{y.value_counts()}")
    return X, y


def build_preprocessor() -> ColumnTransformer:
    """Builds the scikit-learn preprocessing ColumnTransformer."""
    preprocessor = ColumnTransformer(
        transformers=[
            ("num", StandardScaler(), NUMERICAL_FEATURES),
            ("bin", "passthrough", BINARY_FEATURES),
        ],
        remainder="drop",
    )
    return preprocessor


def train_and_evaluate(
    X: pd.DataFrame,
    y: pd.Series,
    random_seed: int = 42
) -> Tuple[Pipeline, Dict[str, Any]]:
    """
    Executes training workflow adhering to ML best practices.
    """
    # 1. Strict Featurization Ordering: Split train/test BEFORE any pipeline fitting
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.20, random_state=random_seed, stratify=y
    )
    print(f"\n[*] Data partitioned: Train={len(X_train)} samples, Test={len(X_test)} samples.")

    preprocessor = build_preprocessor()

    # 2. Baseline Model: Logistic Regression
    baseline_pipe = Pipeline([
        ("preprocessor", preprocessor),
        ("classifier", LogisticRegression(max_iter=1000, random_state=random_seed))
    ])

    # 3. Production Model: Random Forest Classifier
    rf_pipe = Pipeline([
        ("preprocessor", preprocessor),
        ("classifier", RandomForestClassifier(
            n_estimators=100,
            max_depth=12,
            min_samples_split=4,
            min_samples_leaf=2,
            random_state=random_seed,
            n_jobs=-1
        ))
    ])

    # 4. Stratified 5-Fold Cross-Validation on Training Data
    cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=random_seed)
    baseline_cv_scores = cross_val_score(baseline_pipe, X_train, y_train, cv=cv, scoring="accuracy")
    rf_cv_scores = cross_val_score(rf_pipe, X_train, y_train, cv=cv, scoring="accuracy")

    print("\n" + "=" * 60)
    print(" 5-Fold Stratified Cross-Validation Results (Training Set)")
    print("=" * 60)
    print(f" Baseline Logistic Regression: Mean Accuracy = {baseline_cv_scores.mean():.4f} (+/- {baseline_cv_scores.std():.4f})")
    print(f" Production Random Forest   : Mean Accuracy = {rf_cv_scores.mean():.4f} (+/- {rf_cv_scores.std():.4f})")
    print("=" * 60)

    # 5. Fit Production Model on Entire Training Set
    start_time = time.time()
    rf_pipe.fit(X_train, y_train)
    fit_duration = time.time() - start_time
    print(f"[*] Random Forest trained in {fit_duration:.3f}s")

    # 6. Evaluation on Held-Out Test Set
    y_pred = rf_pipe.predict(X_test)
    test_acc = accuracy_score(y_test, y_pred)
    report = classification_report(y_test, y_pred, labels=CLASS_ORDER, output_dict=True)
    conf_matrix = confusion_matrix(y_test, y_pred, labels=CLASS_ORDER).tolist()

    print("\n" + "=" * 60)
    print(f" Final Evaluation on Held-Out Test Set (Accuracy = {test_acc * 100:.2f}%)")
    print("=" * 60)
    print(classification_report(y_test, y_pred, labels=CLASS_ORDER, digits=4))

    print("Confusion Matrix (Order: NORMAL, ADVISORY, HIGH_RISK, CRITICAL):")
    for row in conf_matrix:
        print(f"  {row}")

    # Feature Importance Extraction
    rf_model = rf_pipe.named_steps["classifier"]
    feature_importances = dict(zip(ALL_FEATURES, [round(float(v), 4) for v in rf_model.feature_importances_]))
    print("\nFeature Importances:")
    for feat, imp in sorted(feature_importances.items(), key=lambda x: x[1], reverse=True):
        print(f"  - {feat:20s}: {imp:.4f}")

    metadata = {
        "model_type": "RandomForestClassifier",
        "n_estimators": 100,
        "max_depth": 12,
        "features": ALL_FEATURES,
        "classes": CLASS_ORDER,
        "training_samples": len(X_train),
        "test_samples": len(X_test),
        "test_accuracy": round(float(test_acc), 4),
        "cv_mean_accuracy": round(float(rf_cv_scores.mean()), 4),
        "cv_std_accuracy": round(float(rf_cv_scores.std()), 4),
        "feature_importances": feature_importances,
        "confusion_matrix": conf_matrix,
        "classification_report": report,
        "trained_at": time.strftime("%Y-%m-%d %H:%M:%SZ", time.gmtime()),
    }

    return rf_pipe, metadata


def save_model(pipeline: Pipeline, metadata: Dict[str, Any]) -> Tuple[str, str]:
    """Persists model binary and JSON metadata to disk."""
    os.makedirs(MODELS_DIR, exist_ok=True)
    joblib.dump(pipeline, MODEL_PATH)
    with open(METADATA_PATH, "w", encoding="utf-8") as f:
        json.dump(metadata, f, indent=2)

    print(f"\n[+] Saved model artifact  : {MODEL_PATH}")
    print(f"[+] Saved model metadata  : {METADATA_PATH}")
    return MODEL_PATH, METADATA_PATH


def main():
    X, y = load_and_validate_data()
    pipeline, metadata = train_and_evaluate(X, y)
    save_model(pipeline, metadata)


if __name__ == "__main__":
    main()
