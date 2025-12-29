import os
import numpy as np
from deepface import DeepFace

def verify():
    print("Verifying DeepFace installation and model loading...")
    
    # Create a dummy image
    dummy_image = np.random.randint(0, 255, (224, 224, 3), dtype=np.uint8)
    import cv2
    cv2.imwrite("dummy.jpg", dummy_image)
    
    try:
        # Attempt to generate an embedding
        # We expect this to fail on face detection with a random noise image if enforce_detection=True
        # But we just want to see if it loads the model.
        print("Loading VGG-Face model...")
        # This will download the model if not present (might take time)
        # In Docker it's pre-downloaded.
        DeepFace.build_model("VGG-Face")
        print("Model loaded successfully.")
        
    except Exception as e:
        print(f"Verification failed: {e}")
    finally:
        if os.path.exists("dummy.jpg"):
            os.remove("dummy.jpg")

if __name__ == "__main__":
    verify()
