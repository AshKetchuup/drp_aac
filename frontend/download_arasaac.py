import os
import requests
import json
import time

WORDS = [
    "who", "what", "why", "where", "when", "now", "then", "daily", "play",
    "i", "to", "want", "come", "see", "this", "that", "chat", "news",
    "my", "be", "stop", "go", "put", "in", "on", "position", "places",
    "it", "can", "like", "get", "good", "a", "the", "time", "feelings",
    "you", "do", "need", "help", "more", "and", "with", "topics", "school",
    "people", "have", "questions", "actions", "describe", "little words", "not", "messages", "spelling abc"
]

os.makedirs('assets/arasaac', exist_ok=True)

for word in WORDS:
    search_word = word.split('/')[0].replace('?', '').strip().lower()
    if search_word == "don't like":
        search_word = "dislike"
    
    print(f"Searching for {search_word}...")
    try:
        url = f"https://api.arasaac.org/api/pictograms/en/search/{search_word}"
        response = requests.get(url)
        if response.status_code == 200:
            data = response.json()
            if data and len(data) > 0:
                pic_id = data[0]['_id']
                img_url = f"https://static.arasaac.org/pictograms/{pic_id}/{pic_id}_300.png"
                img_res = requests.get(img_url)
                if img_res.status_code == 200:
                    # Save as the original requested label
                    filename = word.replace('?', '').replace('/', '_').replace("'", "").replace(" ", "_").lower()
                    with open(f"assets/arasaac/{filename}.png", 'wb') as f:
                        f.write(img_res.content)
                    print(f"Saved {filename}.png")
                else:
                    print(f"Failed to download image for {search_word}")
            else:
                print(f"No results for {search_word}")
        else:
            print(f"API failed for {search_word}")
    except Exception as e:
        print(f"Error for {search_word}: {e}")
    time.sleep(0.5)
