# Automated Test Suite

## Overview
Comprehensive tests ensuring data validation, risk calculation accuracy, and API endpoint correctness.

## Test Categories
* `tests/backend/`:
  - `test_health.py`: Validates service availability and runtime mode reporting.
  - `test_telemetry.py`: Tests the Decision Engine against safe, advisory, high-risk, and critical leakage scenarios.
* `tests/ai/`:
  - Validates tabular ML classification metrics and YOLO object detection inference.

## Running Tests
```powershell
pytest tests/
```
