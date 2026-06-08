import base64
import sys
import os

# Add the backend directory to sys.path to allow running this file directly
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../..')))

from fastapi import APIRouter, HTTPException
from app.schemas import PredictionRequest, PredictionResponse
import ollama
import json

router = APIRouter(prefix="/api/context", tags=["predictions"])

past_predictions = [
    {
        "text": "What do you want for snack?",
        "response": ["Apple", "Crackers", "Juice box", "Yogurt"]
    },
    {
        "text": "What are your favourite subjects?",
        "response": ["Maths", "English"]
    },
    
]

payload_mock = PredictionRequest(
    audio_base64="mock_base64_audio",
    text="What kind of pets would you like?",
    likes=["Park", "Swings", "Library", "Grandma's house", "Dogs"],
    dislikes=["Loud noises", "Dark rooms", "Nap time"]
)

@router.post("/predict", response_model=PredictionResponse)
def predict_words(payload: PredictionRequest):
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
        
    system_prompt = f"""You are a speech therapist/SEND teacher helping a non-verbal child communicate using an AAC app.
Your task: given what someone just said to the child, predict the words the child most likely wants to say back.

The child's favourite things: {likes_str}
Things the child dislikes: {dislikes_str}

What the child said recently:
{history_str}

RULES:
- Suggest 4 to 7 words or short phrases the child would realistically reply with.
- IF the child's likes are directly relevant to the topic, include them. 
- CRITICAL: Dont OVER use the likes if not relevant. DO NOT include random likes (like "Park" or "Swings") if the topic is about something completely different (like "Pets"). Instead, suggest other things to expand the child's vocabulary and general knowledge.
- NEVER include anything from the dislikes list.
- Focus on specific, meaningful vocabulary (nouns, verbs, adjectives) — NOT generic words like "Yes", "No", "Please", "I want" since those are already on the child's board.
- Use the conversation history to make smarter, contextual predictions.
- Return ONLY a valid JSON array of strings. Nothing else. No numbers, no explanations, no keys.
- NO REPEATS

GOOD example:
Someone said: "What animal do you like?"
Child likes: Dogs, Cats, Park, Swings
Child dislikes: Spiders
Answer: ["Dogs", "Cats", "Rabbits", "Hamster", "Fish"]

BAD example (NEVER do this):
["1", "Dogs", "2", "Cats"] — numbers are WRONG
{{"animals": ["Dogs"]}} — objects are WRONG
["Dogs", "Park", "Swings"] — WRONG: "Park" and "Swings" are not animals! Do not force irrelevant likes!"""

    user_prompt = f"""Someone said: "{payload.text}"
Child likes: {likes_str}
Child dislikes: {dislikes_str}
Answer:"""

    response = ollama.chat(
        model='llama3.2', # Extremely smart 3B model (smarter than Qwen 1.5b)
        messages=[
            {'role': 'system', 'content': system_prompt},
            {'role': 'user', 'content': user_prompt}
        ],
        format='json',
        keep_alive=-1,  # CRITICAL FOR SPEED: Keeps model loaded in RAM permanently
        options={
            'num_predict': 80, # We only need a few words, stop generating sooner
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
        
    return suggestions_list[:8]


if __name__ == '__main__':
    print(generate_suggestions(payload_mock))
