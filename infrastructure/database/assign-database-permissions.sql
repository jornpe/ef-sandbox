CREATE USER [$(appService)] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [$(appService)];
ALTER ROLE db_datawriter ADD MEMBER [$(appService)];
GO