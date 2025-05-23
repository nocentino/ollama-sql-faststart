-- Step 1: Restore the AdventureWorks2025 database from a backup file -------------------
USE [master]; 
GO
RESTORE DATABASE [AdventureWorks2025]
FROM DISK = '/var/opt/mssql/backups/AdventureWorks2025_FULL.bak'
WITH
    MOVE 'AdventureWorksLT2022_Data' TO '/var/opt/mssql/data/AdventureWorks2025_Data.mdf',
    MOVE 'AdventureWorksLT2022_Log' TO '/var/opt/mssql/data/AdventureWorks2025_log.ldf',
    FILE = 1,
    NOUNLOAD,
    STATS = 5;
GO

----------------------------------------------------------------------------------------

-- Step 2: Create and test an External Model pointing to our local Ollama Container ----
USE [AdventureWorks2025]
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


-- Step 3: Altering a Table to Add Vector Embeddings Column ----------------------------
USE [AdventureWorks2025];
GO

ALTER TABLE [SalesLT].[Product]
ADD embeddings VECTOR(768), 
    chunk NVARCHAR(2000);
GO
----------------------------------------------------------------------------------------


-- Step 4: CREATE THE EMBEDDINGS (This demo is based off the MS SQL 2025 demo repository)
UPDATE p
SET 
 [chunk] = p.Name + ' ' + ISNULL(p.Color, 'No Color') + ' ' + c.Name + ' ' + m.Name + ' ' + ISNULL(d.Description, ''),
 [embeddings] = AI_GENERATE_EMBEDDINGS(p.Name + ' ' + ISNULL(p.Color, 'No Color') + ' ' + c.Name + ' ' + m.Name + ' ' + ISNULL(d.Description, '') USE MODEL ollama)
FROM [SalesLT].[Product] p
JOIN [SalesLT].[ProductCategory] c ON p.ProductCategoryID = c.ProductCategoryID
JOIN [SalesLT].[ProductModel] m ON p.ProductModelID = m.ProductModelID
LEFT JOIN [SalesLT].[vProductAndDescription] d ON p.ProductID = d.ProductID AND d.Culture = 'en'
WHERE p.embeddings IS NULL;

-- Review the created embeddings
SELECT TOP 10 chunk, embeddings, * 
FROM [SalesLT].[Product] p
----------------------------------------------------------------------------------------


-- Step 5: Perform Vector Search -------------------------------------------------------
DECLARE @search_text NVARCHAR(MAX) = 'I am looking for a red bike and I dont want to spend a lot';
DECLARE @search_vector VECTOR(768) = AI_GENERATE_EMBEDDINGS(@search_text USE MODEL ollama);

SELECT TOP(4)
    p.ProductID,
    p.Name,
    p.chunk,
    vector_distance('cosine', @search_vector, p.embeddings) AS distance
FROM [SalesLT].[Product] p
ORDER BY distance;
GO

----------------------------------------------------------------------------------------

DECLARE @search_text NVARCHAR(MAX) = 'I am looking for a safe helmet that does not weigh much';
DECLARE @search_vector VECTOR(768) = AI_GENERATE_EMBEDDINGS(@search_text USE MODEL ollama);

SELECT TOP(4)
    p.ProductID,
    p.Name,
    p.chunk,
    vector_distance('cosine', @search_vector, p.embeddings) AS distance
FROM [SalesLT].[Product] p
ORDER BY distance;
GO

----------------------------------------------------------------------------------------

DECLARE @search_text NVARCHAR(MAX) = 'Do you sell any padded seats that are good on trails?';
DECLARE @search_vector VECTOR(768) = AI_GENERATE_EMBEDDINGS(@search_text USE MODEL ollama);

SELECT TOP(4)
    p.ProductID,
    p.Name,
    p.chunk,
    vector_distance('cosine', @search_vector, p.embeddings) AS distance
FROM [SalesLT].[Product] p
ORDER BY distance;
GO

----------------------------------------------------------------------------------------


-- Step 6: Create a Vector Index - Uses Approximate Nearest Neighbors or ANN------------
-- Enable trace flags for vector features
DBCC TRACEON (466, 474, 13981, -1);
GO

-- Check trace flags status
DBCC TRACESTATUS;
GO


-- Create a vector index
CREATE VECTOR INDEX vec_idx ON [SalesLT].[Product]([embeddings])
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
    t.ListPrice
FROM vector_search(
    table = [SalesLT].[Product] AS t,
    column = [embeddings],
    similar_to = @search_vector,
    metric = 'cosine',
    top_n = 10
) AS s
WHERE ListPrice < 40
ORDER BY s.distance;
GO
----------------------------------------------------------------------------------------


