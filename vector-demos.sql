-- Step 1: Restore the AdventureWorks2025 database from a backup file -------------------
-- Disconnect all users from the database before restore
ALTER DATABASE [AdventureWorksLT] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO
USE [master];
GO
RESTORE DATABASE [AdventureWorksLT]
FROM DISK = '/var/opt/mssql/data/AdventureWorks2025_FULL.bak'
WITH
    MOVE 'AdventureWorksLT2022_Data' TO '/var/opt/mssql/data/AdventureWorksLT_Data.mdf',
    MOVE 'AdventureWorksLT2022_Log' TO '/var/opt/mssql/data/AdventureWorksLT_log.ldf',
    FILE = 1,
    NOUNLOAD,
    STATS = 5,
    REPLACE;
GO

----------------------------------------------------------------------------------------

-- Step 2: Create and test an External Model pointing to our local Ollama Container ----
USE [AdventureWorksLT]
GO

CREATE EXTERNAL MODEL ollama
WITH (
    LOCATION = 'https://model-web:443/api/embed',
    API_FORMAT = 'Ollama',
    MODEL_TYPE = EMBEDDINGS,
    MODEL = 'nomic-embed-text'
);
GO

PRINT 'Testing the external model by calling AI_GENERATE_EMBEDDINGS function...';
GO
BEGIN
    DECLARE @result NVARCHAR(MAX);
    SET @result = (SELECT CONVERT(NVARCHAR(MAX), AI_GENERATE_EMBEDDINGS(N'test text' USE MODEL ollama)))
    SELECT AI_GENERATE_EMBEDDINGS(N'test text' USE MODEL ollama) AS GeneratedEmbedding

    IF @result IS NOT NULL
        PRINT 'Model test successful. Result: ' + @result;
    ELSE
        PRINT 'Model test failed. No result returned.';
END;
GO
----------------------------------------------------------------------------------------


-- Step 3: Create a new table for storing product embeddings ---------------------------
USE [AdventureWorksLT];
GO

CREATE TABLE [SalesLT].[ProductEmbeddings] (
    ProductID INT PRIMARY KEY,
    embeddings VECTOR(768),
    chunk NVARCHAR(2000)
);
GO
----------------------------------------------------------------------------------------


-- Step 4: CREATE THE EMBEDDINGS -------------------------------------------------------
INSERT INTO [SalesLT].[ProductEmbeddings] (ProductID, chunk, embeddings)
SELECT 
    p.ProductID,
    p.Name + ' ' + ISNULL(p.Color, 'No Color') + ' ' + c.Name + ' ' + m.Name + ' ' + ISNULL(d.Description, '') AS chunk,
    AI_GENERATE_EMBEDDINGS(p.Name + ' ' + ISNULL(p.Color, 'No Color') + ' ' + c.Name + ' ' + m.Name + ' ' + ISNULL(d.Description, '') USE MODEL ollama) AS embeddings
FROM [SalesLT].[Product] p
JOIN [SalesLT].[ProductCategory] c ON p.ProductCategoryID = c.ProductCategoryID
JOIN [SalesLT].[ProductModel] m ON p.ProductModelID = m.ProductModelID
LEFT JOIN [SalesLT].[vProductAndDescription] d ON p.ProductID = d.ProductID AND d.Culture = 'en';

-- Review the created embeddings
SELECT TOP 10 pe.*, p.Name 
FROM [SalesLT].[ProductEmbeddings] pe
JOIN [SalesLT].[Product] p ON pe.ProductID = p.ProductID;
----------------------------------------------------------------------------------------


-- Step 5: Perform Vector Search -------------------------------------------------------
SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO
DECLARE @search_text NVARCHAR(MAX) = 'I am looking for a red bike and I dont want to spend a lot';
DECLARE @search_vector VECTOR(768) = AI_GENERATE_EMBEDDINGS(@search_text USE MODEL ollama);

SELECT TOP(4)
    pe.ProductID,
    p.Name,
    pe.chunk,
    vector_distance('cosine', @search_vector, pe.embeddings) AS distance
FROM [SalesLT].[ProductEmbeddings] pe
JOIN [SalesLT].[Product] p ON pe.ProductID = p.ProductID
ORDER BY distance;
GO

----------------------------------------------------------------------------------------


-- Step 6: Create a Vector Index - Uses Approximate Nearest Neighbors or ANN------------
-- Enable Preview Feature
ALTER DATABASE SCOPED CONFIGURATION
SET PREVIEW_FEATURES = ON;
GO

SELECT * FROM sys.database_scoped_configurations
WHERE [name] = 'PREVIEW_FEATURES'
GO

-- Create a vector index
CREATE VECTOR INDEX vec_idx ON [SalesLT].[ProductEmbeddings]([embeddings])
WITH (
    metric = 'cosine',
    type = 'diskann',
    maxdop = 8
);
GO

-- Verify the vector index
SELECT * 
FROM sys.indexes 
WHERE type = 8;
GO

-- ANN Search and then applies the predicate specified in the WHERE clause.
DECLARE @search_text NVARCHAR(MAX) = 'Do you sell any padded seats that are good on trails?';
DECLARE @search_vector VECTOR(768) = AI_GENERATE_EMBEDDINGS(@search_text USE MODEL ollama);

SELECT
    t.ProductID,
    t.chunk,
    s.distance,
    p.ListPrice
FROM vector_search(
    table = [SalesLT].[ProductEmbeddings] AS t,
    column = [embeddings],
    similar_to = @search_vector,
    metric = 'cosine',
    top_n = 10
) AS s
JOIN [SalesLT].[Product] p ON t.ProductID = p.ProductID
WHERE p.ListPrice < 40
ORDER BY s.distance;
GO
----------------------------------------------------------------------------------------


