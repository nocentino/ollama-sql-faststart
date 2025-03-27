docker-compose up 


# Check the status of the Ollama service
docker exec ollama ollama ps


# List all available models
docker exec ollama ollama list


# Show details of the nomic-embed-text model
docker exec ollama ollama show nomic-embed-text


# Check if the model exists locally
docker exec ollama sh -c "ollama list | grep -q 'nomic-embed-text' && echo 'Model exists' || echo 'Model does not exist'"


# Test the model with a prompt at the command line
docker exec ollama ollama run nomic-embed-text "Provide embeddings for this sample text."


# Check the logs of the Ollama service for debugging
docker logs ollama



# Test the model with a JSON payload using curl
curl -k https://localhost:443/api/embeddings \
     -H "Content-Type: application/json" \
     -d '{ "model":"nomic-embed-text", "prompt":"Provide embeddings for this sample text." }'


# Test the model with a batch of prompts
docker exec ollama sh -c "ollama run nomic-embed-text 'Prompt 1'; ollama run nomic-embed-text 'Prompt 2'; ollama run nomic-embed-text 'Prompt 3'"


# Test the model with a batch of prompts using curl
curl -k https://localhost:443/api/embeddings \
     -H "Content-Type: application/json" \
     -d '{ "model":"nomic-embed-text", "prompt":"Prompt 1" }'

curl -k https://localhost:443/api/embeddings \
     -H "Content-Type: application/json" \
     -d '{ "model":"nomic-embed-text", "prompt":"Prompt 2" }'

curl -k https://localhost:443/api/embeddings \
     -H "Content-Type: application/json" \
     -d '{ "model":"nomic-embed-text", "prompt":"Prompt 3" }'



docker-compose down 
#&& \
docker volume rm ollama-sql-faststart_sql-data && \
docker volume rm ollama-sql-faststart_ollama_models &&
rm ./certs/nginx.crt ./certs/nginx.key
