from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn
from PIL import Image
import io
import base64
from typing import Dict, Any
import json

app = FastAPI(title="Virtual Dressing Room API", version="1.0.0")

# Enable CORS for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your Flutter app's origin
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Test selfies metadata
TEST_SELFIES_METADATA = {
    "selfie_1": {
        "id": "selfie_1",
        "name": "Front Pose - Ideal",
        "difficulty": "Ideal",
        "pose_type": "front_facing",
        "lighting_quality": "good",
        "background_complexity": "simple",
        "body_type": "average",
        "description": "Perfect lighting, clear front pose"
    },
    "selfie_2": {
        "id": "selfie_2",
        "name": "Side Pose - Ideal",
        "difficulty": "Ideal",
        "pose_type": "side_facing",
        "lighting_quality": "good",
        "background_complexity": "simple",
        "body_type": "slim",
        "description": "Good side angle, natural lighting"
    },
    "selfie_3": {
        "id": "selfie_3",
        "name": "Slight Turn - Moderate",
        "difficulty": "Moderate",
        "pose_type": "three_quarter",
        "lighting_quality": "moderate",
        "background_complexity": "moderate",
        "body_type": "curvy",
        "description": "Slight body turn, moderate lighting"
    },
    "selfie_4": {
        "id": "selfie_4",
        "name": "Dynamic Pose - Challenging",
        "difficulty": "Challenging",
        "pose_type": "dynamic",
        "lighting_quality": "poor",
        "background_complexity": "complex",
        "body_type": "athletic",
        "description": "Complex pose, challenging lighting"
    },
    "selfie_5": {
        "id": "selfie_5",
        "name": "Mirror Selfie - Ideal",
        "difficulty": "Ideal",
        "pose_type": "mirror_selfie",
        "lighting_quality": "good",
        "background_complexity": "simple",
        "body_type": "petite",
        "description": "Clear mirror selfie, good visibility"
    },
    "selfie_6": {
        "id": "selfie_6",
        "name": "Outdoor - Moderate",
        "difficulty": "Moderate",
        "pose_type": "front_facing",
        "lighting_quality": "bright",
        "background_complexity": "complex",
        "body_type": "plus_size",
        "description": "Outdoor lighting, busy background"
    },
    "selfie_7": {
        "id": "selfie_7",
        "name": "Low Light - Challenging",
        "difficulty": "Challenging",
        "pose_type": "front_facing",
        "lighting_quality": "poor",
        "background_complexity": "simple",
        "body_type": "average",
        "description": "Low light conditions, grainy image"
    },
    "selfie_8": {
        "id": "selfie_8",
        "name": "Full Body - Ideal",
        "difficulty": "Ideal",
        "pose_type": "full_body",
        "lighting_quality": "excellent",
        "background_complexity": "simple",
        "body_type": "tall",
        "description": "Full body shot, excellent lighting"
    }
}

@app.get("/")
async def root():
    return {"message": "Virtual Dressing Room API is running!"}

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "Virtual Dressing Room API"}

@app.get("/test-selfies")
async def get_test_selfies():
    """Get metadata for all test selfies"""
    return {"selfies": list(TEST_SELFIES_METADATA.values())}

@app.get("/test-selfies/{selfie_id}")
async def get_selfie_metadata(selfie_id: str):
    """Get metadata for a specific test selfie"""
    if selfie_id not in TEST_SELFIES_METADATA:
        raise HTTPException(status_code=404, detail="Selfie not found")
    return TEST_SELFIES_METADATA[selfie_id]

@app.post("/upload-image")
async def upload_image(file: UploadFile = File(...)):
    """Upload and process an image"""
    try:
        # Validate file type
        if not file.content_type.startswith('image/'):
            raise HTTPException(status_code=400, detail="File must be an image")
        
        # Read and process image
        contents = await file.read()
        image = Image.open(io.BytesIO(contents))
        
        # Basic image analysis
        width, height = image.size
        format_type = image.format
        mode = image.mode
        
        # Convert to base64 for response (optional)
        buffered = io.BytesIO()
        image.save(buffered, format=format_type or 'JPEG')
        img_base64 = base64.b64encode(buffered.getvalue()).decode()
        
        return {
            "message": "Image uploaded successfully",
            "filename": file.filename,
            "size": {"width": width, "height": height},
            "format": format_type,
            "mode": mode,
            "file_size": len(contents),
            "processed": True
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing image: {str(e)}")

@app.post("/analyze-image")
async def analyze_image(file: UploadFile = File(...)):
    """Analyze uploaded image for pose, lighting, etc."""
    try:
        contents = await file.read()
        image = Image.open(io.BytesIO(contents))
        
        # Basic analysis (placeholder for future ML models)
        width, height = image.size
        aspect_ratio = width / height
        
        # Simple heuristics for demo purposes
        pose_type = "front_facing" if 0.7 <= aspect_ratio <= 1.3 else "full_body"
        lighting_quality = "good"  # Placeholder
        background_complexity = "simple"  # Placeholder
        
        analysis = {
            "pose_type": pose_type,
            "lighting_quality": lighting_quality,
            "background_complexity": background_complexity,
            "image_quality": "good",
            "suitable_for_processing": True,
            "recommendations": [
                "Image looks good for virtual try-on",
                "Clear pose detected"
            ]
        }
        
        return {
            "analysis": analysis,
            "image_info": {
                "width": width,
                "height": height,
                "aspect_ratio": round(aspect_ratio, 2)
            }
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error analyzing image: {str(e)}")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)