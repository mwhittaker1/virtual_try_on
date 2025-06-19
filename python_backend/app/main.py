from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn
from PIL import Image
import io
import base64
from typing import Dict, Any
import json
from transformers import AutoImageProcessor, AutoModelForSemanticSegmentation
import torch
import numpy as np
from PIL import Image as PILImage

app = FastAPI(title="Virtual Dressing Room API", version="1.0.0")

# Load the fashion segmentation model
processor = AutoImageProcessor.from_pretrained("mattmdjaga/segformer_b2_clothes")
model = AutoModelForSemanticSegmentation.from_pretrained("mattmdjaga/segformer_b2_clothes")


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

def segment_clothing(image: PILImage.Image):
    """Segment clothing items in the image"""
    try:
        # Prepare image for model
        inputs = processor(images=image, return_tensors="pt")
        
        # Run inference
        with torch.no_grad():
            outputs = model(**inputs)
            
        # Get segmentation logits
        logits = outputs.logits
        
        # Resize to original image size
        upsampled_logits = torch.nn.functional.interpolate(
            logits,
            size=image.size[::-1],  # PIL uses (width, height), torch uses (height, width)
            mode="bilinear",
            align_corners=False,
        )
        
        # Get predicted segmentation map
        predicted = upsampled_logits.argmax(dim=1)
        segmentation_map = predicted[0].cpu().numpy()
        
        # Define clothing categories (based on model's classes)
        categories = {
            0: "background",
            1: "hat",
            2: "hair", 
            3: "sunglasses",
            4: "upper-clothes",
            5: "skirt",
            6: "pants",
            7: "dress",
            8: "belt",
            9: "left-shoe",
            10: "right-shoe",
            11: "face",
            12: "left-leg",
            13: "right-leg",
            14: "left-arm",
            15: "right-arm",
            16: "bag",
            17: "scarf"
        }
        
        # Analyze detected clothing items
        detected_items = []
        unique_labels = np.unique(segmentation_map)
        
        for label in unique_labels:
            if label > 0:  # Skip background
                mask_area = np.sum(segmentation_map == label)
                total_pixels = segmentation_map.shape[0] * segmentation_map.shape[1]
                coverage = mask_area / total_pixels
                
                detected_items.append({
                    "category": categories.get(label, f"unknown_{label}"),
                    "label": int(label),
                    "coverage": float(coverage),
                    "pixel_count": int(mask_area)
                })
        
        return {
            "detected_items": detected_items,
            "segmentation_shape": segmentation_map.shape,
            "total_categories": len(unique_labels) - 1  # Exclude background
        }
        
    except Exception as e:
        raise Exception(f"Segmentation failed: {str(e)}")

@app.post("/segment-clothing")
async def segment_clothing_endpoint(file: UploadFile = File(...)):
    """Segment clothing items in uploaded image"""
    try:
        # Validate file type
        if not file.content_type.startswith('image/'):
            raise HTTPException(status_code=400, detail="File must be an image")
        
        # Read and process image
        contents = await file.read()
        image = PILImage.open(io.BytesIO(contents))
        
        # Convert to RGB if needed
        if image.mode != 'RGB':
            image = image.convert('RGB')
        
        # Run segmentation
        segmentation_result = segment_clothing(image)
        
        # Add image info
        width, height = image.size
        
        return {
            "message": "Clothing segmentation completed",
            "image_info": {
                "width": width,
                "height": height,
                "mode": image.mode
            },
            "segmentation": segmentation_result
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error segmenting clothing: {str(e)}")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)