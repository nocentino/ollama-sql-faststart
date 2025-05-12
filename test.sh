docker compose up --detach 


docker cp ./backups/AdventureWorks2025_FULL.bak ollama-sql-faststart-sql1-1:/var/opt/mssql/data/AdventureWorks2025_FULL.bak
docker exec  -u 0 ollama-sql-faststart-sql1-1 chown mssql:mssql /var/opt/mssql/data/AdventureWorks2025_FULL.bak

# Head over to vector-demos.sql to configure the database and run the demos

docker compose down && \
docker volume rm ollama-sql-faststart_sql-data && \
docker volume rm ollama-sql-faststart_ollama_models &&
rm ./certs/nginx.crt ./certs/nginx.key
