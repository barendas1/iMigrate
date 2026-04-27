If dbo.Validation_StoredProcedureExists('PlantImport_ImportPlants') = 1
Begin
	Drop Procedure dbo.PlantImport_ImportPlants
End
Go

Set Ansi_nulls On
Go

Set Quoted_identifier On
Go
-- ================================================================================================
-- Author:		Robert Jansen
-- Create date: 11/06/2014
-- Description:	Import Plants And Yards
-- ================================================================================================
Create Procedure [dbo].[PlantImport_ImportPlants]
As
Begin	
	Declare @PlantInfo Table
	(
    	AutoID Int Identity (1, 1) Not null,
    	Code Nvarchar (100),
    	Name Nvarchar (100),
        Description NVarChar (255),
        MaxBatchSize Float,
        MaxBatchSizeUnitName Nvarchar (100),
        DistrictID Int,
        DistrictCode Nvarchar (100),
        PlantAutoID Int,
        CodeSuffix Int
	)
	
	Declare @HasYards Bit
	
	Declare @PlantCodeValue Int
	Declare @PlantCodeSuffix Int
	
	Declare @NewLine Nvarchar (10)
	
	Declare @ErrorNumber Int
	Declare @ErrorMessage Nvarchar (Max)
	Declare @ErrorSeverity Int
	Declare @ErrorState Int
		
    --Set Nocount On
    
    Begin try
		Begin Transaction
		
		If Exists (Select * From Sys.databases As Databases Where Databases.name = 'Data_Import_RJ')
		Begin
		    If Exists(Select * From Data_Import_RJ.sys.objects Where Name = 'TestImport0000_PlantInfo')		    
		    Begin
		    	Raiserror('', 0, 0) With Nowait
		    	Raiserror('Import Plants', 0, 0) With Nowait
		    	
		    	Set @HasYards = IsNull(dbo.GetAggregatesInYards(), 0)
		    	Set @NewLine = dbo.GetNewLine()
		    	
		    	Raiserror('', 0, 0) With Nowait
		    	Raiserror('Retrieve the Plants that need to be added', 0, 0) With Nowait
		    	
		    	Insert into @PlantInfo (Name, [Description], MaxBatchSize, MaxBatchSizeUnitName)
		    		Select Ltrim(Rtrim(PlantInfo.Name)), Ltrim(Rtrim(PlantInfo.[Description])), PlantInfo.MaxBatchSize, Ltrim(Rtrim(PlantInfo.MaxBatchSizeUnitName))
		    		From Data_Import_RJ.dbo.TestImport0000_PlantInfo As PlantInfo
		    		Left Join dbo.Plants As Plants
		    		On LTrim(RTrim(PlantInfo.Name)) = Plants.Name
		    		Where	Plants.PlantID Is Null And
		    				PlantInfo.AutoID In
		    				(
		    					Select Min(PlantInfo.AutoID)
		    					From Data_Import_RJ.dbo.TestImport0000_PlantInfo As PlantInfo
		    					Where Ltrim(Rtrim(Isnull(PlantInfo.Name, ''))) <> ''
		    					Group By Ltrim(Rtrim(Isnull(PlantInfo.Name, '')))
		    				)
		    		Order By Ltrim(Rtrim(PlantInfo.Name))
		    		
		    	If @HasYards = 1
		    	Begin
		    		Raiserror('', 0, 0) With Nowait
		    		Raiserror('Link the Plants that need to be added to Yards', 0, 0) With Nowait
		    	
		    		Insert into @PlantInfo (Name, [Description], PlantAutoID)
		    			Select PlantInfo.Name + ' Yard', PlantInfo.[Description], PlantInfo.AutoID
		    			From @PlantInfo As PlantInfo
		    			Order By PlantInfo.Name
		    	End
		    	
		    	Raiserror('', 0, 0) With Nowait
		    	Raiserror('Set up Code Suffixes that will be used to set up the Plant Codes', 0, 0) With Nowait
		    	
		    	Update PlantInfo 
		    		Set	PlantInfo.CodeSuffix = RowNumberInfo.CodeSuffix
		    	From @PlantInfo As PlantInfo
		    	Inner Join
		    	(
		    		Select PlantInfo.AutoID, Row_number() Over (Order By PlantInfo.AutoID) As CodeSuffix
		    		From @PlantInfo As PlantInfo
		    		Where PlantInfo.PlantAutoID Is Not Null
		    	) As RowNumberInfo
		    	On PlantInfo.AutoID = RowNumberInfo.AutoID
		    	
		    	Set @PlantCodeSuffix = Isnull((Select Max(PlantInfo.CodeSuffix) From @PlantInfo As PlantInfo Where PlantInfo.CodeSuffix Is Not null), 0)

		    	Update PlantInfo 
		    		Set	PlantInfo.CodeSuffix = RowNumberInfo.CodeSuffix + @PlantCodeSuffix
		    	From @PlantInfo As PlantInfo
		    	Inner Join
		    	(
		    		Select PlantInfo.AutoID, Row_number() Over (Order By PlantInfo.AutoID) As CodeSuffix
		    		From @PlantInfo As PlantInfo
		    		Where PlantInfo.PlantAutoID Is Null
		    	) As RowNumberInfo
		    	On PlantInfo.AutoID = RowNumberInfo.AutoID
		    	
		    	Raiserror('', 0, 0) With Nowait
		    	Raiserror('Retrieve the Last Plant Code Suffix', 0, 0) With Nowait
		    	
		    	If Exists (Select * From dbo.Plants As Plants)
		    	Begin 
		    		Set @PlantCodeValue = (Select Max(Cast(LTrim(RTrim(Substring(Plants.PLNTTAGShouldGoAway, Charindex('-', Plants.PLNTTAGShouldGoAway) + 1, Len(Plants.PLNTTAGShouldGoAway)))) As Int)) From dbo.Plants As Plants)
		    	End
		    	Else
		    	Begin
		    	    Set @PlantCodeValue = 0
		    	End
		    	
		    	Raiserror('', 0, 0) With Nowait
		    	Raiserror('Link Plants To A Concrete District', 0, 0) With Nowait

		    	Update PlantInfo
		    		Set PlantInfo.DistrictID = District.DistrictIdentifier,
		    			PlantInfo.DistrictCode = District.RGCode
		    	From @PlantInfo As PlantInfo
		    	Inner Join dbo.District As District
		    	On District.Name = 'Concrete District'

		    	Raiserror('', 0, 0) With Nowait
		    	Raiserror('Link Plants To The First District If Not Linked To A District', 0, 0) With Nowait

		    	Update PlantInfo
		    		Set PlantInfo.DistrictID = DistrictInfo.DistrictIdentifier,
		    			PlantInfo.DistrictCode = DistrictInfo.RGCode
		    	From @PlantInfo As PlantInfo
		    	Cross Join
		    	(
		    		Select District.DistrictIdentifier, District.RGCode
		    		From dbo.District As District
		    		Where	District.DistrictIdentifier In
		    				(
		    					Select Min(District.DistrictIdentifier)
		    					From dbo.District As District
		    				)
		    	) As DistrictInfo
		    	Where PlantInfo.DistrictID Is Null		    	 
		    	
		    	If @HasYards = 1
		    	Begin
		    		Raiserror('', 0, 0) With Nowait
		    		Raiserror('Add Yards', 0, 0) With Nowait
		    	
		    		Insert into dbo.Plants
		    		(
		    			PLNTTAGShouldGoAway,
		    			Name,
		    			[Description],
		    			ParentBusinessUnitId,
		    			PlantKind,
		    			PlantIdForYard,
		    			DistrictCodeShouldGoAway
		    		)
		    		Select	'P-' + Right('0000000' + Cast(@PlantCodeValue + PlantInfo.CodeSuffix As Nvarchar), 7),
		    				PlantInfo.Name,
		    				PlantInfo.[Description],
		    				PlantInfo.DistrictID,
		    				'ConcreteYard',
		    				Null,
		    				PlantInfo.DistrictCode
		    		From @PlantInfo As PlantInfo
		    		Where PlantInfo.PlantAutoID Is Not null
		    		Order By PlantInfo.AutoID
		
		    		Raiserror('', 0, 0) With Nowait
		    		Raiserror('Add Plants and link them to the Yards', 0, 0) With Nowait
		    	
		    		Insert into dbo.Plants
		    		(
		    			PLNTTAGShouldGoAway,
		    			Name,
		    			[Description],
		    			ParentBusinessUnitId,
		    			PlantKind,
		    			PlantIdForYard,
		    			DistrictCodeShouldGoAway,
		    			MaximumBatchSize
		    		)
		    		Select	'P-' + Right('0000000' + Cast(@PlantCodeValue + PlantInfo.CodeSuffix As Nvarchar), 7),
		    				PlantInfo.Name,
		    				PlantInfo.[Description],
		    				PlantInfo.DistrictID,
		    				'BatchPlant',
		    				ViewYard.PlantID,
		    				PlantInfo.DistrictCode,
		    				PlantInfo.MaxBatchSize
		    		From @PlantInfo As PlantInfo
		    		Inner Join @PlantInfo As YardInfo
		    		On PlantInfo.AutoID = YardInfo.PlantAutoID
		    		Inner Join dbo.ViewPlant As ViewYard
		    		On YardInfo.Name = ViewYard.Name
		    		Where PlantInfo.PlantAutoID Is Null
		    		Order By PlantInfo.AutoID
		    	End
		    	Else
		    	Begin
		    		Raiserror('', 0, 0) With Nowait
		    		Raiserror('Add Plants', 0, 0) With Nowait
		    	
		    		Insert into dbo.Plants
		    		(
		    			PLNTTAGShouldGoAway,
		    			Name,
		    			[Description],
		    			ParentBusinessUnitId,
		    			PlantKind,
		    			DistrictCodeShouldGoAway,
		    			MaximumBatchSize
		    		)
		    		Select	'P-' + Right('0000000' + Cast(@PlantCodeValue + PlantInfo.CodeSuffix As Nvarchar), 7),
		    				PlantInfo.Name,
		    				PlantInfo.[Description],
		    				PlantInfo.DistrictID,
		    				'BatchPlant',
		    				PlantInfo.DistrictCode,
		    				PlantInfo.MaxBatchSize
		    		From @PlantInfo As PlantInfo
		    		Order By PlantInfo.AutoID
		    	End
		    End		    
		End
		
		Commit Transaction
		
		Raiserror('', 0, 0) With Nowait
		Raiserror('The Plants May Have Been Imported.', 0, 0) With Nowait
		
    End Try
	Begin Catch
		If @@TRANCOUNT > 0
		Begin
			Rollback Transaction
		End
	    
		Select  @ErrorNumber  = Error_number(),
				@ErrorSeverity = Error_severity(),
				@ErrorState = Error_state(),
				@ErrorMessage  = Error_message()

		Set @ErrorMessage = --@NewLine +
			'   Error Number: ' + Cast(Isnull(@ErrorNumber, -1) As Nvarchar) + '.  ' + @NewLine +
			'   Error Severity: ' + Cast(Isnull(@ErrorSeverity, -1) As Nvarchar) + '.  ' + @NewLine +
			'   Error State: ' + Cast(Isnull(@ErrorState, -1) As Nvarchar) + '.  ' + @NewLine +
			'   Error Message: ' + Isnull(@ErrorMessage, '') + @NewLine
	    
		Raiserror('', 0, 0) With Nowait
		Raiserror('The Plants and/or Yards culd not be added.  Transaction Rolled Back.', 0, 0) With Nowait
		Print @ErrorMessage
	End Catch
			
	--Set Statistics Time Off

	If dbo.Validation_TemporaryTableExists('#PlantInfo') = 1
	Begin
		Drop table #PlantInfo
	End
End
Go
