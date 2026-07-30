#!/usr/bin/env bash
set -Eeuo pipefail

/opt/venv/bin/python - <<'PY'
import cv2
import insightface
import numpy
import onnx
import onnxruntime as ort
import opennsfw2
import PIL
import psutil
import tensorflow as tf
from PySide6.QtCore import qVersion

assert numpy.__version__ == "1.26.4"
assert "CUDAExecutionProvider" in ort.get_available_providers()

print("NumPy:", numpy.__version__)
print("OpenCV:", cv2.__version__)
print("ONNX:", onnx.__version__)
print("ONNX Runtime:", ort.__version__)
print("Proveedores ORT:", ort.get_available_providers())
print("TensorFlow:", tf.__version__)
print("GPU TensorFlow:", tf.config.list_physical_devices("GPU"))
print("InsightFace:", insightface.__version__)
print("Pillow:", PIL.__version__)
print("Qt:", qVersion())
print("[OK] Entorno Python IA operativo.")
PY
