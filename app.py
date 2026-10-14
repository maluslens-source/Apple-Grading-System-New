import os
import tempfile
from pathlib import Path

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.responses import JSONResponse

from grader import AppleGrader

app = FastAPI()

# Cloud Run CPU-only deployment: force CPU for deterministic runtime behavior.
grader = AppleGrader(
    "models/detector_best.pt",
    "models/classifier_best.pt",
    device="cpu",
)


@app.get("/healthz")
async def healthz():
    return {"status": "ok"}


@app.post("/grade")
async def grade_image(
    file: UploadFile = File(...),
    threshold: float = Form(0.50),
):
    if not file.filename:
        raise HTTPException(status_code=400, detail="No file uploaded")

    suffix = Path(file.filename).suffix.lower() or ".jpg"
    with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
        contents = await file.read()
        tmp.write(contents)
        tmp_path = tmp.name

    try:
        result = grader.grade(tmp_path, a_threshold=threshold)
        return JSONResponse(content=result)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc
    finally:
        try:
            os.unlink(tmp_path)
        except OSError:
            pass


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("app:app", host="0.0.0.0", port=int(os.environ.get("PORT", "8080")))
