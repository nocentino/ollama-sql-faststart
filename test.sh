# Start up the Ollama SQL Faststart demo with Docker Compose
# This script will start up the Ollama SQL Faststart demo with Docker Compose
docker compose up --detach 

# Head over to vector-demos.sql to configure the database and run the demos


# Clean up the Docker containers and volumes after the demo
# This script will stop and remove the Docker containers, volumes and clean up the certificates
docker compose down && \
docker volume rm ollama-sql-faststart_sql-data && \
docker volume rm ollama-sql-faststart_ollama_models &&
rm ./certs/nginx.crt ./certs/nginx.key
