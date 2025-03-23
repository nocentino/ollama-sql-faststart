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

ALTER TABLE [SalesLT].[Product]
ADD embeddings VECTOR(768), 
    chunk NVARCHAR(2000);
GO


SELECT * FROM SalesLT.Product WHERE embeddings IS NULL;

CREATE EXTERNAL MODEL ollama
WITH (
    LOCATION = 'https://model.example.com:443/api/embeddings',
    MODEL_PROVIDER = 'Ollama',
    MODEL_TYPE = EMBEDDINGS,
    MODEL = 'nomic-embed-text'
);
GO

-- create the embeddings
SET NOCOUNT ON
DROP TABLE IF EXISTS #MYTEMP
DECLARE @ProductID int
declare @text nvarchar(max);
SELECT * INTO #MYTEMP FROM [SalesLT].Product where embeddings is null;
SELECT @ProductID = ProductID FROM #MYTEMP;
SELECT TOP(1) @ProductID = ProductID FROM #MYTEMP
WHILE @@ROWCOUNT <> 0
BEGIN
set @text = (SELECT p.Name + ' '+ ISNULL(p.Color,'No Color') + ' '+
c.Name + ' '+ m.Name + ' '+ ISNULL(d.Description,'')
FROM
[SalesLT].[ProductCategory] c,
[SalesLT].[ProductModel] m,
[SalesLT].[Product] p
LEFT OUTER JOIN
[SalesLT].[vProductAndDescription] d
on p.ProductID = d.ProductID
and d.Culture = 'en'
where p.ProductCategoryID = c.ProductCategoryID
and p.ProductModelID = m.ProductModelID
and p.ProductID = @ProductID);
update [SalesLT].[Product] set [embeddings] = get_embeddings(ollama,
@text) , [chunk] = @text where ProductID = @ProductID;
DELETE FROM #MYTEMP WHERE ProductID = @ProductID
SELECT TOP(1) @ProductID = ProductID FROM #MYTEMP
END