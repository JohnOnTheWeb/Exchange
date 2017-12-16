IF ( DB_ID( N'Azure POC_ServiceBusPubSub' ) IS NULL )
	CREATE DATABASE [Azure POC_ServiceBusPubSub]

GO

USE [Azure POC_ServiceBusPubSub]

GO

IF ( SCHEMA_ID( 'DataFix' ) IS NULL )
	EXECUTE( 'CREATE SCHEMA DataFix' )

--	By default, Service Broker is not enabled - if it changes in future, there is no need to enable it
DECLARE @IsBrokerEnabled bit
SELECT	@IsBrokerEnabled = is_broker_enabled
FROM	sys.databases
WHERE	Name = N'Azure POC_ServiceBusPubSub'

--	Enable Service Broker and create master key for this database
IF ( @IsBrokerEnabled = 0 )
	ALTER DATABASE [Azure POC_ServiceBusPubSub]
		SET ENABLE_BROKER
	
--	Create or update master key for this database
IF EXISTS( SELECT principal_id FROM sys.symmetric_keys WHERE principal_id = DATABASE_PRINCIPAL_ID() )
	ALTER MASTER KEY REGENERATE WITH ENCRYPTION BY PASSWORD = 'd4vn0.punj3n3.p4pr1ik3!'
ELSE
	CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'd4vn0.punj3n3.p4pr1ik3!'
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

IF OBJECT_ID( N'[dbo].[Server]', N'U' ) IS NULL
	CREATE TABLE [dbo].[Server]
	(
		[ServerId] [int] IDENTITY(1,1) NOT NULL,
		[EndpointAddress] [varchar](900) NOT NULL
	)
--ELSE
--BEGIN	
--END
GO

