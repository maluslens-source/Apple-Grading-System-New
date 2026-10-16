import os
import shutil
import uuid
from fastapi import FastAPI, File, UploadFile, Query, HTTPException
from grader import AppleGrader

app = FastAPI(title="Apple Grading API")

# Initialize models once at startup to avoid re-loading on each request
DETECTOR_PATH = os.getenv("DETECTOR_PATH", "models/detector_best.pt")
CLASSIFIER_PATH = os.getenv("CLASSIFIER_PATH", "models/classifier_best.pt")

grader = AppleGrader(DETECTOR_PATH, CLASSIFIER_PATH)

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/grade")
async def grade_image(
    file: UploadFile = File(...),
    threshold: float = Query(0.50, ge=0.0, le=1.0, description="Grade A probability threshold")
):
    # Use a unique filename to avoid concurrency conflicts in /tmp
    extension = os.path.splitext(file.filename or "")[1] or ".jpg"
    temp_path = f"/tmp/{uuid.uuid4()}{extension}"

    try:
        with open(temp_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        # Run the grading pipeline via grader.py
        result = grader.grade(temp_path, a_threshold=threshold)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to process image: {str(e)}")
    finally:
        # Clean up temporary image file
        if os.path.exists(temp_path):
            os.remove(temp_path)

if __name__ == "__main__":
    import uvicorn
    # Cloud Run injects PORT (defaults to 8080)
    port = int(os.environ.get("PORT", 8080))
    uvicorn.run("main:app", host="0.0.0.0", port=port)
