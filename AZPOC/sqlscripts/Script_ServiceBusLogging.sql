IF ( DB_ID( N'Azure POC_ServiceBusLogging' ) IS NULL )
	CREATE DATABASE [Azure POC_ServiceBusLogging]

GO

USE [Azure POC_ServiceBusLogging]

GO

IF SCHEMA_ID('DataFix') is null
	EXECUTE('CREATE SCHEMA DataFix')
GO

--
-- Data Fix Script Execution Log Table
--
IF OBJECT_ID (N'[DataFix].[Log]', N'U') IS NULL
	BEGIN
	--
	-- The table does not exist so create it using the final version
	--
	CREATE TABLE [DataFix].[Log]
	(
	[TrackingID] [uniqueidentifier] NOT NULL,
	[Section] [int] NOT NULL,
	[Completed] [datetime] NOT NULL,
	[Comment] [nvarchar](255) NULL,
	)

	END
/*
ELSE
BEGIN
	--
	-- A version of the table exists so the current version must be determined and alterations made
	--
END
*/

GO

--
-- Data Fix Script Execution Tracking Table
--
IF OBJECT_ID (N'[DataFix].[Tracking]', N'U') IS NULL
	BEGIN
	--
	-- The table does not exist so create it using the final version
	--
	CREATE TABLE [DataFix].[Tracking]
	(
	[TrackingID] [uniqueidentifier] NOT NULL,
	[ReferenceID] [nchar](10) NOT NULL,
	[Author] [nvarchar](50) NOT NULL,
	)

	END
/*
ELSE
BEGIN
	--
	-- A version of the table exists so the current version must be determined and alterations made
	--
END
*/

GO

IF OBJECT_ID( N'[dbo].[LogEntry]', N'U' ) IS NULL
	CREATE TABLE [dbo].[LogEntry]
	(
		[LogEntryID] [int] IDENTITY(1,1) NOT NULL,
		[MachineName] [varchar](64) NOT NULL,
		[Context] [varchar](240) NOT NULL,
		[Date] [datetime] NOT NULL,
		[Level] [varchar](50) NOT NULL,
		[Message] [varchar](300) NOT NULL,
		[Stack] [image] NULL,
		[Exception] [image] NULL,
		[ExceptionText] [text] NULL
	)
--ELSE
--BEGIN	
--END
GO

IF OBJECT_ID( N'[dbo].[LogEntryAttribute]', N'U' ) IS NULL
	CREATE TABLE [dbo].[LogEntryAttribute]
	(
		[LogEntryID] [int] NOT NULL,
		[AttributeNameID] [int] NOT NULL,
		[Value] [varchar](250) NOT NULL,
		[Date] [datetime] NULL 
	)
--ELSE
--BEGIN	
--END
GO

IF OBJECT_ID( N'[dbo].[LogEntryAttributeName]', N'U' ) IS NULL	
	CREATE TABLE [dbo].[LogEntryAttributeName]
	(
		[AttributeNameID] [int] IDENTITY(1,1) NOT NULL,
		[Name] [varchar](80) NOT NULL
	)
--ELSE
--BEGIN	
--END
GO

IF OBJECT_ID( N'[dbo].[LogEntryContextSummary]', N'U' ) IS NULL
	CREATE TABLE [dbo].[LogEntryContextSummary]
	(
		[Date] [datetime] NOT NULL,
		[Context] [nvarchar](240) NOT NULL,
		[MachineName] [nvarchar](64) NOT NULL,
		[Frequency] [int] NOT NULL
	)
--ELSE
--BEGIN	
--END
GO

IF OBJECT_ID( N'[dbo].[LoggingUserDefinedIntParameters]', N'U' ) IS NULL
	CREATE TABLE [dbo].[LoggingUserDefinedIntParameters]
	(
		[RowID] [int] IDENTITY(1,1) NOT NULL,
		[ParamName] [varchar](250) NOT NULL,
		[ParamValue] [int] NOT NULL
	)
--ELSE
--BEGIN	
--END
GO

--
-- Data Fix Script Execution Log Table's Primary Key
--
IF OBJECT_ID (N'[DataFix].[PK_DataFix_Log]', N'PK') IS NULL
	BEGIN
	--
	-- The index does not exist so create it using the final version
	--
	ALTER TABLE [DataFix].[Log] ADD CONSTRAINT [PK_DataFix_Log] PRIMARY KEY CLUSTERED
	(
	[TrackingID],
	[Section]
	)

	END
