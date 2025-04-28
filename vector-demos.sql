USE [master];
GO
RESTORE DATABASE [AdventureWorks2025]
FROM DISK = '/var/opt/mssql/data/AdventureWorksLT2025.bak'
WITH
    MOVE 'AdventureWorksLT2022_Data' TO '/var/opt/mssql/data/AdventureWorks2025_Data.mdf',
    MOVE 'AdventureWorksLT2022_Log' TO '/var/opt/mssql/data/AdventureWorks2025_log.ldf',
    FILE = 1,
    NOUNLOAD,
    STATS = 5;
GO


USE [AdventureWorks2025];
GO

CREATE EXTERNAL MODEL ollama
WITH (
    LOCATION = 'https://model-web:443/api/embeddings',
    MODEL_PROVIDER = 'Ollama',
    MODEL_TYPE = EMBEDDINGS,
    MODEL = 'nomic-embed-text'
);
GO

-- Example: Altering a Table to Add Vector Embeddings Column
ALTER TABLE [SalesLT].[Product]
ADD embeddings VECTOR(768), chunk NVARCHAR(2000);
GO

SELECT * FROM SalesLT.Product WHERE embeddings IS NULL;


-- CREATE THE EMBEDDINGS
SET NOCOUNT ON;
DROP TABLE IF EXISTS #MYTEMP;
DECLARE @ProductID INT;
DECLARE @text NVARCHAR(MAX);

-- Create a temporary table with products that have NULL embeddings
SELECT * 
INTO #MYTEMP 
FROM [SalesLT].[Product] 
WHERE embeddings IS NULL;

-- Loop through all rows in the temporary table
WHILE EXISTS (SELECT 1 FROM #MYTEMP)
BEGIN
    -- Get the next ProductID from the temporary table
    SELECT TOP(1) @ProductID = ProductID 
    FROM #MYTEMP;

    -- Generate the text for embeddings
    SET @text = (
        SELECT p.Name + ' ' + ISNULL(p.Color, 'No Color') + ' ' + c.Name + ' ' + m.Name + ' ' + ISNULL(d.Description, '')
        FROM [SalesLT].[ProductCategory] c,
             [SalesLT].[ProductModel] m,
             [SalesLT].[Product] p
        LEFT OUTER JOIN [SalesLT].[vProductAndDescription] d
        ON p.ProductID = d.ProductID AND d.Culture = 'en'
        WHERE p.ProductCategoryID = c.ProductCategoryID AND p.ProductModelID = m.ProductModelID AND p.ProductID = @ProductID
    );

    -- Update the embeddings and chunk columns in the main table
    UPDATE [SalesLT].[Product]
    SET [embeddings] = get_embeddings(ollama, @text), 
        [chunk] = @text
    WHERE ProductID = @ProductID;

    -- Remove the processed row from the temporary table
    DELETE FROM #MYTEMP 
    WHERE ProductID = @ProductID;

    PRINT 'Processed ProductID: ' + CAST(@ProductID AS NVARCHAR(10)) + ' with text: ' + @text;
END;

USE  AdventureWorks2025;
GO

-- you cannot read the vector datatype in the vs code extension
SELECT TOP 10 name, embeddings from SalesLT.Product

SELECT ProductID, Name, Color from SalesLT.Product
WHERE embeddings IS NOT NULL



/*
    VECTOR_DISTANCE
    
    Uses K-Nearest Neighbors or KNN
    Use the following SQL to run similarity searches using VECTOR_DISTANCE.
*/
USE AdventureWorks2025;
GO

DECLARE @search_text NVARCHAR(MAX) = 'I am looking for a red bike and I dont want to spend a lot';
DECLARE @search_vector VECTOR(768) = get_embeddings(ollama, @search_text);

SELECT TOP(4)
    p.ProductID,
    p.Name,
    p.chunk,
    vector_distance('cosine', @search_vector, p.embeddings) AS distance
FROM [SalesLT].[Product] p
ORDER BY distance;

DECLARE @search_text NVARCHAR(MAX) = 'I am looking for a safe helmet that does not weigh much';
DECLARE @search_vector VECTOR(768) = get_embeddings(ollama, @search_text);

SELECT TOP(4)
    p.ProductID,
    p.Name,
    p.chunk,
    vector_distance('cosine', @search_vector, p.embeddings) AS distance
FROM [SalesLT].[Product] p
ORDER BY distance;

DECLARE @search_text NVARCHAR(MAX) = 'Do you sell any padded seats that are good on trails?';
DECLARE @search_vector VECTOR(768) = get_embeddings(ollama, @search_text);

SELECT TOP(4)
    p.ProductID,
    p.Name,
    p.chunk,
    vector_distance('cosine', @search_vector, p.embeddings) AS distance
FROM [SalesLT].[Product] p
ORDER BY distance;


/*
    VECTOR_SEARCH
    Uses Approximate Nearest Neighbors or ANN
*/

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


-- Verify the vector index
SELECT * 
FROM sys.indexes 
WHERE type = 8;
GO

-- ANN Search
DECLARE @search_text NVARCHAR(MAX) = 'Do you sell any padded seats that are good on trails?';
DECLARE @search_vector VECTOR(768) = get_embeddings(ollama, @search_text);

SELECT
    t.chunk,
    s.distance
FROM vector_search(
    table = [SalesLT].[Product] AS t,
    column = [embeddings],
    similar_to = @search_vector,
    metric = 'cosine',
    top_n = 10
) AS s
ORDER BY s.distance;
GO



/*
    CHUNKING WITH EMBEDDINGS
*/

-- Create a table to store text chunks
CREATE TABLE textchunk (
    text_id INT IDENTITY(1,1) PRIMARY KEY,
    text_to_chunk NVARCHAR(MAX)
);
GO

-- Insert sample text into the textchunk table
INSERT INTO textchunk (text_to_chunk)
VALUES
    ('All day long we seemed to dawdle through a country which was full of beauty of every kind. Sometimes we saw little towns or castles on the top of steep hills such as we see in old missals; sometimes we ran by rivers and streams which seemed from the wide stony margin on each side of them to be subject to great floods.'),
    ('My Friend, Welcome to the Carpathians. I am anxiously expecting you. Sleep well to-night. At three to-morrow the diligence will start for Bukovina; a place on it is kept for you. At the Borgo Pass my carriage will await you and will bring you to me. I trust that your journey from London has been a happy one, and that you will enjoy your stay in my beautiful land. Your friend, DRACULA');
GO

-- Generate embeddings for text chunks
SELECT 
    c.*, 
    get_embeddings(model_name, c.chunk)
FROM textchunk t
CROSS APPLY GET_CHUNKS(
    source = text_to_chunk, 
    chunk_type = N'FIXED', 
    chunk_size = 50, 
    overlap = 10
) c;
GO

-- Create an event session to monitor external REST endpoint usage
CREATE EVENT SESSION [rest] ON SERVER
ADD EVENT sqlserver.external_rest_endpoint_summary,
ADD EVENT sqlserver.get_embeddings_summary
WITH (
    MAX_MEMORY = 4096 KB,
    EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS,
    MAX_DISPATCH_LATENCY = 30 SECONDS,
    MAX_EVENT_SIZE = 0 KB,
    MEMORY_PARTITION_MODE = NONE,
    TRACK_CAUSALITY = OFF,
    STARTUP_STATE = OFF
);
GO