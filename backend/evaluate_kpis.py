import time
import statistics
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)

# --- SCENARIOS for KPI 2 (Relevance / Error Rate) ---
# As per the DRP presentation: "Measure something meaningful for your product - not just what is easy to measure."
# For an AAC app, an "Error" is an irrelevant suggestion that forces the user to abandon the smart feature.
TEST_SCENARIOS = [
    {
        "description": "Lunch time",
        "payload": {
            "text": "It's time for lunch, what do you want to eat?",
            "likes": ["pizza", "apple", "sandwich"],
            "dislikes": ["pasta"]
        },
        "expected_keywords": ["pizza", "apple", "sandwich", "eat", "food", "hungry", "water", "drink"]
    },
    {
        "description": "Play time",
        "payload": {
            "text": "What do you want to play with today?",
            "likes": ["Legos", "Dinosaurs"],
            "dislikes": []
        },
        "expected_keywords": ["legos", "dinosaurs", "play", "want", "game", "blocks", "toys"]
    },
    {
        "description": "Feeling unwell",
        "payload": {
            "text": "Are you feeling okay?",
            "likes": [],
            "dislikes": []
        },
        "expected_keywords": ["yes", "no", "sick", "tired", "hurt", "bad", "good", "sad", "okay", "fine"]
    },
    {
        "description": "Going outside",
        "payload": {
            "text": "We are going outside to the park now.",
            "likes": ["slide", "running"],
            "dislikes": ["sand"]
        },
        "expected_keywords": ["park", "slide", "run", "running", "fun", "yay", "no", "outside", "play"]
    }
]

def run_evaluation():
    print("="*60)
    print(" DRP IMPACT DEVELOPMENT - KPI EVALUATION")
    print("="*60)
    print("Aligned with 'DRP - Impact Development.pdf':")
    print(" 1. Processing Time (Component of 'Total Time per Interaction')")
    print(" 2. Prediction Relevance (Inverse of 'Error Rate')")
    print("="*60)

    latencies = []
    relevance_scores = []

    for i, scenario in enumerate(TEST_SCENARIOS):
        print(f"\n[Scenario {i+1}/{len(TEST_SCENARIOS)}]: {scenario['description']}")
        
        # 1. Measure Processing Time (Latency)
        start_time = time.perf_counter()
        
        response = client.post("/api/context/predict", json=scenario["payload"])
        
        end_time = time.perf_counter()
        
        processing_time_ms = (end_time - start_time) * 1000
        latencies.append(processing_time_ms)
        
        if response.status_code != 200:
            print(f"  [!] Error: Endpoint returned {response.status_code}")
            print(f"  Details: {response.text}")
            continue
            
        predictions = response.json().get("predictions", [])
        print(f"  -> Processing Time: {processing_time_ms:.2f} ms")
        print(f"  -> AI Predictions:  {predictions}")
        
        # 2. Measure Relevance (Error Rate)
        # We consider a prediction "relevant" if it conceptually matches expected keywords.
        hits = 0
        predictions_lower = [str(p).lower() for p in predictions]
        
        for pred in predictions_lower:
            # Check if any expected keyword is in the prediction (or vice versa)
            if any(expected in pred or pred in expected for expected in scenario["expected_keywords"]):
                hits += 1
                
        # Calculate score (e.g., out of the max number of suggestions generated)
        max_possible = len(predictions) if predictions else 4
        score = (hits / max_possible) * 100 if max_possible > 0 else 0
        relevance_scores.append(score)
        
        print(f"  -> Relevance Score: {score:.1f}% ({hits}/{max_possible} hits)")

    print("\n" + "="*60)
    print(" FINAL METRICS REPORT")
    print("="*60)
    if latencies:
        print(f"Processing Time (Latency):")
        print(f"  - Average: {statistics.mean(latencies):.2f} ms")
        print(f"  - Peak:    {max(latencies):.2f} ms")
        print(f"  - Fastest: {min(latencies):.2f} ms")
        print("\nPrediction Relevance (Accuracy):")
        print(f"  - Average Relevance Score: {statistics.mean(relevance_scores):.1f}%")
        print(f"  - Equivalent Error Rate:   {100 - statistics.mean(relevance_scores):.1f}%")
    else:
        print("No successful scenarios ran.")
    print("="*60)

if __name__ == "__main__":
    run_evaluation()