/*
ELSE
	BEGIN
	--
	-- A version of the index exists so the current version must be determined and alterations made
	--

	END
*/

GO

--
-- Data Fix Script Execution Tracking Table's Primary Key
--
IF OBJECT_ID (N'[DataFix].[PK_DataFix_Tracking]', N'PK') IS NULL
	BEGIN
	--
	-- The index does not exist so create it using the final version
	--
	ALTER TABLE [DataFix].[Tracking] ADD CONSTRAINT [PK_DataFix_Tracking] PRIMARY KEY CLUSTERED
	(
	[TrackingID]
	)

	END
/*
ELSE
	BEGIN
	--
	-- A version of the index exists so the current version must be determined and alterations made
	--

	END
*/

GO

IF OBJECT_ID( N'[dbo].[PK_LogEntry]', N'PK' ) IS NULL
BEGIN
	ALTER TABLE [dbo].[LogEntry] 
		ADD CONSTRAINT [PK_LogEntry] PRIMARY KEY CLUSTERED ( [LogEntryID] ASC )
END
GO

IF OBJECT_ID( N'[dbo].[PK_LogEntryAttribute]', N'PK' ) IS NULL
BEGIN
	ALTER TABLE [dbo].[LogEntryAttribute] 
		ADD CONSTRAINT [PK_LogEntryAttribute] 
		PRIMARY KEY CLUSTERED 
		(
			[LogEntryID] ASC,
			[AttributeNameID] ASC,
			[Value] ASC
		)
END
GO

IF OBJECT_ID( N'[dbo].[PK_LogEntryAttributeName]', N'PK' ) IS NULL
BEGIN
	ALTER TABLE [dbo].[LogEntryAttributeName] 
		ADD CONSTRAINT [PK_LogEntryAttributeName] 
		PRIMARY KEY CLUSTERED ( [AttributeNameID] ASC )
END
GO

IF OBJECT_ID( N'[dbo].[PK_LogEntryContextSummary]', N'PK' ) IS NULL
BEGIN
	ALTER TABLE [dbo].[LogEntryContextSummary] 
		ADD CONSTRAINT [PK_LogEntryContextSummary] 
		PRIMARY KEY CLUSTERED 
		(
			[Date] ASC,
			[Context] ASC,
			[MachineName] ASC
		)
END
GO

--
-- Data Fix Script Execution Log Table's Constraint Against the Tracking Table
--
IF OBJECT_ID (N'[DataFix].[FK_DataFix_Log_Tracking]', N'F') IS NULL
	BEGIN
	--
	-- The index does not exist so create it using the final version
	--
	ALTER TABLE [DataFix].[Log] WITH CHECK ADD CONSTRAINT [FK_DataFix_Log_Tracking] FOREIGN KEY
	(
	[TrackingID]
	)
	REFERENCES [DataFix].[Tracking]
	(
	[TrackingID]
	)

	ALTER TABLE [DataFix].[Log] CHECK CONSTRAINT [FK_DataFix_Log_Tracking]

	END
/*
ELSE
	BEGIN
	--
	-- A version of the index exists so the current version must be determined and alterations made
	--

	END
*/

GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[LogEntry]') AND name = N'IX_LogEntry_DateA')
BEGIN
    CREATE NONCLUSTERED INDEX [IX_LogEntry_DateA] ON [dbo].[LogEntry] 
	(
		[Date] ASC,
		[Level] ASC,
		[LogEntryID] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[LogEntry]') AND name = N'IX_LogEntry_DateD')
BEGIN
    CREATE NONCLUSTERED INDEX [IX_LogEntry_DateD] ON [dbo].[LogEntry] 
	(
		[Date] DESC,
		[LogEntryID] DESC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[LogEntry]') AND name = N'IX_LogEntry_Level')
BEGIN
    CREATE NONCLUSTERED INDEX [IX_LogEntry_Level] ON [dbo].[LogEntry] 
	(
		[Level] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[LogEntry]') AND name = N'IX_LogEntry_MachineContext')
BEGIN
    CREATE NONCLUSTERED INDEX [IX_LogEntry_MachineContext] ON [dbo].[LogEntry] 
	(
		[MachineName] ASC,
		[Context] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)

END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[LogEntry]') AND name = N'IX_LogEntry_Message')
BEGIN
    CREATE NONCLUSTERED INDEX [IX_LogEntry_Message] ON [dbo].[LogEntry] 
	(
		[Message] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[LogEntryAttribute]') AND name = N'IX_LogEntryAttribute_IdNameValue')
BEGIN
    CREATE NONCLUSTERED INDEX [IX_LogEntryAttribute_IdNameValue] ON [dbo].[LogEntryAttribute]
    (
		[LogEntryId]
	) 
    INCLUDE 
    ( 
		[AttributeNameID], 
		[Value] 
	)
	WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80)
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[LogEntryAttribute]') AND name = N'IX_LogEntryAttribute_NameValue')
BEGIN
    CREATE NONCLUSTERED INDEX [IX_LogEntryAttribute_NameValue] ON [dbo].[LogEntryAttribute] 
	(
		[AttributeNameID] ASC,
		[Value] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80)
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[LogEntryAttributeName]') AND name = N'IX_LogEntryAttributeName_Name')
BEGIN
    CREATE NONCLUSTERED INDEX [IX_LogEntryAttributeName_Name] ON [dbo].[LogEntryAttributeName] 
	(
		[Name] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80)
END
GO

DECLARE @ParamValue int
SELECT	@ParamValue = ParamValue
  FROM	[dbo].[LoggingUserDefinedIntParameters] WITH ( NOLOCK )
 WHERE	[ParamName] = 'ContextSummaryLastID'
	
	IF	@ParamValue IS NULL
		BEGIN	
			INSERT INTO [dbo].[LoggingUserDefinedIntParameters]
						([ParamName]
						,[ParamValue])
			VALUES
						('ContextSummaryLastID'
						,0)
        END
GO
GO

--
-- Return the section's state; one if completed and zero if not completed.
--

IF OBJECT_ID (N'[DataFix].[SectionState]', N'FN') IS NOT NULL
	BEGIN
	--
	-- Drop the function because we are going to create it again
	--
	DROP FUNCTION [DataFix].[SectionState]

	END
GO

CREATE FUNCTION [DataFix].[SectionState]
(
	@TrackingID uniqueidentifier,
	@Section int
)	RETURNS bit
AS
BEGIN
	DECLARE @SectionCompleted bit, @SectionNotRun bit
	SET @SectionCompleted = 1
	SET @SectionNotRun = 0

	DECLARE @SectionState bit
	SET @SectionState = @SectionCompleted
	
	IF EXISTS(SELECT * FROM DataFix.Tracking WHERE TrackingID = @TrackingID)
		IF NOT EXISTS(SELECT * FROM DataFix.Log WHERE TrackingID = @TrackingID AND Section = @Section)
			SET @SectionState = @SectionNotRun

	RETURN @SectionState
END

GO

IF TYPE_ID( N'[dbo].[LogEntryAttribute]') IS NULL
BEGIN
	CREATE TYPE [dbo].[LogEntryAttribute] AS TABLE
	(
		 [Name] [nvarchar](80) NULL,
		 [Value] [nvarchar](250) NULL
	)
END
GO

--
-- Insert an entry into the data fix tracking table
--

IF OBJECT_ID (N'[DataFix].[Initialize]', N'P') IS NOT NULL
	BEGIN
	--
	-- Drop the procedure because we are going to create it again
	--
	DROP PROCEDURE [DataFix].[Initialize]

	END
GO

CREATE PROCEDURE [DataFix].[Initialize]
(
	@TrackingID uniqueidentifier,
	@ReferenceID nchar(10),
	@Author nvarchar(50)
)
AS
BEGIN
	IF NOT EXISTS(SELECT * FROM DataFix.Tracking WHERE TrackingID = @TrackingID)
		INSERT INTO DataFix.Tracking
		(
			TrackingID,
			ReferenceID,
			Author
		)
		VALUES
		(
			@TrackingID,
			@ReferenceID,
			@Author
		)
END;

GO

--
-- Insert an entry into the data fix log table to indicate that the section has been completed
--

IF OBJECT_ID (N'[DataFix].[SetSectionCompleted]', N'P') IS NOT NULL
	BEGIN
	--
	-- Drop the procedure because we are going to create it again
	--
	DROP PROCEDURE [DataFix].[SetSectionCompleted]

	END
GO

CREATE PROCEDURE [DataFix].[SetSectionCompleted]
(
	@TrackingID uniqueidentifier,
	@Section int,
	@Comment nvarchar(255) = NULL
)
AS
BEGIN
	IF NOT EXISTS(SELECT * FROM DataFix.Log WHERE TrackingID = @TrackingID AND Section = @Section)
		INSERT INTO DataFix.Log
		(
			TrackingID,
			Section,
			Completed,
			Comment
		)
		VALUES
		(
			@TrackingID,
			@Section,
			GETDATE(),
			@Comment
		)
END;

GO

IF OBJECT_ID( N'[dbo].[cpAggregateLogEntryByContextMachine]', N'P' ) IS NOT NULL
	DROP PROCEDURE [dbo].[cpAggregateLogEntryByContextMachine]
GO

CREATE PROCEDURE [dbo].[cpAggregateLogEntryByContextMachine]
as
begin
	SET NOCOUNT ON

	Create table #Temptable
	(
		[Date] [datetime] NOT NULL,
		[Context] [nvarchar](240) NOT NULL,
		[MachineName] [nvarchar](64) NOT NULL,
		Frequency		int NOT NULL
	)

	declare @MinLogEntryID int, @MaxLogEntryID int, @RowsAffected int

	select @MinLogEntryID = ParamValue+1
	from LoggingUserDefinedIntParameters 
	where ParamName = 'ContextSummaryLastID'

	select @MaxLogEntryID = max(LogEntryID), @RowsAffected = count(1)
	from LogEntry with (nolock)
	where LogEntryID >= @MinLogEntryID

	if isnull(@MaxLogEntryID,0) = 0
		return

	print @RowsAffected

	Insert into #Temptable
	select Convert(char(10), Date, 120) as Date, Context, MachineName, count(1) as Frequency
	from LogEntry with (nolock)
	where LogEntryID between @MinLogEntryID and @MaxLogEntryID
	group by Convert(char(10), Date, 120), Context, MachineName

	Update lg
	set	Frequency = lg.Frequency + tbl.Frequency
	from LogEntryContextSummary as lg
		join #Temptable as tbl on tbl.Date = lg.Date and tbl.Context = lg.Context and tbl.MachineName = lg.MachineName

	Insert into LogEntryContextSummary (Date, Context, MachineName, Frequency)
	select Date, Context, MachineName, Frequency
	from #Temptable as tbl
	where not exists (select 1 from LogEntryContextSummary as lg
						where lg.Date = tbl.Date
						and	lg.Context = tbl.Context
						and	lg.MachineName = tbl.MachineName
					)

	update LoggingUserDefinedIntParameters
	set ParamValue = @MaxLogEntryID
	where ParamName = 'ContextSummaryLastID'

end
GO

IF OBJECT_ID( N'[dbo].[InsertLogEntryWithAttributes]', N'P' ) IS NOT NULL
	DROP PROCEDURE [dbo].[InsertLogEntryWithAttributes]
GO

CREATE PROCEDURE [dbo].[InsertLogEntryWithAttributes]
(
	@MachineName nvarchar(64),
	@Context nvarchar(240),
	@Date datetime,
	@Level nvarchar(15),
	@Message nvarchar(300),
	@Stack image = null,
	@Exception image = null,
	@ExceptionText text = null,
	@Attributes  LogEntryAttribute READONLY

)
AS
DECLARE @LogEntryID int
DECLARE @AttributeNameID int
INSERT INTO LogEntry
(
	MachineName,
	Context,
	[Date],
	[Level],
	[Message],
	Stack,
	Exception,
	ExceptionText
)
VALUES
(
	@MachineName,
	@Context,
	@Date,
	@Level,
	@Message,
	@Stack,
	@Exception,
	@ExceptionText
)
	

SET @LogEntryID = @@identity

INSERT INTO LogEntryAttributeName (Name)
SELECT 	A.Name 
FROM @Attributes A
LEFT OUTER JOIN LogEntryAttributeName L ON L.Name=A.Name
WHERE  L.Name IS NULL

INSERT INTO LogEntryAttribute (LogEntryID,AttributeNameID,[Value],[Date])
SELECT @LogEntryID, L.AttributeNameID, A.Value, @Date 
FROM @Attributes A
INNER JOIN LogEntryAttributeName L ON L.Name=A.Name

return @LogEntryID
GO

IF OBJECT_ID( N'[dbo].[LogEntry_Ins]', N'P' ) IS NOT NULL
	DROP PROCEDURE [dbo].[LogEntry_Ins]
GO

CREATE PROCEDURE [dbo].[LogEntry_Ins]
(
	@MachineName nvarchar(64),
	@Context nvarchar(240),
	@Date datetime,
	@Level nvarchar(15),
	@Message nvarchar(300),
	@Stack image = null,
	@Exception image = null,
	@ExceptionText text = null,
	@Name1 varchar(80) = null,
	@Value1 nvarchar(250) = null,
	@Name2 varchar(80) = null,
	@Value2 nvarchar(250) = null,
	@Name3 varchar(80) = null,
	@Value3 nvarchar(250) = null,
	@Name4 varchar(80) = null,
	@Value4 nvarchar(250) = null,
	@Name5 varchar(80) = null,
	@Value5 nvarchar(250) = null,
	@Name6 varchar(80) = null,
	@Value6 nvarchar(250) = null,
	@Name7 varchar(80) = null,
	@Value7 nvarchar(250) = null,
	@Name8 varchar(80) = null,
	@Value8 nvarchar(250) = null,
	@Name9 varchar(80) = null,
	@Value9 nvarchar(250) = null,
	@Name10 varchar(80) = null,
	@Value10 nvarchar(250) = null

)
as
declare @LogEntryID int
declare @AttributeNameID int
insert into LogEntry
(
	MachineName,
	Context,
	[Date],
	[Level],
	[Message],
	Stack,
	Exception,
	ExceptionText
)
values
(
	@MachineName,
	@Context,
	@Date,
	@Level,
	@Message,
	@Stack,
	@Exception,
	@ExceptionText
)
	

set @LogEntryID = @@identity

if ( @name1 is not null and @value1 is not null)
begin
if not exists (select AttributeNameID from LogEntryAttributeName where [Name] = @Name1)
	insert into LogEntryAttributeName([Name]) values (@Name1)
set @AttributeNameID = (select AttributeNameID	from LogEntryAttributeName where [Name] = @Name1)

insert into LogEntryAttribute(LogEntryID,AttributeNameID,[Value])
values(	@LogEntryID,
		@AttributeNameID,
		@Value1)
end

if ( @name2 is not null and @value2 is not null)
begin
if not exists (select AttributeNameID from LogEntryAttributeName where [Name] = @Name2)
	insert into LogEntryAttributeName([Name]) values (@Name2)
set @AttributeNameID = (select AttributeNameID	from LogEntryAttributeName where [Name] = @Name2)

insert into LogEntryAttribute(LogEntryID,AttributeNameID,[Value])
values(	@LogEntryID,
		@AttributeNameID,
		@Value2)
end

if ( @name3 is not null and @value3 is not null)
begin
if not exists (select AttributeNameID from LogEntryAttributeName where [Name] = @Name3)
	insert into LogEntryAttributeName([Name]) values (@Name3)
set @AttributeNameID = (select AttributeNameID	from LogEntryAttributeName where [Name] = @Name3)

insert into LogEntryAttribute(LogEntryID,AttributeNameID,[Value])
values(	@LogEntryID,
		@AttributeNameID,
		@Value3)
end

if ( @name4 is not null and @value4 is not null)
begin
if not exists (select AttributeNameID from LogEntryAttributeName where [Name] = @Name4)
	insert into LogEntryAttributeName([Name]) values (@Name4)
set @AttributeNameID = (select AttributeNameID	from LogEntryAttributeName where [Name] = @Name4)

insert into LogEntryAttribute(LogEntryID,AttributeNameID,[Value])
values(	@LogEntryID,
		@AttributeNameID,
		@Value4)
end

if ( @name5 is not null and @value5 is not null)
begin
if not exists (select AttributeNameID from LogEntryAttributeName where [Name] = @Name5)
	insert into LogEntryAttributeName([Name]) values (@Name5)
set @AttributeNameID = (select AttributeNameID	from LogEntryAttributeName where [Name] = @Name5)

insert into LogEntryAttribute(LogEntryID,AttributeNameID,[Value])
values(	@LogEntryID,
		@AttributeNameID,
		@Value5)
end

if ( @name6 is not null and @value6 is not null)
begin
if not exists (select AttributeNameID from LogEntryAttributeName where [Name] = @Name6)
	insert into LogEntryAttributeName([Name]) values (@Name6)
set @AttributeNameID = (select AttributeNameID	from LogEntryAttributeName where [Name] = @Name6)

insert into LogEntryAttribute(LogEntryID,AttributeNameID,[Value])
values(	@LogEntryID,
		@AttributeNameID,
		@Value6)
end

if ( @name7 is not null and @value7 is not null)
begin
if not exists (select AttributeNameID from LogEntryAttributeName where [Name] = @Name7)
	insert into LogEntryAttributeName([Name]) values (@Name7)
set @AttributeNameID = (select AttributeNameID	from LogEntryAttributeName where [Name] = @Name7)

insert into LogEntryAttribute(LogEntryID,AttributeNameID,[Value])
values(	@LogEntryID,
		@AttributeNameID,
		@Value7)
end

if ( @name8 is not null and @value8 is not null)
begin
if not exists (select AttributeNameID from LogEntryAttributeName where [Name] = @Name8)
	insert into LogEntryAttributeName([Name]) values (@Name8)
set @AttributeNameID = (select AttributeNameID	from LogEntryAttributeName where [Name] = @Name8)

insert into LogEntryAttribute(LogEntryID,AttributeNameID,[Value])
values(	@LogEntryID,
		@AttributeNameID,
		@Value8)
end

if ( @name9 is not null and @value9 is not null)
begin
if not exists (select AttributeNameID from LogEntryAttributeName where [Name] = @Name9)
	insert into LogEntryAttributeName([Name]) values (@Name9)
set @AttributeNameID = (select AttributeNameID	from LogEntryAttributeName where [Name] = @Name9)

insert into LogEntryAttribute(LogEntryID,AttributeNameID,[Value])
values(	@LogEntryID,
		@AttributeNameID,
		@Value9)
end

if ( @name10 is not null and @value10 is not null)
begin
if not exists (select AttributeNameID from LogEntryAttributeName where [Name] = @Name10)
	insert into LogEntryAttributeName([Name]) values (@Name10)
set @AttributeNameID = (select AttributeNameID	from LogEntryAttributeName where [Name] = @Name10)

insert into LogEntryAttribute(LogEntryID,AttributeNameID,[Value])
values(	@LogEntryID,
		@AttributeNameID,
		@Value10)
end

return @LogEntryID
GO

IF OBJECT_ID( N'[dbo].[LogEntryAttribute_Ins]', N'P' ) IS NOT NULL
	DROP PROCEDURE [dbo].[LogEntryAttribute_Ins]
GO

CREATE PROCEDURE [dbo].[LogEntryAttribute_Ins]
(
	@LogEntryID int,
	@Name1 varchar(80) = null,
	@Value1 nvarchar(250) = null,
	@Name2 varchar(80) = null,
	@Value2 nvarchar(250) = null,
	@Name3 varchar(80) = null,
	@Value3 nvarchar(250) = null,
	@Name4 varchar(80) = null,
	@Value4 nvarchar(250) = null,
	@Name5 varchar(80) = null,
	@Value5 nvarchar(250) = null,
	@Name6 varchar(80) = null,
	@Value6 nvarchar(250) = null,
	@Name7 varchar(80) = null,
	@Value7 nvarchar(250) = null,
	@Name8 varchar(80) = null,
	@Value8 nvarchar(250) = null,
	@Name9 varchar(80) = null,
	@Value9 nvarchar(250) = null,
	@Name10 varchar(80) = null,
	@Value10 nvarchar(250) = null
)
as

declare @AttributeNameID [int]

if ( @Name1 is not null and @Value1 is not null)
begin
if not exists (select AttributeNameID from LogEntryAttributeName where [Name] = @Name1)
	insert into LogEntryAttributeName([Name]) values (@Name1)
set @AttributeNameID = (select AttributeNameID	from LogEntryAttributeName where [Name] = @Name1)

insert into LogEntryAttribute(LogEntryID,AttributeNameID,[Value])
values(	@LogEntryID,@AttributeNameID,@Value1)
end

if ( @Name2 is not null and @Value2 is not null)
begin
if not exists (select AttributeNameID from LogEntryAttributeName where [Name] = @Name2)
	insert into LogEntryAttributeName([Name]) values (@Name2)
set @AttributeNameID = (select AttributeNameID	from LogEntryAttributeName where [Name] = @Name2)

insert into LogEntryAttribute(LogEntryID,AttributeNameID,[Value])
values(	@LogEntryID,@AttributeNameID,@Value2)
end

if ( @Name3 is not null and @Value3 is not null)
begin
if not exists (select AttributeNameID from LogEntryAttributeName where [Name] = @Name3)
	insert into LogEntryAttributeName([Name]) values (@Name3)
set @AttributeNameID = (select AttributeNameID	from LogEntryAttributeName where [Name] = @Name3)

insert into LogEntryAttribute(LogEntryID,AttributeNameID,[Value])
values(	@LogEntryID,@AttributeNameID,@Value3)
end

if ( @Name4 is not null and @Value4 is not null)
begin
if not exists (select AttributeNameID from LogEntryAttributeName where [Name] = @Name4)
	insert into LogEntryAttributeName([Name]) values (@Name4)
set @AttributeNameID = (select AttributeNameID	from LogEntryAttributeName where [Name] = @Name4)

insert into LogEntryAttribute(LogEntryID,AttributeNameID,[Value])
values(	@LogEntryID,@AttributeNameID,@Value4)
end

if ( @Name5 is not null and @Value5 is not null)
begin
if not exists (select AttributeNameID from LogEntryAttributeName where [Name] = @Name5)
	insert into LogEntryAttributeName([Name]) values (@Name5)
set @AttributeNameID = (select AttributeNameID	from LogEntryAttributeName where [Name] = @Name5)

insert into LogEntryAttribute(LogEntryID,AttributeNameID,[Value])
values(	@LogEntryID,@AttributeNameID,@Value5)
end

if ( @Name6 is not null and @Value6 is not null)
begin
if not exists (select AttributeNameID from LogEntryAttributeName where [Name] = @Name6)
	insert into LogEntryAttributeName([Name]) values (@Name6)
set @AttributeNameID = (select AttributeNameID	from LogEntryAttributeName where [Name] = @Name6)

insert into LogEntryAttribute(LogEntryID,AttributeNameID,[Value])
values(	@LogEntryID,@AttributeNameID,@Value6)
end

if ( @Name7 is not null and @Value7 is not null)
begin
if not exists (select AttributeNameID from LogEntryAttributeName where [Name] = @Name7)
	insert into LogEntryAttributeName([Name]) values (@Name7)
set @AttributeNameID = (select AttributeNameID	from LogEntryAttributeName where [Name] = @Name7)

insert into LogEntryAttribute(LogEntryID,AttributeNameID,[Value])
values(	@LogEntryID,@AttributeNameID,@Value7)
end

if ( @Name8 is not null and @Value8 is not null)
begin
if not exists (select AttributeNameID from LogEntryAttributeName where [Name] = @Name8)
	insert into LogEntryAttributeName([Name]) values (@Name8)
set @AttributeNameID = (select AttributeNameID	from LogEntryAttributeName where [Name] = @Name8)

insert into LogEntryAttribute(LogEntryID,AttributeNameID,[Value])
values(	@LogEntryID,@AttributeNameID,@Value8)
end

if ( @Name9 is not null and @Value9 is not null)
begin
if not exists (select AttributeNameID from LogEntryAttributeName where [Name] = @Name9)
	insert into LogEntryAttributeName([Name]) values (@Name9)
set @AttributeNameID = (select AttributeNameID	from LogEntryAttributeName where [Name] = @Name9)

insert into LogEntryAttribute(LogEntryID,AttributeNameID,[Value])
values(	@LogEntryID,@AttributeNameID,@Value9)
end

if ( @Name10 is not null and @Value10 is not null)
begin
if not exists (select AttributeNameID from LogEntryAttributeName where [Name] = @Name10)
	insert into LogEntryAttributeName([Name]) values (@Name10)
set @AttributeNameID = (select AttributeNameID	from LogEntryAttributeName where [Name] = @Name10)

insert into LogEntryAttribute(LogEntryID,AttributeNameID,[Value])
values(	@LogEntryID,@AttributeNameID,@Value10)
end
return
GO

IF OBJECT_ID( N'[dbo].[lvGetContextMachineCounts]', N'P' ) IS NOT NULL
	DROP PROCEDURE [dbo].[lvGetContextMachineCounts]
GO

CREATE PROCEDURE [dbo].[lvGetContextMachineCounts]
as

select Context, MachineName, Sum(Frequency) as 'Count'
from LogEntryContextSummary with (nolock)
group by Context, MachineName
order by Context, MachineName

return
GO

IF OBJECT_ID( N'[dbo].[lvGetMachineContextCounts]', N'P' ) IS NOT NULL
	DROP PROCEDURE [dbo].[lvGetMachineContextCounts]
GO

CREATE PROCEDURE [dbo].[lvGetMachineContextCounts]
as

select Context, count(*) as 'Count'
from LogEntry with (nolock)
group by Context

select MachineName, Context, count(*) as 'Count'
from LogEntry with (nolock)
group by MachineName, Context

return
GO

IF OBJECT_ID( N'[dbo].[lvGetNextPage]', N'P' ) IS NOT NULL
	DROP PROCEDURE [dbo].[lvGetNextPage]
GO

CREATE PROCEDURE [dbo].[lvGetNextPage]
(
	@lastLogEntryTime datetime,
	@lastLogEntryId int,
	@pageSize int
)
as

declare @ids table ( dt datetime, id int )
declare @count int

set rowcount @pageSize

insert into @ids
select
	[Date],
	LogEntryID
from
	LogEntry with (nolock)
where
	[Date] < @lastLogEntryTime
	or (
		[Date] = @lastLogEntryTime
		and LogEntryID < @lastLogEntryId )
order by
	[Date] desc,
	LogEntryID desc
	
set @count = @@ROWCOUNT
if ( @count < @pageSize )
begin

	if ( @count > 0 )
	begin
		set @lastLogEntryTime = (select min(dt) from @ids)
	end
	
	delete @ids
	
	insert into @ids
	select
		[Date],
		LogEntryID
	from
		LogEntry with (nolock)
	where
		[Date] >= @lastLogEntryTime
	order by
		[Date] asc,
		LogEntryID asc
		
end

select
	l.LogEntryID,
	l.MachineName,
	l.Context,
	l.[Date],
	l.[Level],
	l.Message,
	l.ExceptionText
from
	@ids i
	join LogEntry l with (nolock) on
		l.LogEntryID = i.id
order by
	l.[Date] desc,
	l.LogEntryID desc
	
set rowcount 0

select 
	a.LogEntryID,
	n.Name,
	a.Value
from
	@ids i
	join LogEntryAttribute a with (nolock) on
		a.LogEntryID = i.id
	join LogEntryAttributeName n with (nolock) on
		n.AttributeNameID = a.AttributeNameID
order by
	a.LogEntryID desc

return
GO

IF OBJECT_ID( N'[dbo].[lvGetPrevPage]', N'P' ) IS NOT NULL
	DROP PROCEDURE [dbo].[lvGetPrevPage]
GO

CREATE PROCEDURE [dbo].[lvGetPrevPage]
(
	@lastLogEntryTime datetime,
	@lastLogEntryId int,
	@pageSize int
)
as

declare @ids table ( dt datetime, id int )
declare @count int

set rowcount @pageSize

insert into @ids
select
	[Date],
	LogEntryID
from
	LogEntry with (nolock)
where
	[Date] > @lastLogEntryTime
	or ( [Date] = @lastLogEntryTime
		and LogEntryID > @lastLogEntryId )
order by
	[Date] asc,
	LogEntryID asc
	
set @count = @@ROWCOUNT
if ( @count < @pageSize )
begin

	if ( @count > 0 )
	begin
		set @lastLogEntryTime = (select max(dt) from @ids)
	end
	
	delete @ids
	
	insert into @ids
	select
		[Date],
		LogEntryID
	from
		LogEntry with (nolock)
	where
		[Date] <= @lastLogEntryTime
	order by
		[Date] desc,
		LogEntryID desc
		
end

select
	l.LogEntryID,
	l.MachineName,
	l.Context,
	l.[Date],
	l.[Level],
	l.Message,
	l.ExceptionText
from
	@ids i
	join LogEntry l with (nolock) on
		l.LogEntryID = i.id
order by
	l.[Date] desc,
	l.LogEntryID desc
	
set rowcount 0

select 
	a.LogEntryID,
	n.Name,
	a.Value
from
	@ids i
	join LogEntryAttribute a with (nolock) on
		a.LogEntryID = i.id
	join LogEntryAttributeName n with (nolock) on
		n.AttributeNameID = a.AttributeNameID
order by
	a.LogEntryID desc

return
