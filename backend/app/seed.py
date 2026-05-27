from app.db import db

def seed_data():
    teachers_ref = db.collection("teachers")
    
    if not list(teachers_ref.limit(1).stream()):
        _, teacher_ref = teachers_ref.add({
            "name": "Rupert Polanski",
            "email": "rp1224@ic.ac.uk"
        })

        teacher_id = teacher_ref.id

        students_ref = db.collection("students")
        students_ref.add({"name": "May", "age": 14, "teacher_id": teacher_id})
        students_ref.add({"name": "June", "age": 15, "teacher_id": teacher_id})

        minigames_ref = db.collection("minigames")
        minigames_ref.add({
            "title": "Cannonball!",
            "description": "Select and launch words into the correct sentence using a cannon. Practice choosing functional words (like 'a', 'the', and other sentence parts) to build correct sentences. Supports AAC users in grammar, sequencing, and structured language building.",
            "category": "Articles"
        })
        minigames_ref.add({
            "title": "Traffic Jam",
            "description": "Help clear a traffic jam by using words to decide where each word belongs. Each car represents a category, idea, or meaning, and the user must match words to the correct car to move the traffic forward. This supports vocabulary building, word association, and categorization skills in an AAC-friendly way.",
            "category": "Vocabulary"
        })
