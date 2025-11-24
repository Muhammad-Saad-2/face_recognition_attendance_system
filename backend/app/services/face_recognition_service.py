import face_recognition
import pickle
import os
import shutil
from typing import List, Dict
from fastapi import UploadFile
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

    def process_student_images(self, student_id: str, images: List[UploadFile]) -> List:
        student_encodings = []
        student_images_dir = os.path.join(self.images_dir, student_id)
        os.makedirs(student_images_dir, exist_ok=True)

        for i, image in enumerate(images):
            file_path = os.path.join(student_images_dir, f"{i}_{image.filename}")
            with open(file_path, "wb") as buffer:
                shutil.copyfileobj(image.file, buffer)
            
            # Load image for face recognition
            img = face_recognition.load_image_file(file_path)
            encs = face_recognition.face_encodings(img)
            
            if len(encs) > 0:
                student_encodings.append(encs[0])
        
        return student_encodings

    def add_student_encodings(self, student_id: str, encodings: List):
        known_encodings = self.load_encodings()
        known_encodings[student_id] = encodings
        self.save_encodings(known_encodings)

    def recognize_faces(self, image_path: str) -> List[str]:
        unknown_image = face_recognition.load_image_file(image_path)
        unknown_encodings = face_recognition.face_encodings(unknown_image)
        
        if not unknown_encodings:
            return []

        known_encodings_dict = self.load_encodings()
        known_faces = []
        known_ids = []
        
        for s_id, encs in known_encodings_dict.items():
            for enc in encs:
                known_faces.append(enc)
                known_ids.append(s_id)

        if not known_faces:
            return []

        recognized_ids = []
        for unknown_encoding in unknown_encodings:
            matches = face_recognition.compare_faces(known_faces, unknown_encoding, tolerance=0.5)
            # face_distances = face_recognition.face_distance(known_faces, unknown_encoding)
            
            if True in matches:
                first_match_index = matches.index(True)
                student_id = known_ids[first_match_index]
                if student_id not in recognized_ids:
                    recognized_ids.append(student_id)
                    
        return recognized_ids
