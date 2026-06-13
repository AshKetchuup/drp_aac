from fastapi import APIRouter, Depends
from app.schemas import PredictionRequest, PredictionResponse
from app.auth import get_current_user
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
    text="What is your favourite Operating system?",
    likes=["Park", "Swings", "Library", "Grandma's house", "Dogs"],
    dislikes=["Loud noises", "Dark rooms", "Nap time"]
)

@router.post("/predict", response_model=PredictionResponse)
def predict_words(payload: PredictionRequest, user: dict = Depends(get_current_user)):
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
    exclude_str = ", ".join(payload.current_suggestions) if payload.current_suggestions else "None"

    history_str = ""
    for past in past_predictions[-3:]:  # Only take the last 3 to keep it fast
        history_str += f"- Context: '{past['text']}' -> Child said: {past['response']}\n"
    if not history_str:
        history_str = "No recent history."
        
    system_prompt = f"""You are a speech therapist/SEND teacher helping a non-verbal child communicate using an AAC app.
Your task: given what someone just said to the child, predict the words the child most likely wants to say back.

The child's favourite things: {likes_str}
Things the child dislikes: {dislikes_str}
Already suggested (DO NOT SUGGEST THESE AGAIN): {exclude_str}

What the child said recently:
{history_str}

RULES:
- IMPORTANT: SUGGEST ATLEAST {payload.min_suggestions} to {payload.min_suggestions + 4} words or short phrases the child would realistically reply with.
- IMPORTANT: Include the words from MOST RELEVANT to LEAST RELEVANT. 
- INCLUDE THE PROPER NOUNS WITHIN THE SENTENCE, that are not already in the AAC board.
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
Child dislikes: {dislikes_str}"""

    if payload.current_suggestions:
        exclude_str = ", ".join(payload.current_suggestions)
        user_prompt += f"\n\nCRITICAL: You have already suggested the following words: {exclude_str}.\nYOU MUST NOT SUGGEST ANY OF THOSE WORDS AGAIN. Give me entirely DIFFERENT options!"

    user_prompt += "\nAnswer:"

    response = ollama.chat(
        model='qwen2.5:1.5b', # Extremely smart 1B model
        messages=[
            {'role': 'system', 'content': system_prompt},
            {'role': 'user', 'content': user_prompt}
        ],
        format='json',
        keep_alive=-1,  # CRITICAL FOR SPEED: Keeps model loaded in RAM permanently
        options={
            'num_predict': 256, # Increased to prevent cutting off long JSON arrays
            'num_ctx': 1024,
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
        
    # Fully flatten any nested lists, split comma-separated strings, and convert to strings
    suggestions_list = []
    existing_lower = set(s.lower() for s in payload.current_suggestions) if payload.current_suggestions else set()
    
    for item in raw_list:
        val = ""
        if isinstance(item, list) and len(item) > 0:
            val = str(item[0])
        else:
            val = str(item)
            
        # The small models sometimes return ["word1, word2"] instead of ["word1", "word2"]
        # Split by comma to fix this if it happens.
        for split_val in val.split(','):
            cleaned = split_val.strip()
            # Remove leading '#' if the model added it randomly
            if cleaned.startswith('#'):
                cleaned = cleaned[1:].strip()
                
            if cleaned:
                cleaned_lower = cleaned.lower()
                if cleaned_lower not in existing_lower:
                    suggestions_list.append(cleaned)
                    existing_lower.add(cleaned_lower)
        
    return suggestions_list[:max(payload.min_suggestions + 4, 8)]


if __name__ == '__main__':
    print(generate_suggestions(payload_mock))
