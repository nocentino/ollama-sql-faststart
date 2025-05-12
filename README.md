# Ollama SQL FastStart

## Overview

Ollama SQL FastStart is a Docker-based project designed to simplify the setup and management of a SQL Server 2025 environment integrated with Ollama services. It provides a preconfigured environment for running SQL Server, managing models, and serving requests through NGINX with SSL support and configures SQL Server to trust this certificate.

## Features

- **SQL Server**: A preconfigured SQL Server instance.
- **Ollama Integration**: Includes Ollama services for model management and pulling.
- **NGINX with SSL**: Secure reverse proxy setup using NGINX and self-signed certificates.
- **Health Checks**: Automated health checks for critical services.
- **Data Persistence**: Persistent storage for SQL Server and Ollama models.
- **Automation**: Scripts for initializing and configuring the SQL Server environment.

## Services

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
   docker-compose up --detach
   ```

3. Verify that all services are running:
   - Access the SQL Server on port `1433`.
   - Access the Ollama service on port `11434`.
   - Access NGINX on port `443` which routes to Ollama.

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

- **Start Services**: Use `docker-compose up --detach` to start all services.
- **Stop Services**: Use `docker-compose down` to stop and remove containers.
- **Clean up resources**: 
   ```
   docker volume rm ollama-sql-faststart_sql-data && \
   docker volume rm ollama-sql-faststart_ollama_models &&
   rm ./certs/nginx.crt ./certs/nginx.key
   ```

