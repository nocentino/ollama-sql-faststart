-- Turn External REST Endpoint Invocation ON in the database
PRINT 'Enabling external REST endpoint invocation...'
GO
sp_configure 'external rest endpoint enabled', 1
GO
RECONFIGURE WITH OVERRIDE;
GO


DROP EXTERNAL MODEL ollama
GO

PRINT 'Creating External model "ollama"...';
GO
CREATE EXTERNAL MODEL ollama
WITH (
    LOCATION = 'https://model-web:443/api/embeddings',
    MODEL_PROVIDER = 'Ollama',
    MODEL_TYPE = EMBEDDINGS,
    MODEL = 'nomic-embed-text'
);
GO

PRINT 'Testing the external model by calling get_embeddings function...';
GO
BEGIN
    DECLARE @result NVARCHAR(MAX);
    SET @result = (SELECT CONVERT(NVARCHAR(MAX), get_embeddings(ollama, N'test text')));

    IF @result IS NOT NULL
        PRINT 'Model test successful. Result: ' + @result;
    ELSE
        PRINT 'Model test failed. No result returned.';
END;
GO