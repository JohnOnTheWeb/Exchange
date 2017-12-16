IF ( DB_ID( N'Azure POC_ServiceBusMetering' ) IS NULL )
	CREATE DATABASE [Azure POC_ServiceBusMetering]

GO

USE [Azure POC_ServiceBusMetering]

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

IF OBJECT_ID( N'[dbo].[ContextAttribute]', N'U' ) IS NULL
	CREATE TABLE [dbo].[ContextAttribute]
	(
		[AttributeId] [int] IDENTITY(1,1) NOT NULL,
		[MeteringPointId] [int] NOT NULL,
		[Name] [varchar](500) NOT NULL,
		[Value] [varchar](1000) NOT NULL		
	)
--ELSE
--BEGIN	
--END
GO

IF OBJECT_ID( N'[dbo].[MeteringPoint]', N'U' ) IS NULL
	CREATE TABLE [dbo].[MeteringPoint]
	(
		[MeteringPointId] [int] IDENTITY(1,1) NOT NULL,
		[MeteringPointInstanceId] [uniqueidentifier] NOT NULL,
		[Name] [varchar](200) NOT NULL,
		[Code] [varchar](200) NOT NULL,
		[MeteringType] [smallint] NOT NULL,
		[CallerType] [varchar](250) NOT NULL,
		[PublishedName] [varchar](500) NOT NULL,
		[DateCreated] [datetime] NOT NULL,
		[ValueLong] [bigint] NOT NULL,
		[ValueTimeSpan] [real] NOT NULL	
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

IF OBJECT_ID( N'[dbo].[PK_ContextAttribute]', N'PK' ) IS NOT NULL
	ALTER TABLE [dbo].[ContextAttribute] DROP CONSTRAINT [PK_ContextAttribute]

ALTER TABLE [dbo].[ContextAttribute] 
	ADD CONSTRAINT [PK_ContextAttribute] 
	PRIMARY KEY CLUSTERED ( AttributeId )
GO

IF OBJECT_ID( N'[dbo].[PK_MeteringPoint]', N'PK' ) IS NOT NULL
	ALTER TABLE [dbo].[MeteringPoint] DROP CONSTRAINT [PK_MeteringPoint]

ALTER TABLE [dbo].[MeteringPoint] 
	ADD CONSTRAINT [PK_MeteringPoint] 
	PRIMARY KEY CLUSTERED ( MeteringPointId )
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

IF OBJECT_ID( N'[dbo].[ContextAttributeInsert]', N'P' ) IS NOT NULL
	DROP PROCEDURE [dbo].[ContextAttributeInsert]
GO

CREATE PROCEDURE [dbo].[ContextAttributeInsert] 
(
	@MeteringPointId [int],
	@Name1 [varchar](500),
	@Value1 [varchar](1000),
	@Name2 [varchar](500),
	@Value2 [varchar](1000),
	@Name3 [varchar](500),
	@Value3 [varchar](1000),
	@Name4 [varchar](500),
	@Value4 [varchar](1000),
	@Name5 [varchar](500),
	@Value5 [varchar](1000),
	@Name6 [varchar](500),
	@Value6 [varchar](1000),
	@Name7 [varchar](500),
	@Value7 [varchar](1000),
	@Name8 [varchar](500),
	@Value8 [varchar](1000),
	@Name9 [varchar](500),
	@Value9 [varchar](1000),
	@Name10 [varchar](500),
	@Value10 [varchar](1000)
)
AS

IF @name1 IS NOT NULL AND @value1 IS NOT NULL
		INSERT INTO [dbo].[ContextAttribute]
		(
			MeteringPointId,
			[Name],
			Value
		)
		VALUES
		(	
			@MeteringPointId,
			@Name1,
			@Value1
		)
		
	IF @name2 IS NOT NULL AND @value2 IS NOT NULL
		INSERT INTO [dbo].[ContextAttribute]
		(
			MeteringPointId,
			[Name],
			Value
		)
		VALUES
		(	
			@MeteringPointId,
			@Name2,
			@Value2
		)
		
	IF @name3 IS NOT NULL AND @value3 IS NOT NULL
		INSERT INTO [dbo].[ContextAttribute]
		(
			MeteringPointId,
			[Name],
			Value
		)
		VALUES
		(	
			@MeteringPointId,
			@Name3,
			@Value3
		)
		
	IF @name4 IS NOT NULL AND @value4 IS NOT NULL
		INSERT INTO [dbo].[ContextAttribute]
		(
			MeteringPointId,
			[Name],
			Value
		)
		VALUES
		(	
			@MeteringPointId,
			@Name4,
			@Value4
		)
		
	IF @name5 IS NOT NULL AND @value5 IS NOT NULL
		INSERT INTO [dbo].[ContextAttribute]
		(
			MeteringPointId,
			[Name],
			Value
		)
		VALUES
		(	
			@MeteringPointId,
			@Name5,
			@Value5
		)
		
	IF @name6 IS NOT NULL AND @value6 IS NOT NULL
		INSERT INTO [dbo].[ContextAttribute]
		(
			MeteringPointId,
			[Name],
			Value
		)
		VALUES
		(	
			@MeteringPointId,
			@Name6,
			@Value6
		)
		
	IF @name7 IS NOT NULL AND @value7 IS NOT NULL
		INSERT INTO [dbo].[ContextAttribute]
		(
			MeteringPointId,
			[Name],
			Value
		)
		VALUES
		(
			@MeteringPointId,
			@Name7,
			@Value7
		)
		
	IF @name8 IS NOT NULL AND @value8 IS NOT NULL
		INSERT INTO [dbo].[ContextAttribute]
		(
			MeteringPointId,
			[Name],
			Value
		)
		VALUES
		(	
			@MeteringPointId,
			@Name8,
			@Value8
		)
		
	IF @name9 IS NOT NULL AND @value9 IS NOT NULL
		INSERT INTO [dbo].[ContextAttribute]
		(
			MeteringPointId,
			[Name],
			Value
		)
		VALUES
		(
			@MeteringPointId,
			@Name9,
			@Value9
		)
		
	IF @name10 IS NOT NULL AND @value10 IS NOT NULL
		INSERT INTO [dbo].[ContextAttribute]
		(
			MeteringPointId,
			[Name],
			Value
		)
		VALUES
		(	
			@MeteringPointId,
			@Name10,
			@Value10
		)

	RETURN 
GO

IF OBJECT_ID( N'[dbo].[GetMeteringPointFilteredData]', N'P' ) IS NOT NULL
	DROP PROCEDURE [dbo].[GetMeteringPointFilteredData]
GO

CREATE PROCEDURE [dbo].[GetMeteringPointFilteredData]
( 
	@MeteringPointInstanceId [uniqueidentifier], 
	@Name [varchar](200),
	@Code [varchar](200),
	@MeteringType [smallint],
	@CallerType [varchar](250),
	@PublishedName [varchar](500),
	@DateFrom [datetime],
	@DateTo [datetime],	
	@Name1 [varchar](500),
	@Name2 [varchar](500),
	@Name3 [varchar](500),
	@Value1 [varchar](1000),
	@Value2 [varchar](1000),
	@Value3 [varchar](1000),
	@LastSelectedMeteringID [int],
	@PagingDirection [int],	-- 1 = latest, 2 = newer, 3 = older, 4 = oldest
	@PageSize [int] 
)
AS
	DECLARE @FirstId [int]	-- start of selected metering points range
	DECLARE @LastId [int]	-- end of selected metering points range

	DECLARE @UseAttributes [bit]	-- indicates whether there is at least one context attribute filter
	SET @UseAttributes = 0

	-- Check whether there is at least one context attribute filter
	IF @Name1 IS NULL OR @Value1 IS NULL
		SET @Name1 = NULL
	ELSE
		SET @UseAttributes = 1

	IF @Name2 IS NULL OR @Value2 IS NULL
		SET @Name2 = NULL
	ELSE
		SET @UseAttributes = 1

	IF @Name3 IS NULL OR @Value3 IS NULL
		SET @Name3 = NULL
	ELSE
		SET @UseAttributes = 1
	
	-- Select IDs of metering points matching specified filters
	-- (context attribute filters not applied here)
	SELECT	MeteringPointId
	INTO	#MatchingMeteringPointFilters
	FROM	[dbo].[MeteringPoint] (NOLOCK)
	WHERE
		( ( MeteringPointInstanceId = @MeteringPointInstanceId ) OR ( @MeteringPointInstanceId IS NULL ) )
		AND
		( ( Name = @Name ) OR ( @Name IS NULL ) )
		AND
		( ( Code = @Code ) OR ( @Code IS NULL ) )
		AND
		( ( MeteringType = @MeteringType ) OR ( @MeteringType IS NULL ) )
		AND
		( ( CallerType = @CallerType ) OR ( @CallerType IS NULL ) )
		AND
		( ( PublishedName LIKE @PublishedName + '%' ) OR ( @PublishedName IS NULL ) )
		AND
		( ( DateCreated >= @DateFrom ) OR ( @DateFrom IS NULL ) )
		AND
		( ( DateCreated <= @DateTo ) OR ( @DateTo IS NULL ) )

	-- Create table to hold IDs of metering points matching all specified filters
	CREATE TABLE #MatchingAllFilters( MeteringPointId [int] )

	IF ( @UseAttributes = 0 )
		-- Select IDs of metering points matching filters specified for MeteringPoint column value
		-- into table of IDs of metering points matching all filters
		INSERT INTO	#MatchingAllFilters 
		SELECT		mp.MeteringPointId 
		FROM		#MatchingMeteringPointFilters mp
		ORDER BY	mp.MeteringPointId ASC	
	ELSE
		-- Perform ContextAttribute filtering and insert matching metering points IDs
		-- into table of IDs of metering points matching all filters
		INSERT INTO		#MatchingAllFilters 
		SELECT DISTINCT	mp.MeteringPointId 
		FROM			#MatchingMeteringPointFilters mp
			INNER JOIN ContextAttribute ca1
			ON	( ca1.MeteringPointId = mp.MeteringPointId )
				AND
				( ( ( ca1.Name = @Name1 ) AND ( ca1.Value = @Value1 ) ) OR ( @Name1 IS NULL ) )
			INNER JOIN ContextAttribute ca2
			ON	( ca2.MeteringPointId = mp.MeteringPointId )
				AND
				( ( ( ca2.Name = @Name2 ) AND ( ca2.Value = @Value2 ) ) OR ( @Name2 IS NULL ) )
			INNER JOIN ContextAttribute ca3
			ON	( ca3.MeteringPointId = mp.MeteringPointId )
				AND
				( ( ( ca3.Name = @Name3 ) AND ( ca3.Value = @Value3 ) ) OR ( @Name3 IS NULL ) )
		ORDER BY mp.MeteringPointId ASC

	-- Determine range of metering point IDs that shouldbe selected
	IF  ( @PagingDirection = 1 ) -- 1 = latest
		BEGIN					
			SET ROWCOUNT @PageSize
			SELECT	@FirstId = MeteringPointId
			FROM	#MatchingAllFilters
			ORDER BY MeteringPointId DESC
			
			SET ROWCOUNT 1
			SELECT	@LastId = MeteringPointId
			FROM	#MatchingAllFilters
			ORDER BY MeteringPointId DESC
		END
	ELSE IF ( @PagingDirection = 2 ) -- 2 = newer
		BEGIN
			SET ROWCOUNT 1
			SELECT	@FirstId = MeteringPointId
			FROM	#MatchingAllFilters
			WHERE	( MeteringPointId > @LastSelectedMeteringID )
					OR
					( @LastSelectedMeteringID IS NULL)
			
			SET ROWCOUNT @PageSize
			SELECT	@LastId = MeteringPointId
			FROM	#MatchingAllFilters
			WHERE	MeteringPointId > @LastSelectedMeteringID
					OR
					( @LastSelectedMeteringID IS NULL)
		END
	ELSE IF ( @PagingDirection = 3 ) -- 3 = older
		BEGIN			
			--SET ROWCOUNT @PageSize
			SET ROWCOUNT 1
			SELECT	@LastId = MeteringPointId
			FROM	#MatchingAllFilters
			WHERE	MeteringPointId < @LastSelectedMeteringID
					OR
					( @LastSelectedMeteringID IS NULL)
			ORDER BY MeteringPointId DESC			
			
			SET ROWCOUNT @PageSize
			SELECT	@FirstId = MeteringPointId
			FROM	#MatchingAllFilters
			--WHERE	MeteringPointId <= @LastId
			WHERE	MeteringPointId < @LastSelectedMeteringID
					OR
					( @LastSelectedMeteringID IS NULL)
			ORDER BY MeteringPointId DESC
		END		
	ELSE IF ( @PagingDirection = 4 ) -- 4 = oldest
		BEGIN
			SET ROWCOUNT 1
			SELECT @FirstId = MeteringPointId
			FROM #MatchingAllFilters
			
			SET ROWCOUNT @PageSize
			SELECT @LastId = MeteringPointId
			FROM #MatchingAllFilters
		END

	-- Select all matching metering points data and their context attributes
	SET ROWCOUNT 0
	SELECT
		mp.MeteringPointId, mp.MeteringPointInstanceId, mp.Name, mp.Code, mp.MeteringType, mp.CallerType, 
		mp.PublishedName, mp.DateCreated, mp.ValueLong, mp.ValueTimeSpan,
		ca.Name AS AttributeName, ca.Value AS AttributeValue
	FROM #MatchingAllFilters mpp
		INNER JOIN MeteringPoint mp ( NOLOCK )
			ON ( mp.MeteringPointId = mpp.MeteringPointId )
		LEFT OUTER JOIN ContextAttribute ca ( NOLOCK )
			ON ( mp.MeteringPointId = ca.MeteringPointId )
	WHERE
		( mpp.MeteringPointId >= @FirstId )
		AND
		( mpp.MeteringPointId <= @LastId )
	ORDER BY mp.MeteringPointId DESC
	
	-- Return number of matching metering points
	RETURN	( SELECT COUNT(MeteringPointId) FROM #MatchingAllFilters )
GO

IF OBJECT_ID( N'[dbo].[GetMeteringPointPublishedName]', N'P' ) IS NOT NULL
	DROP PROCEDURE [dbo].[GetMeteringPointPublishedName]
GO

CREATE PROCEDURE [dbo].[GetMeteringPointPublishedName]	
AS	
	SELECT DISTINCT PublishedName
	FROM [dbo].[MeteringPoint]
	
	RETURN (SELECT COUNT(*) FROM [dbo].[MeteringPoint])
GO

IF OBJECT_ID( N'[dbo].[MeteringPointInsert]', N'P' ) IS NOT NULL
	DROP PROCEDURE [dbo].[MeteringPointInsert]
GO

CREATE  PROCEDURE [dbo].[MeteringPointInsert] 
(
	@MeteringPointInstanceId [uniqueidentifier],
	@Name [varchar](200),
	@Code [varchar](200),
	@MeteringType [smallint],
	@CallerType [varchar](250),
	@PublishedName [varchar](500),
    @DateCreated [datetime],
    @ValueLong [bigint],
	@ValueTimeSpan [real],
	@Name1 [varchar](500),
	@Value1 [varchar](1000),
	@Name2 [varchar](500),
	@Value2 [varchar](1000),
	@Name3 [varchar](500),
	@Value3 [varchar](1000),
	@Name4 [varchar](500),
	@Value4 [varchar](1000),
	@Name5 [varchar](500),
	@Value5 [varchar](1000),
	@Name6 [varchar](500),
	@Value6 [varchar](1000),
	@Name7 [varchar](500),
	@Value7 [varchar](1000),
	@Name8 [varchar](500),
	@Value8 [varchar](1000),
	@Name9 [varchar](500),
	@Value9 [varchar](1000),
	@Name10 [varchar](500),
	@Value10 [varchar](1000)
)
AS

	DECLARE @MeteringPointId [int]
	
	INSERT INTO [dbo].[MeteringPoint]
	(	
		MeteringPointInstanceId,		
		Name,
		Code,
		MeteringType,
		CallerType,
		PublishedName,
		DateCreated,
		ValueLong,
		ValueTimeSpan 
	)				
	VALUES 
	(
		@MeteringPointInstanceId,			
		@Name,
		@Code,
		@MeteringType,
		@CallerType,
		@PublishedName,
		@DateCreated,
		@ValueLong,
		@ValueTimeSpan 
	)

	SET @MeteringPointId = @@identity

	IF @name1 IS NOT NULL AND @value1 IS NOT NULL
		INSERT INTO [dbo].[ContextAttribute]
		(
			MeteringPointId,
			[Name],
			Value
		)
		VALUES
		(	
			@MeteringPointId,
			@Name1,
			@Value1
		)
		
	IF @name2 IS NOT NULL AND @value2 IS NOT NULL
		INSERT INTO [dbo].[ContextAttribute]
		(
			MeteringPointId,
			[Name],
			Value
		)
		VALUES
		(	
			@MeteringPointId,
			@Name2,
			@Value2
		)
		
	IF @name3 IS NOT NULL AND @value3 IS NOT NULL
		INSERT INTO [dbo].[ContextAttribute]
		(
			MeteringPointId,
			[Name],
			Value
		)
		VALUES
		(	
			@MeteringPointId,
			@Name3,
			@Value3
		)
		
	IF @name4 IS NOT NULL AND @value4 IS NOT NULL
		INSERT INTO [dbo].[ContextAttribute]
		(
			MeteringPointId,
			[Name],
			Value
		)
		VALUES
		(	
			@MeteringPointId,
			@Name4,
			@Value4
		)
		
	IF @name5 IS NOT NULL AND @value5 IS NOT NULL
		INSERT INTO [dbo].[ContextAttribute]
		(
			MeteringPointId,
			[Name],
			Value
		)
		VALUES
		(	
			@MeteringPointId,
			@Name5,
			@Value5
		)
		
	IF @name6 IS NOT NULL AND @value6 IS NOT NULL
		INSERT INTO [dbo].[ContextAttribute]
		(
			MeteringPointId,
			[Name],
			Value
		)
		VALUES
		(	
			@MeteringPointId,
			@Name6,
			@Value6
		)
		
	IF @name7 IS NOT NULL AND @value7 IS NOT NULL
		INSERT INTO [dbo].[ContextAttribute]
		(
			MeteringPointId,
			[Name],
			Value
		)
		VALUES
		(
			@MeteringPointId,
			@Name7,
			@Value7
		)
		
	IF @name8 IS NOT NULL AND @value8 IS NOT NULL
		INSERT INTO [dbo].[ContextAttribute]
		(
			MeteringPointId,
			[Name],
			Value
		)
		VALUES
		(	
			@MeteringPointId,
			@Name8,
			@Value8
		)
		
	IF @name9 IS NOT NULL AND @value9 IS NOT NULL
		INSERT INTO [dbo].[ContextAttribute]
		(
			MeteringPointId,
			[Name],
			Value
		)
		VALUES
		(
			@MeteringPointId,
			@Name9,
			@Value9
		)
		
	IF @name10 IS NOT NULL AND @value10 IS NOT NULL
		INSERT INTO [dbo].[ContextAttribute]
		(
			MeteringPointId,
			[Name],
			Value
		)
		VALUES
		(	
			@MeteringPointId,
			@Name10,
			@Value10
		)

	RETURN @MeteringPointId
GO

IF OBJECT_ID( N'[dbo].[MeteringPointSelect]', N'P' ) IS NOT NULL
	DROP PROCEDURE [dbo].[MeteringPointSelect]
GO

CREATE PROCEDURE [dbo].[MeteringPointSelect]
(
	@MeteringPointId [uniqueidentifier]
)
AS
	SELECT * 
	FROM [dbo].[MeteringPoint]
	WHERE MeteringPointInstanceId = @MeteringPointId
