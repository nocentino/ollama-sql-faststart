---
title: "Getting Started with Vector Search in SQL Server 2025 Using Ollama"
author: Anthony Nocentino
date: 2025-05-09T05:00:00-05:01
draft: true
categories:
 - SQL Server
 - SQL Server 2025
 - Pure Storage
 - T-SQL REST API Integrations
 - Using T-SQL Snapshot Backup
tags:
 - SQL Server
 - SQL Server 2025
 - Pure Storage
 - T-SQL REST API Integrations
 - Using T-SQL Snapshot Backup
---

# Ollama SQL FastStart

Ollama SQL FastStart is a Docker-based project designed to simplify the setup and management of a SQL Server 2025 environment integrated with Ollama services. It offers a preconfigured environment for running SQL Server and Ollama, while also serving requests through NGINX with SSL support. Additionally, it configures SQL Server to trust this SSL certificate.

I created this project to assist database professionals in quickly establishing a complete environment for exploring the new vector capabilities in SQL Server 2025. If you have been interested in implementing vector search in your SQL Server databases but were unsure where to begin, this project provides everything you need in a ready-to-run, containerized solution. The project automatically handles the requirement for SQL Server to trust the SSL certificate used by NGINX for secure communication with Ollama.

> **Note:** If you're using a Mac with an M-series CPU, Rosetta does not support the AVX instruction. SQL Server utilizes AVX to enhance vector operations. Unfortunately, you will need to use an Intel-based machine for this.


## Architecture Overview

The project consists of several Docker containers working together:

1. **SQL Server 2025**: Running the latest release with vector capabilities enabled
2. **Ollama**: An open-source model serving platform that generates text embeddings
3. **NGINX with SSL**: Acts as a secure proxy between SQL Server and Ollama
4. **Automation containers**: For certificate generation, model pulling, and SQL Server configuration
5. **Data Persistence**: Persistent storage for SQL Server and Ollama models.


The docker compose implementation process will:
- Generate SSL certificates for secure communication
- Start SQL Server 2025
- Launch Ollama and pull the `nomic-embed-text` model
- Configure SQL Server to trust the certificates
- Create an external model connection to Ollama's secure TLS endpoint in SQL Server

## Docker Compose Services

Everything is tied together with Docker Compose for easy deployment. The architecture ensures secure communication between components while keeping everything neatly containerized.

| Service | Description |
|---------|-------------|
| **`config`** | Generates self-signed SSL certificates for NGINX |
| **`ollama`** | Runs the Ollama service for managing models |
| **`model-puller`** | Pulls specific models from Ollama after the service is healthy |
| **`nginx`** | Acts as a reverse proxy with SSL termination for secure communication |
| **`sql1`** | SQL Server instance with preconfigured settings for Vector, Rest and SSL support |
| **`sql-tools`** | Utility container for running SQL scripts and configuring the database |

## Getting Started

### 1. Clone the repository:
```bash
git clone https://github.com/your-username/ollama-sql-faststart.git
cd ollama-sql-faststart
```

### 2. Build and start the services:
```bash
docker compose up --detach
```

### 3. Verify that all services are running with `docker ps`

Three containers are running successfully:

| Container | Port | Purpose | Status |
|-----------|------|---------|--------|
| **SQL Server** | **`1433`** | Connect with SQL clients | Healthy |
| **NGINX Reverse Proxy** | **`443`** | Secure Ollama API access | Healthy |
| **Ollama Model Server** | **`11434`** | Direct Ollama API access | Healthy |

All services are operational and ready for vector database demos.

Once up and running, you'll have access to:
- SQL Server on port 1433
- Ollama on port 11434
- NGINX enabling TLS Access to Ollama's API on port 443

## Working with Vector Embeddings in SQL Server

The SQL script `vector-demos.sql` demonstrates vector search capabilities in SQL Server 2025 with Ollama integration:

Connect using your favorite SQL Server tooling, SSMS, or VSCode to localhost, 1433. The default username is `sa,` and the default password is `S0methingS@Str0ng!` 

### Demo Steps

The demo script is broken up into 5 steps walking you through how to setup SQL Server 2025 database for AI enabled similarity search.

#### 1. Database Setup
- Restores `AdventureWorks2025` database from backup

#### 2. Vector Storage
- Adds `VECTOR(768)` column to `Product` table for embeddings
- Adds text `chunk` column for storing descriptive text

#### 3. Embedding Generation
- Processes each product record
- Creates text descriptions by combining product attributes
- Generates vector embeddings using Ollama and the new to SQL Server 2025 function (`AI_GENERATE_EMBEDDINGS`)

#### 4. Basic Vector Search
- Demonstrates semantic queries with cosine distance calculation

#### 5. Advanced Vector Search
- Enables required trace flags
- Creates a vector index using the DiskANN algorithm
- Performs efficient Approximate Nearest Neighbor (ANN) search

The script showcases a complete vector search implementation from setup to optimized semantic queries.

## Conclusion

SQL Server 2025's vector capabilities represent a significant step forward for integrating AI into traditional database workloads. The ability to perform semantic search directly within SQL Server opens up a whole new world of possibilities for your applications.

This project makes it easy to explore these features in a easy to configure, containerized environment. If you're interested in vector search, semantic analysis, or keeping up with the latest database technologies, I encourage you to clone this repo and experiment!
