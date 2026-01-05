try:
    from deepface import DeepFace
    print("DeepFace imported.")
    
    # Check if we can load RetinaFace (might trigger download)
    # We won't actually run it on an image to save time, just check import/availability
    # DeepFace handles imports internally, so we might need to try a dummy call
    
    print("Checking RetinaFace availability...")
    try:
        # This will fail if retina-face package is missing and DeepFace can't install/find it
        # But DeepFace usually wraps this. 
        # Let's just try to import the backend wrapper if possible, or just run a dummy detection
        import retinaface
        print("retinaface module found.")
    except ImportError:
        print("retinaface module NOT found.")

except Exception as e:
    print(f"Error: {e}")
