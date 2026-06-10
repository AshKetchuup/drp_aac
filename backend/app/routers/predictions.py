import base64
from fastapi import APIRouter, HTTPException, Depends
from app.schemas import PredictionRequest, PredictionResponse
from app.auth import get_current_user
import ollama
import json

router = APIRouter(prefix="/api/context", tags=["predictions"])

past_predictions = [
    {
        "text": "I want juice",
        "response": ["Juice", "please"]
    },
    {
        "text": "I like sandwitches",
        "response": ["Me too", "Yes"]
    },
    
]

payload_mock = PredictionRequest(
    audio_base64="mock_base64_audio",
    text="What do you want to play with today?",
    likes=["Legos", "Dinosaurs", "Pizza", "Cycling", "Lentil soup", "Mom"],
    dislikes=["Rainy days", "Beets", "Oranges"]
)

@router.post("/predict", response_model=PredictionResponse)
def predict_words(payload: PredictionRequest, user: dict = Depends(get_current_user)):
    try:
        if payload.audio_base64:
            decoded_bytes = base64.b64decode(payload.audio_base64)
            decoded_bytes.decode("utf-8")
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid base64 input")
    

    predictions = generate_suggestions(payload)
    print("predictions", predictions)
    
    # Store the history so the AI remembers what the child says
    past_predictions.append({
        "text": payload.text,
        "response": predictions
    })
    
    return {
        "predictions": predictions
    }




def generate_suggestions(payload):
    likes_str = ", ".join(payload.likes) if payload.likes else "None"
    dislikes_str = ", ".join(payload.dislikes) if payload.dislikes else "None"
    

    history_str = ""
    for past in past_predictions[-3:]:  # Only take the last 3 to keep it fast
        history_str += f"- Context: '{past['text']}' -> Child said: {past['response']}\n"
    if not history_str:
        history_str = "No recent history."
        
    system_prompt = f"""You are the predictive engine for a non-verbal child's AAC (communication) app. 
Your job is to predict 3 to 6 single words or short phrases the child might want to communicate next.

Child's Profile:
- Likes: {likes_str}
- Dislikes: {dislikes_str}

Recent Communication History:
{history_str}

CRITICAL RULES:
1. FRINGE VOCABULARY: Provide specific, subject-related words the child needs for this specific topic (e.g. names, specific nouns, descriptive adjectives). DO NOT provide basic core words (like "Yes", "No", "I want") because they already have those on their board.
2. Bias your suggestions toward the child's 'Likes' when appropriate.
3. Output ONLY a valid JSON array of strings. No explanation.
4. You may need to include subject related words from the child that gets said in the context.

EXAMPLES:
Context: "Who is the GOAT of football?"
Output: ["Messi", "Ronaldo", "Pele", "Maradona"]

Context: "What do you want to play with?"
Likes: legos, cars
Dislikes: dolls
Output: ["Red car", "Lego batman", "Race track", "Build tower"]"""

    user_prompt = f"""Someone just said this to the child: "{payload.text}"

IMPORTANT: The child likes: {likes_str}. The child dislikes: {dislikes_str}.
Provide AT LEAST 3 subject-specific, DISTINCT, advanced words related to this topic. Output JSON array only."""

    response = ollama.chat(
        model='qwen2.5:1.5b', 
        messages=[
            {'role': 'system', 'content': system_prompt},
            {'role': 'user', 'content': user_prompt}
        ],
        format='json',
        options={
            'num_predict': 80,
            'num_ctx': 512,
            'temperature': 0.7,
        }
    )
    
    json_string = response['message']['content']
    parsed = json.loads(json_string)
    
    if isinstance(parsed, dict):
        raw_list = []
        for val in parsed.values():
            if isinstance(val, list):
                raw_list.extend(val)
            else:
                raw_list.append(val)
    elif isinstance(parsed, list):
        raw_list = parsed
    else:
        raw_list = [parsed]
        
    # Fully flatten any nested lists and convert to strings
    suggestions_list = []
    for item in raw_list:
        if isinstance(item, list) and len(item) > 0:
            suggestions_list.append(str(item[0]))
        else:
            suggestions_list.append(str(item))
        
    return suggestions_list[:5]


if __name__ == '__main__':
    print(generate_suggestions(payload_mock))
