-- Turn External REST Endpoint Invocation ON in the database
PRINT 'Enabling external REST endpoint invocation...'
GO
sp_configure 'external rest endpoint enabled', 1
GO
RECONFIGURE WITH OVERRIDE;
GO

