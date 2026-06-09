#!/bin/bash

# Start Ollama in the background
echo "Starting Ollama daemon..."
ollama serve &

# Wait a few seconds for the daemon to initialize
sleep 5

# Pull the specific model you are using in predictions.py
echo "Pulling llama3.2:1b model..."
ollama pull llama3.2:1b

# Start the FastAPI server
echo "Starting FastAPI server..."
# Coolify passes the port in the $PORT environment variable, default to 8000
PORT=${PORT:-8000}
python -m uvicorn app.main:app --host 0.0.0.0 --port $PORT
