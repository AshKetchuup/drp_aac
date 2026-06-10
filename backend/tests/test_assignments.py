# from datetime import datetime
# from unittest.mock import MagicMock, patch
# from fastapi.testclient import TestClient
# import pytest

# from app.main import app

# client = TestClient(app)

# @pytest.fixture
# def mock_db():
#     """Fixture to mock the Firestore client 'db' in app.db."""
#     with patch("app.routers.assignments.db") as mock:
#         yield mock

# def test_create_assignment_success(mock_db):
#     mock_teacher_doc = MagicMock()
#     mock_teacher_doc.exists = True
#     mock_db.collection.return_value.document.return_value.get.side_effect = [
#         mock_teacher_doc,
#     ]

#     mock_student_doc = MagicMock()
#     mock_student_doc.exists = True
#     mock_student_doc.to_dict.return_value = {"teacher_id": "teacher_123", "name": "May"}
    
#     mock_minigame_doc = MagicMock()
#     mock_minigame_doc.exists = True

#     mock_db.collection.return_value.document.return_value.get.side_effect = [
#         mock_teacher_doc,
#         mock_student_doc,
#         mock_minigame_doc
#     ]

#     mock_doc_ref = MagicMock()
#     mock_doc_ref.id = "new_assignment_999"
#     mock_db.collection.return_value.add.return_value = (None, mock_doc_ref)

#     payload = {
#         "teacher_id": "teacher_123",
#         "student_id": "student_456",
#         "minigame_id": "minigame_789"
#     }

#     response = client.post("/assignments", json=payload)

#     assert response.status_code == 200
#     data = response.json()
#     assert data["id"] == "new_assignment_999"
#     assert data["status"] == "assigned"
#     assert data["teacher_id"] == "teacher_123"


# def test_create_assignment_teacher_not_found(mock_db):
#     mock_teacher_doc = MagicMock()
#     mock_teacher_doc.exists = False
#     mock_db.collection.return_value.document.return_value.get.return_value = mock_teacher_doc

#     payload = {
#         "teacher_id": "invalid_teacher",
#         "student_id": "student_456",
#         "minigame_id": "minigame_789"
#     }

#     response = client.post("/assignments", json=payload)

#     assert response.status_code == 404
#     assert response.json()["detail"] == "Teacher not found"


# def test_create_assignment_student_belongs_to_different_teacher(mock_db):
#     mock_teacher_doc = MagicMock()
#     mock_teacher_doc.exists = True

#     mock_student_doc = MagicMock()
#     mock_student_doc.exists = True
#     mock_student_doc.to_dict.return_value = {"teacher_id": "different_teacher", "name": "May"}

#     mock_db.collection.return_value.document.return_value.get.side_effect = [
#         mock_teacher_doc,
#         mock_student_doc
#     ]

#     payload = {
#         "teacher_id": "teacher_123",
#         "student_id": "student_456",
#         "minigame_id": "minigame_789"
#     }

#     response = client.post("/assignments", json=payload)

#     assert response.status_code == 403
#     assert response.json()["detail"] == "Student does not belong to this teacher"
