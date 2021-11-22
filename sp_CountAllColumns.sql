SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Tim Newport
-- Create date: 11/22/2021
-- Description:	This will return the number of columns for all tables and views in every database for the server it is executed on. 
-- =============================================
CREATE PROCEDURE sp_CountAllColumns
	-- Add the parameters for the stored procedure here
	 @SearchDb nvarchar(200) ='%'
	,@SearchSchema nvarchar(200) ='%'
    ,@SearchTable nvarchar(200) = '%record%'
    ,@CustomFilter nvarchar(500) = ' AND t.name NOT LIKE ''%[0-9]%'' AND t.name NOT LIKE ''%old%'' AND t.name NOT LIKE ''%deprecate%'' '
AS
BEGIN
SET NOCOUNT ON 

DECLARE @AllTables table (DbName sysname,SchemaName sysname, TableName sysname,LastUpdated datetime,NumColumns int, SysType char(1) ) 
DECLARE @SQL nvarchar(4000) 
       ,@SQL2 nvarchar(4000) 
    SET @SQL='select ''?'' as DbName, s.name as SchemaName, t.name as TableName, t.modify_date as LastUpdated ,t.max_column_id_used as NumColumns,''T'' as SysType
              from [?].sys.tables t inner join 
              [?].sys.schemas s on t.schema_id=s.schema_id 
              WHERE ''?'' LIKE '''+@SearchDb+''' AND s.name LIKE '''+@SearchSchema+''' AND t.name LIKE '''+@SearchTable+''' ' + @CustomFilter   

INSERT INTO @AllTables (DbName, SchemaName, TableName,LastUpdated,NumColumns,SysType)   
EXEC sp_msforeachdb @SQL  SET NOCOUNT OFF 

SET @SQL2='select ''?'' as DbName, s.name as SchemaName, t.name as TableName, t.modify_date as LastUpdated , 0  as NumColumns,''V'' as SysType
           from [?].sys.views t inner join 
           [?].sys.schemas s on t.schema_id=s.schema_id 
           WHERE ''?'' LIKE '''+@SearchDb+''' AND s.name LIKE '''+@SearchSchema+''' AND t.name LIKE '''+@SearchTable +''' ' + @CustomFilter   

INSERT INTO @AllTables (DbName, SchemaName, TableName,LastUpdated,NumColumns,SysType)   

EXEC sp_msforeachdb @SQL2  SET NOCOUNT OFF 

UPDATE @AllTables 
SET NumColumns = (Select TOP 1 count(*) From  sys.dm_exec_describe_first_result_set(N'Select * from ' + DbName + '.' + SchemaName + '.' + TableName ,null,null)) 
WHERE numColumns = 0 

SELECT * FROM @AllTables ORDER BY numColumns desc,DbName,SysType, SchemaName, TableName
END
GO