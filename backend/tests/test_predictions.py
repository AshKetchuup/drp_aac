# import base64
# from fastapi.testclient import TestClient
# from app.main import app

# client = TestClient(app)


# def test_predict_valid_base64_returns_predictions():
#     text = "I love minecraft"
#     encoded = base64.b64encode(text.encode("utf-8")).decode("utf-8")

#     response = client.post(
#         "/predict",
#         json={"audio_base64": encoded}
#     )

#     assert response.status_code == 200
#     data = response.json()

#     assert "predictions" in data


# def test_predict_invalid_base64_returns_400():
#     response = client.post(
#         "/predict",
#         json={"audio_base64": "%%%notbase64%%%"}
#     )

#     assert response.status_code == 400
#     assert response.json()["detail"] == "Invalid base64 input"
