# Import the dbatools module
Import-Module dbatools


# Create a PSCredential object with a username and password
$Username = "sa"
$Password = ConvertTo-SecureString "S0methingS@Str0ng!" -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential($Username, $Password)


# Define the SQL Server instance and database
$Database = "AdventureWorks2025"
$SqlInstance = Connect-DbaInstance -SqlInstance 'localhost' -SqlCredential $Credential -TrustServerCertificate


# Example usage with Invoke-DbaQuery
# Define the query to execute
$query = @"
SELECT TOP 10 chunk, embeddings 
FROM SalesLT.Product;
"@
Invoke-DbaQuery -SqlInstance $SqlInstance  -Query $query 



# Example usage with Invoke-DbaQuery
# Define the query to execute
$query = @"
--CREATE DATABASE [TestDB];
GO
--CREATE TABLE [TestDB].[dbo].[TestTable1] (ID INT, Name VECTOR(3));
INSERT INTO [TestDB].[dbo].[TestTable1] VALUES (1, '[1,2,3]');
"@
Invoke-DbaQuery -SqlInstance $SqlInstance  -Query $query 

$query = @"
SELECT * FROM [TestDB].[dbo].[TestTable1];
"@
Invoke-DbaQuery -SqlInstance $SqlInstance  -Query $query -Database "TestDB"
