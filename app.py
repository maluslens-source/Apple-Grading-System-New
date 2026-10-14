import os
import tempfile
from pathlib import Path

from flask import Flask, jsonify, request

app = Flask(__name__)

MODEL_DIR = Path(__file__).resolve().parent / "models"
REQUIRED_MODELS = ("detector_best.pt", "classifier_best.pt")


def model_files_exist() -> bool:
    return MODEL_DIR.exists() and all((MODEL_DIR / name).exists() for name in REQUIRED_MODELS)


@app.get("/")
def root():
    return jsonify({
        "status": "ok",
        "service": "apple-grading-system",
        "message": "Cloud Run service is running. Use /health or POST /grade to evaluate an image.",
    })


@app.get("/health")
def health():
    return jsonify({"status": "ok"})


@app.post("/grade")
def grade_image():
    if not model_files_exist():
        return jsonify({
            "error": "Model files not found.",
            "expected": [str(MODEL_DIR / name) for name in REQUIRED_MODELS],
        }), 503

    uploaded_file = request.files.get("image")
    if uploaded_file is None:
        return jsonify({"error": "No image uploaded. Send a multipart form with field 'image'."}), 400

    if uploaded_file.filename == "":
        return jsonify({"error": "Uploaded file has no filename."}), 400

    suffix = Path(uploaded_file.filename).suffix or ".jpg"
    with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
        uploaded_file.save(tmp.name)
        temp_path = tmp.name

    try:
        from grader import AppleGrader

        grader = AppleGrader(
            str(MODEL_DIR / "detector_best.pt"),
            str(MODEL_DIR / "classifier_best.pt"),
            device="cpu",
        )
        threshold = float(request.form.get("threshold", 0.50))
        result = grader.grade(temp_path, a_threshold=threshold)
        return jsonify(result)
    except Exception as exc:  # pragma: no cover - defensive runtime guard
        return jsonify({"error": str(exc)}), 500
    finally:
        try:
            os.unlink(temp_path)
        except OSError:
            pass


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    app.run(host="0.0.0.0", port=port, debug=False)
