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
    LOCATION = 'https://model-web:443/api/embed',
    API_FORMAT = 'Ollama',
    MODEL_TYPE = EMBEDDINGS,
    MODEL = 'nomic-embed-text'
);
GO

PRINT 'Testing the external model by calling get_embeddings function...';
GO
BEGIN
    DECLARE @result NVARCHAR(MAX);
    SET @result = (SELECT CONVERT(NVARCHAR(MAX), AI_GENERATE_EMBEDDINGS(N'test text' MODEL ollama)))
    SELECT AI_GENERATE_EMBEDDINGS(N'test text' MODEL ollama) 

    IF @result IS NOT NULL
        PRINT 'Model test successful. Result: ' + @result;
    ELSE
        PRINT 'Model test failed. No result returned.';
END;
GO