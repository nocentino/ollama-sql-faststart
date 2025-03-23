docker-compose up -d


# Check the status of the Ollama service
docker exec ollama ollama status 


# List all available models
docker exec ollama ollama list


# Check if the model exists locally
docker exec ollama sh -c "ollama list | grep -q 'nomic-embed-text' && echo 'Model exists' || echo 'Model does not exist'"


# Test the model
docker exec ollama sh -c "ollama run nomic-embed-text 'test text'"

# Check the logs of the Ollama service for debugging
docker logs ollama


# Test the model with a JSON payload using curl
curl -k --resolve model.example.com:443:172.18.0.20 https://model.example.com:443/api/embeddings \
     -H "Content-Type: application/json" \
     -d '{ "model":"nomic-embed-text", "prompt":"Provide embeddings for this sample text." }'


# Test the model with a batch of prompts
docker exec ollama sh -c "ollama run nomic-embed-text 'Prompt 1'; ollama run nomic-embed-text 'Prompt 2'; ollama run nomic-embed-text 'Prompt 3'"


# Test the model with a batch of prompts using curl
curl -k --resolve model.example.com:443:172.18.0.20 https://model.example.com:443/api/embeddings \
     -H "Content-Type: application/json" \
     -d '{ "model":"nomic-embed-text", "prompt":"Prompt 1" }'

curl -k --resolve model.example.com:443:172.18.0.20 https://model.example.com:443/api/embeddings \
     -H "Content-Type: application/json" \
     -d '{ "model":"nomic-embed-text", "prompt":"Prompt 2" }'

curl -k --resolve model.example.com:443:172.18.0.20 https://model.example.com:443/api/embeddings \
     -H "Content-Type: application/json" \
     -d '{ "model":"nomic-embed-text", "prompt":"Prompt 3" }'


# Use the sqltools container to run the SQL script configure_model.sql



docker-compose down
docker volume rm ollam-faststarrt_ollama_models ollam-faststarrt_sql-data
