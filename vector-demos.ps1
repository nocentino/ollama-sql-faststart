# Import the dbatools module
Import-Module dbatools


# Create a PSCredential object with a username and password
$Username = "sa"
$Password = ConvertTo-SecureString "S0methingS@Str0ng!" -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential($Username, $Password)


# Define the SQL Server instance and database
$Database = "AdventureWorks2025"
$SqlInstance = Connect-DbaInstance -SqlInstance 'localhost' -SqlCredential $Credential -Database $Database -TrustServerCertificate


# Example usage with Invoke-DbaQuery
# Define the query to execute
$query = @"
SELECT TOP 10 chunk, embeddings 
FROM SalesLT.Product;
"@
Invoke-DbaQuery -SqlInstance $SqlInstance  -Query $query 



