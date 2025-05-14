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



USE [AdventureWorks2025];
GO

-- Step 2: Altering a Table to Add Vector Embeddings Column ----------------------------
ALTER TABLE [SalesLT].[Product]
ADD embeddings VECTOR(768), chunk NVARCHAR(2000);
GO
----------------------------------------------------------------------------------------


-- Step 3: CREATE THE EMBEDDINGS
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
    SET [embeddings] = AI_GENERATE_EMBEDDINGS(@text MODEL ollama),
        [chunk] = @text
    WHERE ProductID = @ProductID;

    -- Remove the processed row from the temporary table
    DELETE FROM #MYTEMP 
    WHERE ProductID = @ProductID;

    PRINT 'Processed ProductID: ' + CAST(@ProductID AS NVARCHAR(10)) + ' with text: ' + @text;
END;
----------------------------------------------------------------------------------------


-- Step 4: Perform Vector Search -------------------------------------------------------
DECLARE @search_text NVARCHAR(MAX) = 'I am looking for a red bike and I dont want to spend a lot';
DECLARE @search_vector VECTOR(768) = AI_GENERATE_EMBEDDINGS(@search_text MODEL ollama);

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
DECLARE @search_vector VECTOR(768) = AI_GENERATE_EMBEDDINGS(@search_text MODEL ollama);

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
DECLARE @search_vector VECTOR(768) = AI_GENERATE_EMBEDDINGS(@search_text MODEL ollama);

SELECT TOP(4)
    p.ProductID,
    p.Name,
    p.chunk,
    vector_distance('cosine', @search_vector, p.embeddings) AS distance
FROM [SalesLT].[Product] p
ORDER BY distance;
GO

----------------------------------------------------------------------------------------

-- Step 5: Create a Vector Index - Uses Approximate Nearest Neighbors or ANN------------
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
DECLARE @search_vector VECTOR(768) = AI_GENERATE_EMBEDDINGS(@search_text MODEL ollama);

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
----------------------------------------------------------------------------------------


