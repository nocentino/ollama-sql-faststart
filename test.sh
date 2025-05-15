# Start up the Ollama SQL Faststart demo with Docker Compose
# This script will start up the Ollama SQL Faststart demo with Docker Compose
docker compose up --detach 


# Head over to vector-demos.sql to configure the database and run the demos


# Clean up the Docker containers and volumes after the demo
# This script will stop and remove the Docker containers, volumes and clean up the certificates
docker compose down && \
docker volume rm ollama-sql-faststart_sql-data && \
docker volume rm ollama-sql-faststart_ollama_models


docker run \
    --name 'sql2' \
    --hostname 'sql2' \
    -e 'ACCEPT_EULA=Y' \
    -e 'MSSQL_SA_PASSWORD=S0methingS@Str0ng!' \
    -p 1434:1433 \
    -d sqlservereap.azurecr.io/mssql-sql2025-ctp1-5-release/mssql-server-ubuntu-22.04 
