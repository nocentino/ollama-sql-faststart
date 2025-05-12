docker compose up --detach 

# Head over to vector-demos.sql to configure the database and run the demos

docker compose down && \
docker volume rm ollama-sql-faststart_sql-data && \
docker volume rm ollama-sql-faststart_ollama_models &&
rm ./certs/nginx.crt ./certs/nginx.key
