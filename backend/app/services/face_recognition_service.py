import os
import shutil
import numpy as np
from typing import List, Dict
from fastapi import UploadFile
from deepface import DeepFace
from sqlmodel import Session, select
from app.core.config import settings
from app.models.student import Student

class FaceRecognitionService:
    def __init__(self):
        self.images_dir = settings.IMAGES_DIR
        os.makedirs(self.images_dir, exist_ok=True)

    def find_cosine_distance(self, source_representation, test_representation):
        a = np.matmul(np.transpose(source_representation), test_representation)
        b = np.sum(np.multiply(source_representation, source_representation))
        c = np.sum(np.multiply(test_representation, test_representation))
        return 1 - (a / (np.sqrt(b) * np.sqrt(c)))

    def process_student_images(self, student_id: str, images: List[UploadFile]) -> List[List[float]]:
        student_encodings = []
        student_images_dir = os.path.join(self.images_dir, student_id)
        os.makedirs(student_images_dir, exist_ok=True)

        for i, image in enumerate(images):
            file_path = os.path.join(student_images_dir, f"{i}_{image.filename}")
            with open(file_path, "wb") as buffer:
                shutil.copyfileobj(image.file, buffer)
            
            try:
                # Use Facenet512 and retinaface backend as requested
                # enforce_detection=True ensures we only get valid faces
                representations = DeepFace.represent(
                    img_path=file_path,
                    model_name="Facenet512",
                    detector_backend="retinaface",
                    enforce_detection=True
                )
                
                for embedding_obj in representations:
                    student_encodings.append(embedding_obj["embedding"])
            except Exception as e:
                print(f"Error processing image {file_path}: {e}")
                continue
        
        return student_encodings

    def add_student_encodings(self, session: Session, student: Student, encodings: List[List[float]]):
        student.encodings = encodings
        session.add(student)
        session.commit()
        session.refresh(student)

    def recognize_faces(self, session: Session, image_path: str) -> List[str]:
        try:
            target_representations = DeepFace.represent(
                img_path=image_path,
                model_name="Facenet512",
                detector_backend="retinaface",
                enforce_detection=True
            )
        except Exception as e:
            print(f"Warning: Detection failed for target image: {e}")
            return []
        
        if not target_representations:
            print("DEBUG: No faces detected in target image.")
            return []
        
        print(f"DEBUG: Detected {len(target_representations)} faces in target image.")


        # Fetch all students with encodings from DB
        statement = select(Student)
        students = session.exec(statement).all()
        print(f"DEBUG: Found {len(students)} students in DB.")
        
        recognized_ids = []
        
        # Threshold for Facenet512 Cosine Distance
        # 0.30 is the recommended threshold for Facenet512
        threshold = 0.30

        for target_obj in target_representations:
            target_embedding = target_obj["embedding"]
            
            best_match_id = None
            min_distance = 1000 # Initialize with high value
            
            for student in students:
                if not student.encodings:
                    continue
                    
                for known_embedding in student.encodings:
                    distance = self.find_cosine_distance(known_embedding, target_embedding)
                    print(f"DEBUG: Distance to {student.name} ({student.student_id}): {distance}")
                    
                    if distance < threshold and distance < min_distance:
                        min_distance = distance
                        best_match_id = student.student_id
            
            print(f"DEBUG: Best match for face: {best_match_id} with distance: {min_distance}")
            
            if best_match_id and best_match_id not in recognized_ids:
                recognized_ids.append(best_match_id)
                    
        return recognized_ids
