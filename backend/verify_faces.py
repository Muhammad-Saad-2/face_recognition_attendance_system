import os
from deepface import DeepFace

# Path to the generated image
image_path = "/home/muhammed-saad/.gemini/antigravity/brain/a3c6ea11-0a6a-4840-847d-ea8fb97fee20/group_photo_test_1767443163918.png"

def verify_face_detection():
    if not os.path.exists(image_path):
        print(f"Error: Image not found at {image_path}")
        return

    print(f"Testing face detection on: {image_path}")
    
    try:
        # Using the same parameters as in the service
        # model_name="VGG-Face", detector_backend="opencv"
        representations = DeepFace.represent(
            img_path=image_path,
            model_name="VGG-Face",
            detector_backend="opencv",
            enforce_detection=True
        )
        
        count = len(representations)
        print(f"Faces detected: {count}")
        
        if count >= 5:
            print("SUCCESS: Detected 5 or more faces.")
        else:
            print(f"WARNING: Only detected {count} faces. Expected at least 5.")
            
    except Exception as e:
        print(f"Error during detection: {e}")

if __name__ == "__main__":
    verify_face_detection()
