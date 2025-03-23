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
    LOCATION = 'https://model.example.com:443/api/embeddings',
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

    PRINT 'Processed ProductID: ' + CAST(@ProductID AS NVARCHAR(10));
END;

use  AdventureWorks2025;
GO

select * from SalesLT.Product where embeddings is null;
select top 10 chunk, embeddings from SalesLT.Product