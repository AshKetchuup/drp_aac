FROM python:3.10-slim

# Install curl (needed to install ollama)
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Install Ollama
RUN curl -fsSL https://ollama.com/install.sh | sh

# Set up the working directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the backend code
COPY . .

# Make the start script executable
RUN chmod +x start.sh

# Expose the port Coolify will use (usually 8000)
EXPOSE 8000

# Run the startup script
CMD ["./start.sh"]
