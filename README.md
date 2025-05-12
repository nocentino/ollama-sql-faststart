# Ollama SQL FastStart

## Overview

Ollama SQL FastStart is a Docker-based project designed to simplify the setup and management of a SQL Server 2025 environment integrated with Ollama services. It provides a preconfigured environment for running SQL Server, Ollama, and serving requests through NGINX to Ollama with SSL support and configures SQL Server to trust this certificate. I created this project to help database professionals quickly set up a complete environment for experimenting with the new vector capabilities in SQL Server 2025. If you've been curious about implementing vector search in your SQL Server databases but weren't sure where to start, this project gives you everything you need in a containerized, ready-to-run solution.


## Architecture Overview

The project consists of several Docker containers working together:

1. **SQL Server 2025**: Running the latest release with vector capabilities enabled
2. **Ollama**: An open-source model serving platform that generates text embeddings
3. **NGINX with SSL**: Acts as a secure proxy between SQL Server and Ollama
4. **Automation containers**: For certificate generation, model pulling, and SQL Server configuration
5. **Data Persistence**: Persistent storage for SQL Server and Ollama models.

## Docker Compose Services

1. **`config`**: Generates self-signed SSL certificates for NGINX.
2. **`ollama`**: Runs the Ollama service for managing models.
3. **`model-puller`**: Pulls specific models from Ollama after the service is healthy.
4. **`nginx`**: Acts as a reverse proxy with SSL termination for secure communication.
5. **`sql1`**: SQL Server instance with preconfigured settings and SSL support.
6. **`sql-tools`**: Utility container for running SQL scripts and configuring the database.

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/ollama-sql-faststart.git
   cd ollama-sql-faststart
   ```

2. Build and start the services:
   ```bash
   docker compose up --detach
   ```

3. Verify that all services are running with `docker ps`

      Three containers are running successfully:

      1. **SQL Server** 
         - **Port**: **`1433`** - Connect with SQL clients
         - Status: Healthy

      2. **NGINX Reverse Proxy** 
         - **Port**: **`443`** - Secure Ollama API access
         - Status: Healthy

      3. **Ollama Model Server** 
         - **Port**: **`11434`** - Direct Ollama API access
         - Status: Healthy

      All services are operational and ready for vector database demos.

4. Run Demos in `vector-demos.sql`


## Configuration

- **SSL Certificates**: Self-signed certificates are generated in the `certs` directory.
- **NGINX Configuration**: Modify `nginx.conf` to customize the reverse proxy settings.
- **SQL Server**: Update the `MSSQL_SA_PASSWORD` environment variable in `docker-compose.yml` for a secure password.

## Volumes

- `ollama_models`: Stores Ollama model data.
- `sql-data`: Stores SQL Server data.

## Networks

- `app_network`: Custom Docker network for inter-service communication.

## Usage

- **Start Services**: Use `docker compose up --detach` to start all services.
- **Stop Services**: Use `docker compose down` to stop and remove containers.
- **Clean up resources**: 
   ```
   docker volume rm ollama-sql-faststart_sql-data && \
   docker volume rm ollama-sql-faststart_ollama_models &&
   rm ./certs/nginx.crt ./certs/nginx.key
   ```

