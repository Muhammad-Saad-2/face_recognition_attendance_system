import pickle
import os
import shutil
import numpy as np
from typing import List, Dict
from fastapi import UploadFile
from deepface import DeepFace
from app.core.config import settings

class FaceRecognitionService:
    def __init__(self):
        self.encodings_file = settings.ENCODINGS_FILE
        self.images_dir = settings.IMAGES_DIR
        self._ensure_files()

    def _ensure_files(self):
        os.makedirs(self.images_dir, exist_ok=True)
        if not os.path.exists(self.encodings_file):
            with open(self.encodings_file, "wb") as f:
                pickle.dump({}, f)

    def load_encodings(self) -> Dict:
        try:
            with open(self.encodings_file, "rb") as f:
                return pickle.load(f)
        except (FileNotFoundError, EOFError):
            return {}

    def save_encodings(self, encodings: Dict):
        with open(self.encodings_file, "wb") as f:
            pickle.dump(encodings, f)

    def find_cosine_distance(self, source_representation, test_representation):
        a = np.matmul(np.transpose(source_representation), test_representation)
        b = np.sum(np.multiply(source_representation, source_representation))
        c = np.sum(np.multiply(test_representation, test_representation))
        return 1 - (a / (np.sqrt(b) * np.sqrt(c)))

    def process_student_images(self, student_id: str, images: List[UploadFile]) -> List:
        student_encodings = []
        student_images_dir = os.path.join(self.images_dir, student_id)
        os.makedirs(student_images_dir, exist_ok=True)

        for i, image in enumerate(images):
            file_path = os.path.join(student_images_dir, f"{i}_{image.filename}")
            with open(file_path, "wb") as buffer:
                shutil.copyfileobj(image.file, buffer)
            
            try:
                # Use VGG-Face and opencv backend as requested
                # enforce_detection=True ensures we only get valid faces
                representations = DeepFace.represent(
                    img_path=file_path,
                    model_name="VGG-Face",
                    detector_backend="opencv",
                    enforce_detection=True
                )
                
                for embedding_obj in representations:
                    student_encodings.append(embedding_obj["embedding"])
            except Exception as e:
                print(f"Error processing image {file_path}: {e}")
                continue
        
        return student_encodings

    def add_student_encodings(self, student_id: str, encodings: List):
        known_encodings = self.load_encodings()
        known_encodings[student_id] = encodings
        self.save_encodings(known_encodings)

    def recognize_faces(self, image_path: str) -> List[str]:
        try:
            target_representations = DeepFace.represent(
                img_path=image_path,
                model_name="VGG-Face",
                detector_backend="opencv",
                enforce_detection=True
            )
        except Exception:
            # No faces detected or other error
            return []
        
        if not target_representations:
            return []

        known_encodings_dict = self.load_encodings()
        recognized_ids = []
        
        # Threshold for VGG-Face Cosine Distance
        # 0.40 is the recommended threshold for VGG-Face
        threshold = 0.40

        for target_obj in target_representations:
            target_embedding = target_obj["embedding"]
            
            best_match_id = None
            min_distance = 1000 # Initialize with high value
            
            for student_id, student_encodings in known_encodings_dict.items():
                for known_embedding in student_encodings:
                    distance = self.find_cosine_distance(known_embedding, target_embedding)
                    
                    if distance < threshold and distance < min_distance:
                        min_distance = distance
                        best_match_id = student_id
            
            if best_match_id and best_match_id not in recognized_ids:
                recognized_ids.append(best_match_id)
                    
        return recognized_ids