IF OBJECT_ID( N'[dbo].[Topic]', N'U' ) IS NULL
	CREATE TABLE [dbo].[Topic]
	(
		[TopicId] [int] IDENTITY(1,1) NOT NULL,
		[ServerId] [int] NOT NULL,
		[Topic] [varchar](896) NOT NULL,
		[IsActive] bit NOT NULL
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

IF OBJECT_ID( N'[dbo].[PK_Server]', N'PK' ) IS NOT NULL
	ALTER TABLE [dbo].[Server] DROP CONSTRAINT [PK_Server]

ALTER TABLE [dbo].[Server] 
	ADD CONSTRAINT [PK_Server] 
	PRIMARY KEY CLUSTERED ( ServerId )
GO

IF OBJECT_ID( N'[dbo].[PK_Topic]', N'PK' ) IS NOT NULL
	ALTER TABLE [dbo].[Topic] DROP CONSTRAINT [PK_Topic]

ALTER TABLE [dbo].[Topic] 
	ADD CONSTRAINT [PK_Topic] 
	PRIMARY KEY CLUSTERED ( TopicId )
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

IF OBJECT_ID( N'[dbo].[IX_Server_EndpointAddress]', N'UQ' ) IS NOT NULL
	ALTER TABLE [dbo].[Server] DROP CONSTRAINT [IX_Server_EndpointAddress]

ALTER TABLE [dbo].[Server]
	ADD CONSTRAINT [IX_Server_EndpointAddress]
	UNIQUE NONCLUSTERED ( EndpointAddress )
GO

IF OBJECT_ID( N'[dbo].[IX_Topic_ServerId_Topic]', N'UQ' ) IS NOT NULL
	ALTER TABLE [dbo].[Topic] DROP CONSTRAINT [IX_Topic_ServerId_Topic]

ALTER TABLE [dbo].[Topic]
	ADD CONSTRAINT [IX_Topic_ServerId_Topic]
	UNIQUE NONCLUSTERED ( ServerId, Topic )
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

IF OBJECT_ID( N'[dbo].[DeactivateServer]', N'P' ) IS NOT NULL
	DROP PROCEDURE [dbo].[DeactivateServer]
GO

CREATE PROCEDURE [dbo].[DeactivateServer]
(
	@ServerId int
)
AS
	DELETE FROM [dbo].[Topic]
	WHERE		[ServerId] = @ServerId
GO

IF OBJECT_ID( N'[dbo].[DeactivateTopic]', N'P' ) IS NOT NULL
	DROP PROCEDURE [dbo].[DeactivateTopic]
GO

CREATE PROCEDURE [dbo].[DeactivateTopic]
(
	@TopicId int
)
AS
	UPDATE	[dbo].[Topic]
	SET		[IsActive] = 0
	WHERE	[TopicId] = @TopicId
GO

IF OBJECT_ID( N'[dbo].[GetOtherSubscriptions]', N'P' ) IS NOT NULL
	DROP PROCEDURE [dbo].[GetOtherSubscriptions]
GO

CREATE PROCEDURE [dbo].[GetOtherSubscriptions]
(
	@ServerId int,
	@LatestTopicId int,
	@Topic varchar(896),
	@IsActive bit
)
AS
	SELECT	t.[TopicId], t.[Topic], s.[EndpointAddress]
	FROM	[dbo].[Server] AS s
			JOIN
			[dbo].[Topic] AS t ON t.[ServerId] = s.[ServerId]
	WHERE	( @ServerId IS NULL OR s.[ServerId] <> @ServerId )
			AND
			( @LatestTopicId IS NULL OR t.[TopicId] > @LatestTopicId )
			AND
			( @Topic IS NULL OR t.[Topic] = @Topic )
			AND
			( @IsActive IS NULL OR t.[IsActive] = @IsActive )
GO

IF OBJECT_ID( N'[dbo].[Server_Ins]', N'P' ) IS NOT NULL
	DROP PROCEDURE [dbo].[Server_Ins]
GO

CREATE PROCEDURE [dbo].[Server_Ins]
(
	@EndpointAddress [varchar](900)
)
AS
	-- Get ServerId
	DECLARE @ServerId int

	SELECT	@ServerId = ServerId
	FROM	[dbo].[Server] WITH ( NOLOCK )
	WHERE	EndpointAddress = @EndpointAddress
	
	-- Insert a server for specified EndpointAddress (if it is not inserted yet)
	IF	@ServerId IS NULL
		BEGIN			
			INSERT INTO [dbo].[Server]
			(
				[EndpointAddress]
			)
			VALUES
			(		
				@EndpointAddress
			)

			SET	@ServerId = SCOPE_IDENTITY()
		END
	
	RETURN @ServerId
GO

IF OBJECT_ID( N'[dbo].[Topic_Del]', N'P' ) IS NOT NULL
	DROP PROCEDURE [dbo].[Topic_Del]
GO

CREATE PROCEDURE [dbo].[Topic_Del]
(
	@TopicId int
)
AS
	DELETE FROM [dbo].[Topic]
	WHERE		[TopicId] = @TopicId
GO

IF OBJECT_ID( N'[dbo].[Topic_Ins]', N'P' ) IS NOT NULL
	DROP PROCEDURE [dbo].[Topic_Ins]
GO

CREATE PROCEDURE [dbo].[Topic_Ins]
(
	@ServerId int,
	@Topic [varchar](896),
	@IsActive bit
)
AS
	DECLARE @TopicId int
	
	SELECT	@TopicId = TopicId
	FROM	[dbo].[Topic]
	WHERE	[ServerId] = @ServerId
			AND
			[Topic] = @Topic
	
	-- Associate the topic with specified server (if it is not already associated)
	IF	@TopicId IS NULL
		BEGIN
			INSERT INTO [dbo].[Topic]
			(
				[ServerId],
				[Topic],
				[IsActive]
			)
			VALUES
			(
				@ServerId,
				@Topic,
				@IsActive
			)
			
			SET	@TopicId = SCOPE_IDENTITY()
		END
	
	RETURN @TopicId
