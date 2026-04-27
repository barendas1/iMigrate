If dbo.Validation_ViewExists('RptMixSpecSpread') = 1
Begin
    Drop View [dbo].[RptMixSpecSpread]
End
Go

Set Ansi_nulls On
Go

Set Quoted_identifier On
Go
Create View [dbo].[RptMixSpecSpread] As
Select  MixSpec.MixSpecID              As MixSpecID,
        MixSpec.Name                   As Name,
        MixSpec.[Description]          As Description,
        MixSpec.UserDefGradingID       As UserDefinedGradingID,
        MixSpec.SharedGradingID        As StandardGradingID,
        SpecDataPoint.SpecDataPointID  As SpecDataPointID,
        SpecMeas.SpecMeasID            As SpecMeasID,
        SpecMeas.MeasTypeID            As MeasTypeID,
        SpecMeas.MinValue              As MinSpread,
        SpecMeas.MaxValue              As MaxSpread,
        SpecMeas.UnitsLink             As SpreadUnitsID
    From dbo.MixSpec                   As MixSpec
    Inner Join dbo.SpecDataPoint       As SpecDataPoint
    On  SpecDataPoint.MixSpecID = MixSpec.MixSpecID
    Inner Join dbo.SpecMeas            As SpecMeas
    On  SpecMeas.SpecDataPointID = SpecDataPoint.SpecDataPointID
    Where   Isnull(SpecMeas.MeasTypeID, -1) = 32
Go

If dbo.Validation_ViewExists('RptMixSpecAggSize') = 1
Begin
    Drop View [dbo].[RptMixSpecAggSize]
End
Go

Set Ansi_nulls On
Go

Set Quoted_identifier On
Go
Create View [dbo].[RptMixSpecAggSize] As
Select  MixSpec.MixSpecID              As MixSpecID,
        MixSpec.Name                   As Name,
        MixSpec.[Description]          As Description,
        MixSpec.UserDefGradingID       As UserDefinedGradingID,
        MixSpec.SharedGradingID        As StandardGradingID,
        SpecDataPoint.SpecDataPointID  As SpecDataPointID,
        SpecMeas.SpecMeasID            As SpecMeasID,
        SpecMeas.MeasTypeID            As MeasTypeID,
        SpecMeas.MinValue              As MinAggSize,
        SpecMeas.MaxValue              As MaxAggSize,
        SpecMeas.UnitsLink             As AggSizeUnitsID
    From dbo.MixSpec                   As MixSpec
    Inner Join dbo.SpecDataPoint       As SpecDataPoint
    On  SpecDataPoint.MixSpecID = MixSpec.MixSpecID
    Inner Join dbo.SpecMeas            As SpecMeas
    On  SpecMeas.SpecDataPointID = SpecDataPoint.SpecDataPointID
    Where   Isnull(SpecMeas.MeasTypeID, -1) = 31
Go

If dbo.Validation_ViewExists('RptMixSpecUnitWeight') = 1
Begin
    Drop View [dbo].[RptMixSpecUnitWeight]
End
Go

Set Ansi_nulls On
Go

Set Quoted_identifier On
Go
Create View [dbo].[RptMixSpecUnitWeight] As
Select  MixSpec.MixSpecID              As MixSpecID,
        MixSpec.Name                   As Name,
        MixSpec.[Description]          As Description,
        MixSpec.UserDefGradingID       As UserDefinedGradingID,
        MixSpec.SharedGradingID        As StandardGradingID,
        SpecDataPoint.SpecDataPointID  As SpecDataPointID,
        SpecMeas.SpecMeasID            As SpecMeasID,
        SpecMeas.MeasTypeID            As MeasTypeID,
        SpecMeas.MinValue              As MinUnitWeight,
        SpecMeas.MaxValue              As MaxUnitWeight,
        SpecMeas.UnitsLink             As UnitWeightUnitsID
    From dbo.MixSpec                   As MixSpec
    Inner Join dbo.SpecDataPoint       As SpecDataPoint
    On  SpecDataPoint.MixSpecID = MixSpec.MixSpecID
    Inner Join dbo.SpecMeas            As SpecMeas
    On  SpecMeas.SpecDataPointID = SpecDataPoint.SpecDataPointID
    Where   Isnull(SpecMeas.MeasTypeID, -1) = 23
Go

If dbo.Validation_FunctionExists('GetUnicodeValueListFromStringValue') = 1
Begin
    Drop function [dbo].[GetUnicodeValueListFromStringValue]
End
Go

Set Ansi_nulls On
Go

Set Quoted_identifier On
Go
-- ================================================================================================
-- Author:		Robert Jansen
-- Create date: 04/30/2019
-- Description:	Return a list of unicode string values from a string value.
-- ================================================================================================
Create Function [dbo].[GetUnicodeValueListFromStringValue]
(
	@Value                      Nvarchar(Max),
	@Delimiter                  Nvarchar(10),	--If the delimiter is null or blank, then the default delimiter will be a space.
	@TrimSubStrings             Bit = 1,
	@PutSubStringsInUCase       Bit = 0,
	@PutSubStringsInLCase       Bit = 0,
	@CanAddBlankStrings         Bit = 0,
	@CanAddEmptyStrings         Bit = 0,
	@CanReplaceChar160WithSpace Bit = 1
)
Returns @ValueList Table 
(
    AutoID Int Identity(1, 1),
    Value Nvarchar(Max),
    Primary Key Clustered(AutoID)
)
As
Begin
	Declare @ListValue Nvarchar (Max)
	Declare @ListDelimiter Nvarchar (Max)
	Declare @TrimValue Bit
	Declare @PutValueInUCase Bit
	Declare @PutValueInLCase Bit
	Declare @AddBlankStrings Bit
	Declare @AddEmptyStrings Bit
	Declare @ReplaceChar160 Bit
	
    Declare @StrPos1       Bigint
    Declare @StrPos2       Bigint
    Declare @StrLen        Bigint
    Declare @DelimiterLen  Bigint
    Declare @SubValue      Nvarchar(Max)

	Set @ListValue = @Value
	Set @ListDelimiter = @Delimiter
	Set @TrimValue = IsNull(@TrimSubStrings, 1)
	Set @PutValueInUCase = Isnull(@PutSubStringsInUCase, 0)
	Set @PutValueInLCase = Isnull(@PutSubStringsInLCase, 0)
	Set @AddBlankStrings = Isnull(@CanAddBlankStrings, 0)
	Set @AddEmptyStrings = Isnull(@CanAddEmptyStrings, 0)
	Set @ReplaceChar160 = Isnull(@CanReplaceChar160WithSpace, 1)
	
    If Isnull(@ListValue, '') <> ''
    Begin
        If Isnull(@ListDelimiter, '') = ''
        Begin
            Set @ListDelimiter = ' '
        End
        
        If @ReplaceChar160 = 1
        Begin
            Set @ListValue = Replace(@ListValue, Char(160), ' ')
            Set @ListDelimiter = Replace(@ListDelimiter, Char(160), ' ')
        End
        
        --Using NVarChars - 2 Bytes Each - must divide by two to get the correct number of characters.
        --Len function does not count Trailing Blanks.
        Set @StrLen = DataLength(@ListValue) / 2 
        Set @DelimiterLen = DataLength(@ListDelimiter) / 2
        
        Set @StrPos1 = 1
        Set @StrPos2 = 0
        
        While (@StrPos1 > 0 And @StrPos1 <= @StrLen)
        Begin
            Set @StrPos2 = Charindex(@ListDelimiter, @ListValue, @StrPos1)
            
            If @StrPos1 = @StrPos2
            Begin
                If @AddEmptyStrings = 1
                Begin
                    Insert Into @ValueList
                    (
                        Value
                    )
                    Values
                    (
                        ''
                    )
                End
            End
            Else
            Begin
                If @StrPos1 < @StrPos2
                Begin
                    Set @SubValue = Substring(@ListValue, @StrPos1, @StrPos2 - @StrPos1)
                End
                Else
                Begin
                    Set @SubValue = Substring(@ListValue, @StrPos1, @StrLen - @StrPos1 + 1)
                End
                
                If @TrimValue = 1
                Begin
                    Set @SubValue = Ltrim(Rtrim(@SubValue))
                End
                
                If @PutValueInUCase = 1
                Begin
                    Set @SubValue = Upper(@SubValue)
                End
                Else If @PutValueInLCase = 1
                Begin
                    Set @SubValue = Lower(@SubValue)
                End
                
                If Ltrim(Rtrim(@SubValue)) <> '' Or
                   @AddEmptyStrings = 1 And
                   @SubValue = '' Or
                   @AddBlankStrings = 1 And
                   @SubValue <> '' And
                   Ltrim(Rtrim(@SubValue)) = ''
                Begin
                    Insert Into @ValueList
                    (
                        Value
                    )
                    Values
                    (
                        @SubValue
                    )
                End
            End
            
            If @StrPos2 >= @StrPos1
            Begin
                Set @StrPos1 = @StrPos2 + @DelimiterLen
            End
            Else
            Begin
                Set @StrPos1 = @StrLen + 1
            End
        End
    End
    
    Return
End
Go






If dbo.Validation_FunctionExists('Validation_IsValidBase26Number') = 1
Begin
	Drop function [dbo].[Validation_IsValidBase26Number]
End
Go
	
Set Ansi_nulls On
Go

Set Quoted_identifier On
Go
-- ================================================================================================
-- Author:		Robert Jansen
-- Create date: 01/20/2014
-- Description:	Return "True" if the Value is a Valid Base 26 Number.
-- ================================================================================================
Create Function [dbo].[Validation_IsValidBase26Number]
(
    @Base26Number Nvarchar (Max)
)
Returns Bit
As
Begin
	Declare @FirstValue Int
	Declare @LastValue Int
	Declare @CharValue Int
	Declare @ValueLength Bigint
	Declare @Index Bigint
	Declare @IsValid Bit
    Declare @Base26Value NVarChar (Max)
        
    Set @IsValid = 0
    
    Set @Base26Value = Upper(Ltrim(Rtrim(Isnull(@Base26Number, ''))))
    
    If @Base26Value <> ''
    Begin
		Set @FirstValue = Ascii('A')
		Set @LastValue = Ascii('Z')
	    
		Set @ValueLength = Len(@Base26Value)
		
        Set @IsValid = 1
        
        Set @Index = 1
        
        While (@Index <= @ValueLength)
        Begin
        	Set @CharValue = Ascii(Substring(@Base26Value, @Index, 1))
        	
        	If @CharValue < @FirstValue Or @CharValue > @LastValue
        	Begin
        	    Set @IsValid = 0
        	    Break
        	End
        	
            Set @Index = @Index + 1
        End
    End
    
	Return @IsValid
End
Go

If dbo.Validation_FunctionExists('GetBase10NumberFromBase26Number') = 1
Begin
	Drop function [dbo].[GetBase10NumberFromBase26Number]
End
Go
	
Set Ansi_nulls On
Go

Set Quoted_identifier On
Go
-- ================================================================================================
-- Author:		Robert Jansen
-- Create date: 01/20/2014
-- Description:	Return a Base 10 Number from a Base 26 Number.
-- ================================================================================================
Create Function [dbo].[GetBase10NumberFromBase26Number]
(
    @Base26Number Nvarchar (Max)
)
Returns BigInt
As
Begin
    Declare @Index BigInt
    Declare @NumOfChars BigInt
    Declare @FirstLetter BigInt
    Declare @Base10Number BigInt
    Declare @Base26Num NVarChar (Max)
    
    Set @Base10Number = Null
    
    If dbo.Validation_IsValidBase26Number(@Base26Number) = 1
    Begin        
        Set @Base26Num = Upper(LTrim(RTrim(@Base26Number)))
        
        Set @NumOfChars = Len(@Base26Num)
        
        Set @FirstLetter = Ascii('A')
        
        Set @Base10Number = 0
        
        Set @Index = @NumOfChars
        
        While (@Index > 0)
        Begin
            Set @Base10Number = @Base10Number + Power(26.0, (@NumOfChars - @Index)) * (Ascii(SubString(@Base26Num, @Index, 1)) - @FirstLetter)
            Set @Index = @Index - 1
        End
    End
    
	Return @Base10Number
End
Go

If dbo.Validation_FunctionExists('GetBase26NumberFromBase10Number') = 1
Begin
	Drop function [dbo].[GetBase26NumberFromBase10Number]
End
Go
	
Set Ansi_nulls On
Go

Set Quoted_identifier On
Go
-- ================================================================================================
-- Author:		Robert Jansen
-- Create date: 01/20/2014
-- Description:	Return a Base 26 Number from a Base 10 Number.
-- ================================================================================================
Create Function [dbo].[GetBase26NumberFromBase10Number]
(
    @Base10Number BigInt
)
Returns Nvarchar (Max)
As
Begin
    Declare @ABSNum BigInt
    --Declare @IsNegativeNum Bit
    Declare @RemainderNum BigInt
    Declare @Base26Divider BigInt
    Declare @Base26Number NVarChar (Max)
    Declare @FirstLetter BigInt
    Declare @Index BigInt

    Set @Base26Number = Null
    
    If IsNull(@Base10Number, -1) >= 0
    Begin
        Set @Base26Divider = 26
        Set @Base26Number = ''
        Set @FirstLetter = Ascii('A')
        Set @Index = 1
        
        --If @Base10Number < 0 
        --Begin
        --    Set @IsNegativeNum = 1
        --End
        --Else
        --Begin
        --    Set @IsNegativeNum = 0
        --End
        
        Set @ABSNum = Abs(@Base10Number)
        
        While (@ABSNum <> 0 Or @Index = 1)
        Begin
            Set @RemainderNum = @ABSNum % @Base26Divider
            Set @Base26Number = Char(@FirstLetter + @RemainderNum) + @Base26Number
            Set @ABSNum = Floor(@ABSNum / @Base26Divider)
            Set @Index = @Index + 1
        End
        
        --If @IsNegativeNum = 1
        --Begin
        --    Set @Base26Number = '-' + @Base26Number
        --End
    End
    
	Return @Base26Number
End
Go

If dbo.Validation_FunctionExists('GetMixNameCodeList') = 1
Begin
	Drop function [dbo].[GetMixNameCodeList]
End
Go
	
Set Ansi_nulls On
Go

Set Quoted_identifier On
Go
-- ================================================================================================
-- Author:		Robert Jansen
-- Create date: 01/20/2014
-- Description:	Return a list of Mix Name Codes starting at the Mix Name Code specified.
-- ================================================================================================
Create Function [dbo].[GetMixNameCodeList]
(
	@NumberOfMixNameCodes Int,
    @StartMixNameCode Nvarchar (20) = 'A',
    @NumberOfCharacters Int = 4    
)
Returns @MixNameCodeList Table
(
	AutoID Int Identity (1, 1),
	MixNameCode Nvarchar (20),
	MixNameCodeValue Bigint,
	Primary Key Clustered 
	(
		MixNameCode
	)
)
As
Begin
	Declare @Index Bigint
	Declare @MixNameCode Nvarchar (20)
	Declare @Base10Number Bigint
	
	If	Isnull(@NumberOfMixNameCodes, -1) > 0 And
		Isnull(@NumberOfCharacters, -1) > 0
	Begin
		If @NumberOfCharacters > 20
		Begin
		    Set @NumberOfCharacters = 20
		End
		
		Set @MixNameCode = Upper(Ltrim(Rtrim(Isnull(@StartMixNameCode, ''))))
		
		If dbo.Validation_IsValidBase26Number(@MixNameCode) = 0
		Begin
		    Set @MixNameCode = 'A'
		End
				
    	Set @Base10Number = dbo.GetBase10NumberFromBase26Number(@MixNameCode)
    	Set @MixNameCode = dbo.GetBase26NumberFromBase10Number(@Base10Number) --Trim off extra A's.    	
    	
		Set @Index = 1
		
		While (@Index <= @NumberOfMixNameCodes)
		Begin
			If Len(@MixNameCode) > @NumberOfCharacters
			Begin
			    Break
			End
			
			Set @MixNameCode = Right(Replicate('A', @NumberOfCharacters) + @MixNameCode, @NumberOfCharacters)
			
			Insert into @MixNameCodeList (MixNameCode, MixNameCodeValue)
				Values (@MixNameCode, @Base10Number)

			Set @Base10Number = @Base10Number + 1
			Set @MixNameCode = dbo.GetBase26NumberFromBase10Number(@Base10Number)
			
			Set @Index = @Index + 1
		End
    End
	
	Return
End
Go

If dbo.Validation_StoredProcedureExists('Utility_DisplayConsoleMessage') = 1
Begin
    Drop Procedure dbo.Utility_DisplayConsoleMessage
End
Go

Set Ansi_nulls On
Go

Set Quoted_identifier On
Go
-- ================================================================================================
-- Author:		Robert Jansen
-- Create date: 09/26/2017
-- Description:	Display the Message in the Console.
-- ================================================================================================
Create Procedure dbo.Utility_DisplayConsoleMessage
(
	@DisplayMessage Nvarchar (Max)
)
As
Begin
	Declare @Message Nvarchar (Max)
	
    Set Nocount On
    
    Set @Message = IsNull(@DisplayMessage, '')
		
	Raiserror('', 0, 0) With Nowait
	Raiserror(@Message, 0, 0) With Nowait
End	
Go

If dbo.Validation_StoredProcedureExists('MixImport_ImportItemCategories') = 1
Begin
	Drop Procedure dbo.MixImport_ImportItemCategories
End
Go

Set Ansi_nulls On
Go

Set Quoted_identifier On
Go
-- ================================================================================================
-- Author:		Robert Jansen
-- Create date: 11/17/2014
-- Description:	Import Item Categories
-- ================================================================================================
Create Procedure [dbo].[MixImport_ImportItemCategories]
As
Begin
	Declare @ErrorMessage Nvarchar (Max)
	Declare @ErrorSeverity Int
		
    --Set Nocount On
    
    Begin try
		Begin Transaction
		
		If Exists (Select * From Sys.databases As Databases Where Databases.name = 'Data_Import_RJ')
		Begin
		    If Exists(Select * From Data_Import_RJ.sys.objects As Objects Where Objects.name = 'TestImport0000_MixItemCategory')		    
		    Begin
		    	Print ''
		    	Print 'Add New Item Categories'
		    	
		    	Insert into dbo.ProductionItemCategory
		    	(
		    		ItemCategory,
		    		[Description],
		    		ShortDescription,
		    		ProdItemCatType
		    	)
		    	Select	Ltrim(Rtrim(ItemCategoryInfo.Name)), 
		    			Ltrim(Rtrim(ItemCategoryInfo.[Description])),
		    	      	Ltrim(Rtrim(ItemCategoryInfo.ShortDescription)),
		    	      	Ltrim(Rtrim(ItemCategoryInfo.CategoryType))
		    	From Data_Import_RJ.dbo.TestImport0000_MixItemCategory As ItemCategoryInfo		    	
		    	Left Join dbo.ProductionItemCategory As ExistingItemCategory
		    	On	Ltrim(Rtrim(ItemCategoryInfo.Name)) = Ltrim(Rtrim(ExistingItemCategory.ItemCategory)) And
		    		Ltrim(Rtrim(ItemCategoryInfo.CategoryType)) = Ltrim(Rtrim(ExistingItemCategory.ProdItemCatType))
		    	Where	ExistingItemCategory.ProdItemCatID Is Null And
		    			ItemCategoryInfo.AutoID In
		    			(
		    				Select Min(ItemCategoryInfo.AutoID)
		    				From Data_Import_RJ.dbo.TestImport0000_MixItemCategory As ItemCategoryInfo
		    				Where	Ltrim(Rtrim(Isnull(ItemCategoryInfo.Name, ''))) <> '' And
		    						LTrim(RTrim(IsNull(ItemCategoryInfo.CategoryType, ''))) In ('Mix', 'Mtrl', 'MtrlCompType')
		    				Group By Ltrim(Rtrim(ItemCategoryInfo.CategoryType)), Ltrim(Rtrim(ItemCategoryInfo.Name))	    	
		    			)
		    	
		    End		    
		End
		
		Commit Transaction
		
		Print ''
		Print 'The Item Categories May Have Been Imported.'
		
    End Try
    Begin catch
		If @@TRANCOUNT > 0
		Begin
		    Rollback Transaction
		End
		
		Select	@ErrorMessage = Error_message(),
				@ErrorSeverity = Error_severity()

		Print 'The Item Categories could not be imported.  The Import was rolled back.'
		Print 'Error Message - ' + @ErrorMessage
		Print 'Error Severity - ' + Cast(@ErrorSeverity As Nvarchar) + '.'		

		Raiserror(@ErrorMessage, @ErrorSeverity, 1)
    End Catch
End
Go

If dbo.Validation_StoredProcedureExists('MixImport_ImportMixes') = 1
Begin
	Drop Procedure dbo.MixImport_ImportMixes
End
Go

Set Ansi_nulls On
Go

Set Quoted_identifier On
Go
-- ================================================================================================
-- Author:		Robert Jansen
-- Create date: 11/07/2014
-- Description:	Import Mixes into the Plants
-- ================================================================================================
Create Procedure [dbo].[MixImport_ImportMixes]
(
	@AllowedToOverwriteMixes Bit = 1,
	@UpdateExistingProdItems Bit = 1,
	@RemoveExistingMixClasses Bit = 1,
	@AllowedToAddInactiveMaterials Bit = 0,
	@DeactivateNewMixes Bit = 0,
	@DeactivateExistingMixes Bit = 0,
	@UpdateMixReportFields Bit = 1
)
As
Begin    
    Declare @ExistingMix Table (AutoID Int Identity (1, 1), PlantCode Nvarchar (100), MixCode Nvarchar(100), Unique Nonclustered (PlantCode, MixCode))
    Declare @CementMix Table (AutoID Int Identity (1, 1), PlantCode Nvarchar (100), MixCode Nvarchar(100), Unique Nonclustered (PlantCode, MixCode))
    Declare @CementitiousMix Table (AutoID Int Identity (1, 1), PlantCode Nvarchar (100), MixCode Nvarchar(100), Unique Nonclustered (PlantCode, MixCode))
    Declare @AdmixtureMix Table (AutoID Int Identity (1, 1), PlantCode Nvarchar (100), MixCode Nvarchar(100), Unique Nonclustered (PlantCode, MixCode))
    Declare @NeedsCementMix Table (AutoID Int Identity (1, 1), PlantCode Nvarchar (100), MixCode Nvarchar(100), Unique Nonclustered (PlantCode, MixCode))
    Declare @MultiMaterial Table (AutoID Int Identity (1, 1), PlantCode Nvarchar (100), MixCode Nvarchar(100), Unique Nonclustered (PlantCode, MixCode))
    Declare @MissingMaterial Table (AutoID Int Identity (1, 1), PlantCode Nvarchar (100), MixCode Nvarchar(100), Unique Nonclustered (PlantCode, MixCode))
    Declare @MixAutoIDInfo Table (AutoID Int Identity (1, 1), MixAutoID Int, Unique Nonclustered (MixAutoID))
    Declare @MixProdInfo Table (AutoID Int Identity (1, 1), MixID Int, Unique Nonclustered (MixID)) 
    
    Declare @AttachmentInfo Table (AutoID Int Identity (1, 1), MixAutoID Int, AttachmentName Nvarchar (300))
    Declare @MixAttachmentInfo Table (AutoID Int Identity(1, 1), MixAutoID Int, MixID Int, AttachmentID Int, AttachmentName Nvarchar (300), AttachmentTypeID Int, SortNumber Int, LastSortNumber Int) 
    Declare @MixClassInfo Table (AutoID Int Identity (1, 1), MixAutoID Int, MixClassName Nvarchar (100))

	Drop Table If Exists #MixReportInfo

	Create Table #MixReportInfo
	(
		MixID Int, 
		MixSpecID Int, 
		PlantName Nvarchar (100),
		MixName Nvarchar (100),
		Strength Float, 
		MinSlump Float, 
		MaxSlump Float, 
		MinAirContent Float, 
		MaxAirContent Float,
		MixStrength Float, 
		MixMinSlump Float, 
		MixMaxSlump Float, 
		MixMinAirContent Float, 
		MixMaxAirContent Float
	)

	Create Unique Clustered Index IX_MixReportInfo_MixID On #MixReportInfo (MixID)
    Create Index IX_MixReportInfo_MixSpecID On #MixReportInfo (MixSpecID)

	Declare @AggregatesInYards Bit 
	
	Declare @CodeDate Nvarchar (20)
	Declare @CodeSuffix Int
	Declare @MixNameCode Nvarchar (20)
	Declare @LastID Int
	Declare @MixTimeStamp Datetime
	Declare @MixDate Nvarchar (20)
	Declare @MixTime Nvarchar (20)
	
	Declare @Index Int
	Declare @MaxIndex Int
	Declare @MixAutoID Int
	Declare @AttachmentNames Nvarchar (Max)
	Declare @MixClassNames Nvarchar (Max)
	Declare @AttachmentFilePath Nvarchar (Max)
		
	Declare @NewLine Nvarchar (10)
	
	Declare @ErrorNumber Int
	Declare @ErrorMessage Nvarchar (Max)
	Declare @ErrorSeverity Int
	Declare @ErrorState Int
	
	Set @NewLine = dbo.GetNewLine()
		
    --Set Nocount On

	If dbo.Validation_DatabaseTemporaryTableExists('#MixInfo') = 1
	Begin
	    Drop table #MixInfo
	End
	
	Create table #MixInfo
	(
		AutoID Int Identity (1, 1),
		MixID Int,
		PlantName Nvarchar (100),
		MixName Nvarchar (100),
		Description Nvarchar (300),
		ShortDescription Nvarchar (100),
		ItemCategory Nvarchar (100),
		MixClassNames Nvarchar (Max),
		MixUsage Nvarchar (Max),
		AttachmentFileNames Nvarchar (Max),
		StrengthAge Float,
		Strength Float,
		AirContent Float,
		MinAirContent Float,
		MaxAirContent Float,
		Slump Float,
		MinSlump Float,
		MaxSlump Float,
		Spread Float,
		MinSpread Float,
		MaxSpread Float,
		DispatchSlumpRange Nvarchar (100),
		MinAggregateSize Float,
		MaxAggregateSize Float,
		MinUnitWeight Float,
		MaxUnitWeight Float,
		MinWCRatio Float,
		MaxWCRatio Float,
		MinWCMRatio Float,
		MaxWCMRatio Float,
		MaxLoadSize	Float,
		MaxWater Float,
		SackContent	Float, 
		Price Float,
		PriceUnitName Nvarchar (100),
		MixInactive Nvarchar (30),
		MaxAttachmentSortNumber Int,
		ActualMixID Int,
		MixCode Nvarchar (20),
		MixNameCode Nvarchar (20),
		MixSpecID Int,
		StrengthDataPointID Int,
		AirDataPointID Int,
		SlumpDataPointID Int,
		SpreadDataPointID Int,
		AggSizeDataPointID Int,
		UnitWeightDataPointID Int,
		StrengthAgeMeasID Int,
		StrengthMeasID Int,
		AirMeasID Int,
		SlumpMeasID Int,
		SpreadMeasID Int,
		AggSizeMeasID Int,
		UnitWeightMeasID Int,

		WCRatio1ID Int,
		WCNumerator1ID Int,
		WCDenominator1ID Int,

		WCMRatio1ID Int,
		WCMNumerator1ID Int,
		WCMDenominator1ID Int,
		WCMDenominator2ID Int,
		
		Primary Key Nonclustered
		(
			MixID
		),
		Unique Nonclustered
		(
			AutoID
		),
		Unique Nonclustered
		(
			PlantName,
			MixName
		)
	)
	
	Create Index IX_MixInfo_PlantName On #MixInfo (PlantName)
	Create Index IX_MixInfo_MixName On #MixInfo (MixName)
	Create Index IX_MixInfo_Description On #MixInfo (Description)
	Create Clustered Index IX_MixInfo_ActualMixID On #MixInfo (ActualMixID)
	Create Index IX_MixInfo_MixCode On #MixInfo (MixCode)
	Create Index IX_MixInfo_MixNameCode On #MixInfo (MixNameCode)
	Create Index IX_MixInfo_MixSpecID On #MixInfo (MixSpecID)
	Create Index IX_MixInfo_StrengthDataPointID On #MixInfo (StrengthDataPointID)
	Create Index IX_MixInfo_AirDataPointID On #MixInfo (AirDataPointID)
	Create Index IX_MixInfo_SlumpDataPointID On #MixInfo (SlumpDataPointID)
	Create Index IX_MixInfo_SpreadDataPointID On #MixInfo (SpreadDataPointID)
	Create Index IX_MixInfo_AggSizeDataPointID On #MixInfo (AggSizeDataPointID)
	Create Index IX_MixInfo_UnitWeightDataPointID On #MixInfo (UnitWeightDataPointID)
	Create Index IX_MixInfo_StrengthAgeMeasID On #MixInfo (StrengthAgeMeasID)
	Create Index IX_MixInfo_StrengthMeasID On #MixInfo (StrengthMeasID)
	Create Index IX_MixInfo_AirMeasID On #MixInfo (AirMeasID)
	Create Index IX_MixInfo_SlumpMeasID On #MixInfo (SlumpMeasID)
	Create Index IX_MixInfo_SpreadMeasID On #MixInfo (SpreadMeasID)
	Create Index IX_MixInfo_AggSizeMeasID On #MixInfo (AggSizeMeasID)
	Create Index IX_MixInfo_UnitWeightMeasID On #MixInfo (UnitWeightMeasID)
	
	If dbo.Validation_DatabaseTemporaryTableExists('#MixRecipeInfo') = 1
	Begin
	    Drop table #MixRecipeInfo
	End

	Create table #MixRecipeInfo
	(
    	AutoID Int Identity (1, 1),
		MixID Int,
		PlantName Nvarchar (100),
		MixName Nvarchar (100),
		MaterialItemCode Nvarchar (100),
		Quantity Float,
		QuantityUnit Nvarchar (100),			
		ConvertedQuantity Float,
		SortNumber Int,
		PlantID Int,
		MaterialID Int,
		MaterialCode Nvarchar (20),
		FamilyMaterialTypeID Int,
		SpecificGravity Float,
		MaterialMoisture Float,
		Primary Key Nonclustered
		(
			MixID,
			MaterialItemCode			
		),
		Unique Nonclustered
		(
			AutoID
		),
		Unique Nonclustered
		(
			PlantName,
			MixName,
			MaterialItemCode
		)
	)
    
    Create Index IX_MixRecipeInfo_MixID On #MixRecipeInfo (MixID)
    Create Index IX_MixRecipeInfo_PlantName On #MixRecipeInfo (PlantName)
    Create Index IX_MixRecipeInfo_MixName On #MixRecipeInfo (MixName)
    Create Index IX_MixRecipeInfo_MaterialItemCode On #MixRecipeInfo (MaterialItemCode)
    Create Index IX_MixRecipeInfo_PlantID On #MixRecipeInfo (PlantID)
    Create Index IX_MixRecipeInfo_MaterialID On #MixRecipeInfo (MaterialID)
    Create Index IX_MixRecipeInfo_MaterialCode On #MixRecipeInfo (MaterialCode)
    Create Index IX_MixRecipeInfo_FamilyMaterialTypeID On #MixRecipeInfo (FamilyMaterialTypeID)
    
    If dbo.Validation_DatabaseTemporaryTableExists('#MaterialInfo') = 1
    Begin
		Drop Table #MaterialInfo
    End
    
    Create table #MaterialInfo
    (
    	AutoID Int Identity (1, 1),
    	PlantName Nvarchar (100),
    	ItemCode Nvarchar (100),
    	SpecificGravity Float,
    	Moisture Float,
    	PlantID Int,
    	MaterialID Int,
    	MaterialCode Nvarchar (30),
    	FamilyMaterialTypeID Int,
    )
    
    Create Index IX_MaterialInfo_AutoID On #MaterialInfo (AutoID)
    Create Index IX_MaterialInfo_PlantName On #MaterialInfo (PlantName)
    Create Index IX_MaterialInfo_ItemCode On #MaterialInfo (ItemCode)
    Create Index IX_MaterialInfo_PlantID On #MaterialInfo (PlantID)
    Create Index IX_MaterialInfo_MaterialID On #MaterialInfo (MaterialID)
    Create Index IX_MaterialInfo_MaterialCode On #MaterialInfo (MaterialCode)
    Create Index IX_MaterialInfo_FamilyMaterialTypeID On #MaterialInfo (FamilyMaterialTypeID)
    
    Begin try
		Begin Transaction
		
		If Exists (Select * From Sys.databases As Databases Where Databases.name = 'Data_Import_RJ')
		Begin
		    If	Exists(Select * From Data_Import_RJ.sys.objects Where Name = 'TestImport0000_MixInfo')
		    Begin
		    	
		    	Exec dbo.Utility_DisplayConsoleMessage 'Import Mixes'
		    	
		    	
		    	Exec dbo.Utility_DisplayConsoleMessage 'Retrieve Batch Plant Materials'
		    	
		    	Insert Into #MaterialInfo
		    	(
		    	    PlantName,
		    	    ItemCode,
		    	    SpecificGravity,
		    	    Moisture,
		    	    PlantID,
		    	    MaterialID,
		    	    MaterialCode,
		    	    FamilyMaterialTypeID
		    	)
		    	Select	Plant.PLNTNAME,
		    			ItemName.Name,
		    			Material.SPECGR,
		    			IsNull(Material.MOISTURE, 0.0),
		    			Plant.PLANTIDENTIFIER,
		    			Material.MATERIALIDENTIFIER,
		    			Material.CODE,
		    			Material.FamilyMaterialTypeID
		    	From dbo.PLANT As Plant
		    	Inner Join dbo.MATERIAL As Material
		    	On Material.PlantID = Plant.PLANTIDENTIFIER
		    	Inner Join dbo.ItemMaster As ItemMaster
		    	On ItemMaster.ItemMasterID = Material.ItemMasterID
		    	Inner Join dbo.Name As ItemName
		    	On ItemName.NameID = ItemMaster.NameID
		    	Inner Join
		    	(
		    		Select	Max(Material.MATERIALIDENTIFIER) As MATERIALIDENTIFIER
		    		From dbo.MATERIAL As Material
		    		Where   (
		    			        Isnull(@AllowedToAddInactiveMaterials, 0) = 1 Or
		    			        Isnull(@AllowedToAddInactiveMaterials, 0) = 0 And 
		    			        Isnull(Material.Inactive, 0) = 0
		    		        ) And
		    		        Isnull(Material.NotAllowedInMixAndBatchRecipes, 0) = 0 And
		    		        Isnull(Material.OnlyAllowedInImportedBatchRecipes, 0) = 0
		    		Group By Material.PlantID, Material.ItemMasterID
		    	) As SelMaterial
		    	On Material.MATERIALIDENTIFIER = SelMaterial.MATERIALIDENTIFIER
		    	Where Plant.PlantKind = 'BatchPlant'
		    	Order By	Material.FamilyMaterialTypeID,
		    				Plant.PLANTIDENTIFIER,
		    				ItemName.Name

		    	
		    	Exec dbo.Utility_DisplayConsoleMessage 'Retrieve Concrete Yard Materials'
		    	
		    	Insert Into #MaterialInfo
		    	(
		    	    PlantName,
		    	    ItemCode,
		    	    SpecificGravity,
		    	    Moisture,
		    	    PlantID,
		    	    MaterialID,
		    	    MaterialCode,
		    	    FamilyMaterialTypeID
		    	)
		    	Select	Plant.PLNTNAME,
		    			ItemName.Name,
		    			Material.SPECGR,
		    			IsNull(Material.MOISTURE, 0.0),
		    			Plant.PLANTIDENTIFIER,
		    			Material.MATERIALIDENTIFIER,
		    			Material.CODE,
		    			Material.FamilyMaterialTypeID
		    	From dbo.PLANT As Yard		    	 
		    	Inner Join dbo.MATERIAL As Material
		    	On Material.PlantID = Yard.PLANTIDENTIFIER
		    	Inner Join dbo.PLANT As Plant
		    	On Yard.PLANTIDENTIFIER = Plant.PlantIDForYard
		    	Inner Join dbo.ItemMaster As ItemMaster
		    	On ItemMaster.ItemMasterID = Material.ItemMasterID
		    	Inner Join dbo.Name As ItemName
		    	On ItemName.NameID = ItemMaster.NameID
		    	Inner Join
		    	(
		    		Select	Max(Material.MATERIALIDENTIFIER) As MATERIALIDENTIFIER
		    		From dbo.MATERIAL As Material
		    		Where   (
		    			        Isnull(@AllowedToAddInactiveMaterials, 0) = 1 Or
		    			        Isnull(@AllowedToAddInactiveMaterials, 0) = 0 And 
		    			        Isnull(Material.Inactive, 0) = 0
		    		        ) And
		    		        Isnull(Material.NotAllowedInMixAndBatchRecipes, 0) = 0 And
		    		        Isnull(Material.OnlyAllowedInImportedBatchRecipes, 0) = 0
		    		Group By Material.PlantID, Material.ItemMasterID
		    	) As SelMaterial
		    	On Material.MATERIALIDENTIFIER = SelMaterial.MATERIALIDENTIFIER
		    	Where Plant.PlantKind = 'BatchPlant'
		    	Order By	Material.FamilyMaterialTypeID,
		    				Plant.PLANTIDENTIFIER,
		    				ItemName.Name
		    			    	
		    	
		    	Exec dbo.Utility_DisplayConsoleMessage 'Set Up Date, Time, Code, And Mix Name Code Info'
		    	
				Set @MixTimeStamp = GetDate()

                If dbo.GetDBSetting_GlobalDateFormat(Default) = 'DD/MM/YYYY'
                Begin
				    Set @MixDate =  Right('00' + LTrim(RTrim(Cast(Day(@MixTimeStamp) As NVarChar))), 2) + '/' +
								    Right('00' + LTrim(RTrim(Cast(Month(@MixTimeStamp) As NVarChar))), 2) + '/' +
								    Right('0000' + LTrim(RTrim(Cast(Year(@MixTimeStamp) As NVarChar))), 4)
                End
                Else
                Begin

					Set @MixDate =  Right('00' + LTrim(RTrim(Cast(Month(@MixTimeStamp) As NVarChar))), 2) + '/' +
									Right('00' + LTrim(RTrim(Cast(Day(@MixTimeStamp) As NVarChar))), 2) + '/' +
									Right('0000' + LTrim(RTrim(Cast(Year(@MixTimeStamp) As NVarChar))), 4)
                End
		                        
				Set @MixTime =  Right('00' + LTrim(RTrim(Cast(DatePart(hour, @MixTimeStamp) As NVarChar))), 2) + ':' +
								Right('00' + LTrim(RTrim(Cast(DatePart(minute, @MixTimeStamp) As NVarChar))), 2)
                        
				Set @AggregatesInYards = IsNull(dbo.GetAggregatesInYards(), 0)
				
				Set @CodeDate =	Right('00' + Cast(Year(@MixTimeStamp) As Nvarchar), 2) +
								Right('00' + Cast(Month(@MixTimeStamp) As Nvarchar), 2) +
								Right('00' + Cast(Day(@MixTimeStamp) As Nvarchar), 2)
								
				Set @CodeSuffix = Null				
				Set @CodeSuffix = (Select Max(Cast(Right(Batch.Code, 5) + 1 As Int)) From dbo.Batch As Batch Where Substring(Batch.CODE, 2, 6) = @CodeDate)
				
				If @CodeSuffix Is Null
				Begin
				    Set @CodeSuffix = 0
				End				 
								
				Set @MixNameCode = Null
				
				Set @MixNameCode = 
					(
						Select Max(Mix.MixNameCode) 
						From dbo.BATCH As Mix 
						Where	Mix.Mix = 'y' And 
								Len(Mix.MixNameCode) = (Select Max(Len(Mix.MixNameCode)) From dbo.Batch As Mix Where Mix.Mix = 'y')
					)
					
				Set @MixNameCode = Ltrim(Rtrim(Isnull(@MixNameCode, '')))
				
				If @MixNameCode = ''
				Begin
				    Set @MixNameCode = 'AAAA'
				End 
				Else
				Begin
				    Set @MixNameCode = dbo.GetBase26NumberFromBase10Number(dbo.GetBase10NumberFromBase26Number(@MixNameCode) + 1)
				    
				    If Len(@MixNameCode) < 4
				    Begin
				        Set @MixNameCode = Right(Replicate('A', 4) + @MixNameCode, 4)
				    End
				End
				
				
				Exec dbo.Utility_DisplayConsoleMessage 'Format Mix Information To Be Imported'
				
		        Update MixInfo
			        Set MixInfo.PlantCode = LTrim(RTrim(Replace(MixInfo.PlantCode, Char(160), ' '))),
				        MixInfo.MixCode = LTrim(RTrim(Replace(MixInfo.MixCode, Char(160), ' '))),
				        MixInfo.MixDescription = LTrim(RTrim(Replace(MixInfo.MixDescription, Char(160), ' '))),
				        MixInfo.MixShortDescription = LTrim(RTrim(Replace(MixInfo.MixShortDescription, Char(160), ' '))),
				        MixInfo.ItemCategory = LTrim(RTrim(Replace(MixInfo.ItemCategory, Char(160), ' '))),
				        MixInfo.DispatchSlumpRange = LTrim(RTrim(Replace(MixInfo.DispatchSlumpRange, Char(160), ' '))),
		                MixInfo.MixClassNames = LTrim(RTrim(Replace(MixInfo.MixClassNames, Char(160), ' '))),
		                MixInfo.MixUsage = LTrim(RTrim(Replace(MixInfo.MixUsage, Char(160), ' '))),
		                MixInfo.AttachmentFileNames = LTrim(RTrim(Replace(MixInfo.AttachmentFileNames, Char(160), ' '))),
				        MixInfo.PriceUnitName = LTrim(RTrim(Replace(MixInfo.PriceUnitName, Char(160), ' '))),
				        MixInfo.MixInactive = LTrim(RTrim(Replace(MixInfo.MixInactive, Char(160), ' '))),
				        MixInfo.Padding1 = LTrim(RTrim(Replace(MixInfo.Padding1, Char(160), ' '))),
				        MixInfo.MaterialItemCode = LTrim(RTrim(Replace(MixInfo.MaterialItemCode, Char(160), ' '))),
				        MixInfo.MaterialItemDescription = LTrim(RTrim(Replace(MixInfo.MaterialItemDescription, Char(160), ' '))),
				        MixInfo.QuantityUnitName = LTrim(RTrim(Replace(MixInfo.QuantityUnitName, Char(160), ' ')))
		        From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo

                If Isnull(@AllowedToOverwriteMixes, 1) = 0
                Begin
                	Exec dbo.Utility_DisplayConsoleMessage 'Retrieve Existing Mixes'
                	
                    Insert into @ExistingMix (PlantCode, MixCode)
					    Select MixRecipe.PlantCode, MixRecipe.MixCode
					    From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixRecipe
					    Inner Join dbo.Plants As Plants
					    On MixRecipe.PlantCode = Plants.Name
					    Inner Join dbo.Name As MixName
					    On MixRecipe.MixCode = MixName.Name
					    Inner Join dbo.BATCH As Mix
					    On  Plants.PlantId = Mix.Plant_Link And
					        MixName.NameID = Mix.NameID
					    Group By MixRecipe.PlantCode, MixRecipe.MixCode
                End
                
				
				Exec dbo.Utility_DisplayConsoleMessage 'Retrieve Mixes With Cementitious Quantities'
				
                Insert into @CementitiousMix (PlantCode, MixCode)
					Select MixRecipe.PlantCode, MixRecipe.MixCode
					From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixRecipe
					Inner Join #MaterialInfo As MaterialInfo
					On	MixRecipe.PlantCode = MaterialInfo.PlantName And
						MixRecipe.MaterialItemCode = MaterialInfo.ItemCode
					Where MaterialInfo.FamilyMaterialTypeID In (2, 4)
					Group By MixRecipe.PlantCode, MixRecipe.MixCode
					Having Round(Sum(MixRecipe.Quantity), 2) > 0.0


				Exec dbo.Utility_DisplayConsoleMessage 'Retrieve Mixes With Cement Quantities'
				
                Insert into @CementMix (PlantCode, MixCode)
					Select MixRecipe.PlantCode, MixRecipe.MixCode
					From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixRecipe
					Inner Join #MaterialInfo As MaterialInfo
					On	MixRecipe.PlantCode = MaterialInfo.PlantName And
						MixRecipe.MaterialItemCode = MaterialInfo.ItemCode
					Where MaterialInfo.FamilyMaterialTypeID In (2)
					Group By MixRecipe.PlantCode, MixRecipe.MixCode
					Having Round(Sum(MixRecipe.Quantity), 2) > 0.0
				
				Exec dbo.Utility_DisplayConsoleMessage 'Retrieve Mixes With Admixtures'
				
                Insert into @AdmixtureMix (PlantCode, MixCode)
					Select MixRecipe.PlantCode, MixRecipe.MixCode
					From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixRecipe
					Inner Join #MaterialInfo As MaterialInfo
					On	MixRecipe.PlantCode = MaterialInfo.PlantName And
						MixRecipe.MaterialItemCode = MaterialInfo.ItemCode
					Where MaterialInfo.FamilyMaterialTypeID In (3)
					Group By MixRecipe.PlantCode, MixRecipe.MixCode
                

				Exec dbo.Utility_DisplayConsoleMessage 'Retrieve Mixes That Must Have A Cement Quantity'
				
                Insert into @NeedsCementMix (PlantCode, MixCode)
					Select MixRecipe.PlantCode, MixRecipe.MixCode
					From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixRecipe
					Inner Join #MaterialInfo As MaterialInfo
					On	MixRecipe.PlantCode = MaterialInfo.PlantName And
						MixRecipe.MaterialItemCode = MaterialInfo.ItemCode
					Where   MaterialInfo.FamilyMaterialTypeID In (3) And
					        MixRecipe.QuantityUnitName In ('oz/cwt C') 
					Group By MixRecipe.PlantCode, MixRecipe.MixCode
				
				Exec dbo.Utility_DisplayConsoleMessage 'Retrieve Mixes With Multiple Material With The Same Item Code'
				
                Insert into @MultiMaterial (PlantCode, MixCode)
                    Select MultiMaterial.PlantCode, MultiMaterial.MixCode
                    From 
                    (
					    Select MixInfo.PlantCode, MixInfo.MixCode
					    From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
					    Group By MixInfo.PlantCode, MixInfo.MixCode, MixInfo.MaterialItemCode
					    Having Count(*) > 1
                    ) As MultiMaterial
                    Group By MultiMaterial.PlantCode, MultiMaterial.MixCode
                             
				
				Exec dbo.Utility_DisplayConsoleMessage 'Retrieve Mixes With Missing Materials'
				
                Insert into @MissingMaterial (PlantCode, MixCode)
					Select MixInfo.PlantCode, MixInfo.MixCode
					From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
					Left Join #MaterialInfo As MaterialInfo
					On	MixInfo.PlantCode = MaterialInfo.PlantName And
						MixInfo.MaterialItemCode = MaterialInfo.ItemCode
					Where	MaterialInfo.AutoID Is Null
					Group By MixInfo.PlantCode, MixInfo.MixCode

				
				Exec dbo.Utility_DisplayConsoleMessage 'Retrieve Mix Auto ID Information Of Mixes That May Be Imported'
					
				Insert into @MixAutoIDInfo (MixAutoID)
					Select Min(MixInfo.AutoID)
					From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
					Inner Join dbo.Plant As Plant
					On MixInfo.PlantCode = Plant.PLNTNAME
					Left Join @ExistingMix As ExistingMix
					On  MixInfo.PlantCode = ExistingMix.PlantCode And
					    MixInfo.MixCode = ExistingMix.MixCode
					Left Join @CementitiousMix As CementitiousMix
					On	MixInfo.PlantCode = CementitiousMix.PlantCode And
						MixInfo.MixCode = CementitiousMix.MixCode
					Left Join @CementMix As CementMix
					On	MixInfo.PlantCode = CementMix.PlantCode And
						MixInfo.MixCode = CementMix.MixCode							
					Left Join @NeedsCementMix As NeedsCementMix
					On	MixInfo.PlantCode = NeedsCementMix.PlantCode And
						MixInfo.MixCode = NeedsCementMix.MixCode										
					Left Join @AdmixtureMix As AdmixtureMix
					On	MixInfo.PlantCode = AdmixtureMix.PlantCode And
						MixInfo.MixCode = AdmixtureMix.MixCode
					Left Join @MultiMaterial As MultiMaterial
					On	MixInfo.PlantCode = MultiMaterial.PlantCode And
						MixInfo.MixCode = MultiMaterial.MixCode
					Left Join @MissingMaterial As MissingMaterial
					On	MixInfo.PlantCode = MissingMaterial.PlantCode And
						MixInfo.MixCode = MissingMaterial.MixCode
					Where	IsNull(MixInfo.MixCode, '') <> '' And		
					        ExistingMix.AutoID Is Null And							
							MultiMaterial.AutoID Is Null And
							MissingMaterial.AutoID Is Null And
							(
								AdmixtureMix.AutoID Is Null Or
								AdmixtureMix.AutoID Is Not null And
								CementitiousMix.AutoID Is Not null
							) And
							(
								NeedsCementMix.AutoID Is Null Or
								NeedsCementMix.AutoID Is Not null And
								CementMix.AutoID Is Not Null
							)
					Group By	MixInfo.PlantCode,
								MixInfo.MixCode

				
				Exec dbo.Utility_DisplayConsoleMessage 'Retrieve Mix Import Information'
				
				Insert Into #MixInfo
				(
				    MixID,
				    ActualMixID,
				    MixCode,
				    MixNameCode,
				    MixSpecID,
				    PlantName,
				    MixName,
				    [Description],
				    ShortDescription,
				    ItemCategory,
				    MixClassNames, 
				    MixUsage,
				    AttachmentFileNames,
				    StrengthAge,
				    Strength,
				    AirContent,
				    MinAirContent,
				    MaxAirContent,
				    Slump,
				    MinSlump,
				    MaxSlump,
				    DispatchSlumpRange,
				    MinAggregateSize, 
				    MaxAggregateSize, 
				    MinUnitWeight, 
				    MaxUnitWeight, 
				    MinWCRatio, 
				    MaxWCRatio, 
				    MinWCMRatio, 
				    MaxWCMRatio,
				    MaxLoadSize, 
				    MaxWater,
				    SackContent, 
				    Price,
				    PriceUnitName,
				    MixInactive
				)
				Select  MixInfo.AutoID,
				        Mix.BATCHIDENTIFIER,
				        Mix.CODE,
				        Mix.MixNameCode,
				        Mix.MixSpecID,
				        MixInfo.PlantCode,
				        MixInfo.MixCode,
				        MixInfo.MixDescription,
				        MixInfo.MixShortDescription,
				        MixInfo.ItemCategory,
				        MixInfo.MixClassNames, 
				        MixInfo.MixUsage,
				        MixInfo.AttachmentFileNames,				        
				        Case 
							When Round(Isnull(MixInfo.Strength, -1.0), 2) <= 0.0
							Then Null
							When	Round(Isnull(MixInfo.Strength, -1.0), 2) > 0.0 And
									Round(Isnull(MixInfo.StrengthAge, -1.0), 2) <= 0.0
							Then 28.0
							Else MixInfo.StrengthAge
						End,
						Case
							When Round(Isnull(MixInfo.Strength, -1.0), 2) <= 0.0
							Then Null
							Else MixInfo.Strength
						End,
				        MixInfo.AirContent,
				        MixInfo.MinAirContent,
				        MixInfo.MaxAirContent,
				        MixInfo.Slump,
				        MixInfo.MinSlump,
				        MixInfo.MaxSlump,
				        MixInfo.DispatchSlumpRange,
				        MixInfo.MinAggregateSize, 
				        MixInfo.MaxAggregateSize,
				        MixInfo.MinUnitWeight,
				        MixInfo.MaxUnitWeight,
				        MixInfo.MinWCRatio, 
				        MixInfo.MaxWCRatio,
				        MixInfo.MinWCMRatio, 
				        MixInfo.MaxWCMRatio,
				        MixInfo.MaxLoadSize, 
				        MixInfo.MaximumWater,
				        MixInfo.SackContent, 
				        MixInfo.Price,
				        MixInfo.PriceUnitName, 
				        MixInfo.MixInactive
				From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
				Inner Join @MixAutoIDInfo As MixAutoIDInfo
				On MixInfo.AutoID = MixAutoIDInfo.MixAutoID
				Inner Join dbo.Plants As Plants
				On MixInfo.PlantCode = Plants.Name
				Left Join dbo.Name As MixName
				On MixInfo.MixCode = MixName.Name
				Left Join dbo.Batch As Mix
				On  Plants.PlantId = Mix.Plant_Link And
				    Mix.NameID = MixName.NameID
						
				
				Exec dbo.Utility_DisplayConsoleMessage 'Retrieve Mix Recipe Information'
						
		        Insert Into #MixRecipeInfo
		        (
		            MixID,
		            PlantName,
		            MixName,
		            MaterialItemCode,
		            Quantity,
		            QuantityUnit,
		            PlantID,
		            MaterialID,
		            MaterialCode,
		            FamilyMaterialTypeID,
		            SpecificGravity,
					MaterialMoisture
		        )
		        Select  MixInfo.MixID,
						MixRecipe.PlantCode, 
						MixRecipe.MixCode,
						MixRecipe.MaterialItemCode,
						MixRecipe.Quantity, 
						MixRecipe.QuantityUnitName,
						MaterialInfo.PlantID,
						MaterialInfo.MaterialID, 
						MaterialInfo.MaterialCode,
						MaterialInfo.FamilyMaterialTypeID,
						MaterialInfo.SpecificGravity,
						MaterialInfo.Moisture
				From #MixInfo As MixInfo
				Inner Join Data_Import_RJ.dbo.TestImport0000_MixInfo As MixRecipe
				On	MixInfo.PlantName = MixRecipe.PlantCode And
					MixInfo.MixName = MixRecipe.MixCode
				Inner Join #MaterialInfo As MaterialInfo
				On	MixRecipe.PlantCode = MaterialInfo.PlantName And
					MixRecipe.MaterialItemCode = MaterialInfo.ItemCode
		                
				
				Exec dbo.Utility_DisplayConsoleMessage 'Convert Recipe Quantities From LBs to Kgs'
				
		        Update MixRecipeInfo 
					Set MixRecipeInfo.ConvertedQuantity = MixRecipeInfo.Quantity * 0.45359240000781
		        From #MixRecipeInfo As MixRecipeInfo
		        Where	MixRecipeInfo.QuantityUnit In ('LB', 'Pounds') Or
						MixRecipeInfo.QuantityUnit In ('Per Cubic Yard') And (MixRecipeInfo.FamilyMaterialTypeID <> 3 Or MixRecipeInfo.MaterialMoisture = 0.0)

		        Exec dbo.Utility_DisplayConsoleMessage 'Set Recipe Quantities in Kgs'
		        
		        Update MixRecipeInfo 
					Set MixRecipeInfo.ConvertedQuantity = MixRecipeInfo.Quantity
		        From #MixRecipeInfo As MixRecipeInfo
		        Where MixRecipeInfo.QuantityUnit In ('KG', 'Kilograms')

		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Convert Recipe Quantities From Ozs to Kgs'
		        
		        Update MixRecipeInfo 
					Set MixRecipeInfo.ConvertedQuantity = MixRecipeInfo.Quantity * MixRecipeInfo.SpecificGravity * 0.0651984837440621 * 0.45359240000781
		        From #MixRecipeInfo As MixRecipeInfo
		        Where	MixRecipeInfo.QuantityUnit In ('LQ OZ', 'OZ', 'Ounces', 'Fluid Oz', 'fl oz', 'FO') Or
						MixRecipeInfo.QuantityUnit In ('Per Cubic Yard') And MixRecipeInfo.FamilyMaterialTypeID = 3 And MixRecipeInfo.MaterialMoisture > 0.0
				
		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Convert Recipe Quantities From Yd^3 to Kgs'
		        
		        Update MixRecipeInfo 
					Set MixRecipeInfo.ConvertedQuantity = MixRecipeInfo.Quantity * 201.974026 * MixRecipeInfo.SpecificGravity * 1.0 / 0.26417205
		        From #MixRecipeInfo As MixRecipeInfo
		        Where MixRecipeInfo.QuantityUnit In ('CYD', 'Cubic Yards', 'CY')
				
		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Convert Recipe Quantities From Gallons to Kgs'
		        
		        Update MixRecipeInfo 
					Set MixRecipeInfo.ConvertedQuantity = MixRecipeInfo.Quantity * MixRecipeInfo.SpecificGravity * 1.0 / 0.26417205
		        From #MixRecipeInfo As MixRecipeInfo
		        Where MixRecipeInfo.QuantityUnit In ('GL', 'GA', 'GAL', 'Gallons')

		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Convert Recipe Quantities From Oz/CWt CM to Kgs'
		        
		        Update MixRecipeInfo 
					Set MixRecipeInfo.ConvertedQuantity = MixRecipeInfo.Quantity * MixRecipeInfo.SpecificGravity * 0.0651984837440621 * CementitiousInfo.TotalQuantity / 100.0
		        From #MixRecipeInfo As MixRecipeInfo
		        Inner Join
		        (
		        	Select MixRecipeInfo.MixID, Sum(Isnull(MixRecipeInfo.ConvertedQuantity, 0.0)) As TotalQuantity
		        	From #MixRecipeInfo As MixRecipeInfo
		        	Where MixRecipeInfo.FamilyMaterialTypeID In (2, 4)
		        	Group By MixRecipeInfo.MixID
		        	Having Round(Sum(Isnull(MixRecipeInfo.ConvertedQuantity, 0.0)), 2) > 0.0
		        ) As CementitiousInfo
		        On MixRecipeInfo.MixID = CementitiousInfo.MixID
		        Where MixRecipeInfo.QuantityUnit In ('CW', 'oz/cwt CM', 'OZ/CWT')
				
				--dblMlCKgCPs * dblSpecGrav * DensWater4CGmPerMl * dblCementitiousWt / (CDbl(1000) * 100)


		        Exec dbo.Utility_DisplayConsoleMessage 'Convert Recipe Quantities From Ml/CKg CM to Kgs'

		        Update MixRecipeInfo 
					Set MixRecipeInfo.ConvertedQuantity = MixRecipeInfo.Quantity * MixRecipeInfo.SpecificGravity * 1.0 * CementitiousInfo.TotalQuantity / (1000.0 * 100.0)
		        From #MixRecipeInfo As MixRecipeInfo
		        Inner Join
		        (
		        	Select MixRecipeInfo.MixID, Sum(Isnull(MixRecipeInfo.ConvertedQuantity, 0.0)) As TotalQuantity
		        	From #MixRecipeInfo As MixRecipeInfo
		        	Where MixRecipeInfo.FamilyMaterialTypeID In (2, 4)
		        	Group By MixRecipeInfo.MixID
		        	Having Round(Sum(Isnull(MixRecipeInfo.ConvertedQuantity, 0.0)), 2) > 0.0
		        ) As CementitiousInfo
		        On MixRecipeInfo.MixID = CementitiousInfo.MixID
		        Where MixRecipeInfo.QuantityUnit In ('ML/CKg CM', 'ML/CKg', 'ml/100kg', 'ML/100KG CM')


		        Exec dbo.Utility_DisplayConsoleMessage 'Convert Recipe Quantities From Oz/CWt C to Kgs'
		        
		        Update MixRecipeInfo 
					Set MixRecipeInfo.ConvertedQuantity = MixRecipeInfo.Quantity * MixRecipeInfo.SpecificGravity * 0.0651984837440621 * CementInfo.TotalQuantity / 100.0
		        From #MixRecipeInfo As MixRecipeInfo
		        Inner Join
		        (
		        	Select MixRecipeInfo.MixID, Sum(Isnull(MixRecipeInfo.ConvertedQuantity, 0.0)) As TotalQuantity
		        	From #MixRecipeInfo As MixRecipeInfo
		        	Where MixRecipeInfo.FamilyMaterialTypeID In (2)
		        	Group By MixRecipeInfo.MixID
		        	Having Round(Sum(Isnull(MixRecipeInfo.ConvertedQuantity, 0.0)), 2) > 0.0
		        ) As CementInfo
		        On MixRecipeInfo.MixID = CementInfo.MixID
		        Where MixRecipeInfo.QuantityUnit In ('oz/cwt C')
		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Convert Recipe Quantities From Grams to Kgs'

		        Update MixRecipeInfo 
					Set MixRecipeInfo.ConvertedQuantity = MixRecipeInfo.Quantity / 1000.0
		        From #MixRecipeInfo As MixRecipeInfo
		        Where MixRecipeInfo.QuantityUnit = 'GR'

		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Convert Recipe Quantities From L to Kgs'
		        
		        Update MixRecipeInfo 
					Set MixRecipeInfo.ConvertedQuantity = MixRecipeInfo.Quantity * MixRecipeInfo.SpecificGravity * 1.0
		        From #MixRecipeInfo As MixRecipeInfo
		        Where MixRecipeInfo.QuantityUnit In ('L', 'LT', 'LI', 'Liters', 'Litre')

		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Convert Recipe Quantities From Ml to Kgs'
		        
		        Update MixRecipeInfo 
					Set MixRecipeInfo.ConvertedQuantity = MixRecipeInfo.Quantity * MixRecipeInfo.SpecificGravity * 1.0 / 1000.0
		        From #MixRecipeInfo As MixRecipeInfo
		        Where MixRecipeInfo.QuantityUnit In ('ML', 'Ml-liter', 'ml/m3', 'Milliliters')

		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Convert Recipe Quantities From CM^3 to Kgs'

		        Update MixRecipeInfo 
					Set MixRecipeInfo.ConvertedQuantity = MixRecipeInfo.Quantity * MixRecipeInfo.SpecificGravity * 1.0 / 1000.0
		        From #MixRecipeInfo As MixRecipeInfo
		        Where MixRecipeInfo.QuantityUnit In ('CC')



		        Exec dbo.Utility_DisplayConsoleMessage 'Treat Units Of Bags And Dosages As Ozs And Convert Recipe Quantities From Ozs to Kgs'
		        
		        Update MixRecipeInfo 
					Set MixRecipeInfo.ConvertedQuantity = MixRecipeInfo.Quantity * MixRecipeInfo.SpecificGravity * 0.0651984837440621 * 0.45359240000781
		        From #MixRecipeInfo As MixRecipeInfo
		        Where MixRecipeInfo.QuantityUnit In ('DS', 'BG', 'BAG', 'BAGS')
				
				Exec dbo.Utility_DisplayConsoleMessage 'Treat Units Of Each As Lbs And Convert Recipe Quantities From LBs to Kgs'
				
		        Update MixRecipeInfo 
					Set MixRecipeInfo.ConvertedQuantity = MixRecipeInfo.Quantity * 0.45359240000781
		        From #MixRecipeInfo As MixRecipeInfo
		        Where MixRecipeInfo.QuantityUnit In ('Each', 'EA')
				
                /*
		        Exec dbo.Utility_DisplayConsoleMessage 'Set Recipe Quantities in Kgs (Units are Each or Bag)'
		        
		        Update MixRecipeInfo 
					Set MixRecipeInfo.ConvertedQuantity = MixRecipeInfo.Quantity
		        From #MixRecipeInfo As MixRecipeInfo
		        Where MixRecipeInfo.QuantityUnit In ('Each', 'Bag', 'EA')
                */
		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Link Mixes To Mix Name Codes'
		        
		        Update MixInfo
					Set MixInfo.MixNameCode = MixNameCodeList.MixNameCode
		        From #MixInfo As MixInfo
		        Inner Join
		        (
		        	Select  MixInfo.AutoID, Row_number() Over (Order By MixInfo.AutoID) As RowNumber
		        	From #MixInfo As MixInfo
		        	Where MixInfo.ActualMixID Is Null
		        ) As RowNumberInfo
		        On MixInfo.AutoID = RowNumberInfo.AutoID
		        Inner Join dbo.GetMixNameCodeList(Isnull((Select Count(*) From #MixInfo As MixInfo Where MixInfo.ActualMixID Is Null), 0), @MixNameCode, 4) As MixNameCodeList
		        On RowNumberInfo.RowNumber = MixNameCodeList.AutoID
		        Where MixInfo.ActualMixID Is Null
		        
		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Link Mixes To Codes'
		        
		        Update MixInfo
					Set MixInfo.MixCode = 'B' + @CodeDate + Right('00000' + Cast(@CodeSuffix + RowNumberInfo.RowNumber - 1 As Nvarchar), 5)										
		        From #MixInfo As MixInfo
		        Inner Join
		        (
		        	Select  MixInfo.AutoID, Row_number() Over (Order By MixInfo.AutoID) As RowNumber
		        	From #MixInfo As MixInfo
		        	Where MixInfo.ActualMixID Is Null
		        ) As RowNumberInfo
		        On MixInfo.AutoID = RowNumberInfo.AutoID
		        
		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Set Up Spreads From Slumps'
		        
		        Update MixInfo
					Set MixInfo.Spread = MixInfo.Slump,
						MixInfo.MinSpread = MixInfo.MinSlump,
						MixInfo.MaxSpread = MixInfo.MaxSlump
		        From #MixInfo As MixInfo
		        Where	Isnull(MixInfo.Slump, -1.0) > 12.0 Or
						Isnull(MixInfo.MinSlump, -1.0) > 12.0 Or
						Isnull(MixInfo.MaxSlump, -1.0) > 12.0

		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Clear Out Slumps With Spreads'
		        
		        Update MixInfo
					Set MixInfo.Slump = Null,
						MixInfo.MinSlump = Null,
						MixInfo.MaxSlump = Null
		        From #MixInfo As MixInfo
		        Where	Isnull(MixInfo.Spread, -1.0) >= 0.0 Or
						Isnull(MixInfo.MinSpread, -1.0) >= 0.0 Or
						Isnull(MixInfo.MaxSpread, -1.0) >= 0.0
		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Retrieve and add Attachment File Names and Mix Class Names'
		        
		        Set @Index = 1
		        Set @MaxIndex = Isnull((Select Max(MixInfo.AutoID) From #MixInfo As MixInfo), 0)
		        
		        While @Index <= @MaxIndex
		        Begin
		        	Select  @MixAutoID = MixInfo.AutoID,
		        	        @AttachmentNames = IsNull(MixInfo.AttachmentFileNames, ''),
		        	        @MixClassNames = IsNull(MixInfo.MixClassNames, '')
		        	From #MixInfo As MixInfo
		        	Where MixInfo.AutoID = @Index
		        	
		        	If @AttachmentNames <> ''
		        	Begin
		        	    Insert into @AttachmentInfo (MixAutoID, AttachmentName)
		        	        Select @MixAutoID, AttachmentInfo.[Value]
		        	        From dbo.GetUnicodeValueListFromStringValue(@AttachmentNames, ':', Default, Default, Default, Default, Default, Default) As AttachmentInfo
		        	        Group By AttachmentInfo.[Value]
		        	        Order By AttachmentInfo.[Value]
		        	End
		        	
		        	If @MixClassNames <> ''
		        	Begin
		        	    Insert into @MixClassInfo (MixAutoID, MixClassName)
		        	        Select @MixAutoID, MixClassInfo.[Value]
		        	        From dbo.GetUnicodeValueListFromStringValue(@MixClassNames, ';', Default, Default, Default, Default, Default, Default) As MixClassInfo
		        	        Group By MixClassInfo.[Value]
		        	        Order By MixClassInfo.[Value]
		        	End
		        	
		            Set @Index = @Index + 1
		        End
		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Show Mixes'
		        
		        Select *
		        From #MixInfo As MixInfo
		        Order By MixInfo.AutoID
		        
		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Show Mixes That Might Be Created'
		        
		        Select 'Mixes That Might be Created', *
		        From #MixInfo As MixInfo
		        Where MixInfo.ActualMixID Is Null
		        Order By MixInfo.AutoID
		        
		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Show Mix Recipes'
		        
		        Select *
		        From #MixRecipeInfo As MixRecipeInfo
		        Order By MixRecipeInfo.AutoID

				
				Exec dbo.Utility_DisplayConsoleMessage 'Show Mix Recipes Without Material Links'
				
		        Select *
		        From #MixRecipeInfo As MixRecipeInfo
		        Where IsNull(MixRecipeInfo.MaterialCode, '') = ''
		        Order By MixRecipeInfo.AutoID
		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Show Attachments'
		        
		        Select *
		        From @AttachmentInfo As AttachmentInfo
		        Order By AttachmentInfo.AutoID
		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Show Mix Classes'
		        
		        Select *
		        From @MixClassInfo As MixClassInfo
		        Order By MixClassInfo.AutoID

		        --/*
		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Add New Mix Names'
		        
		        Insert into dbo.Name
		        (
		        	Name,
		        	NameType
		        )
		        Select MixNameInfo.MixName, 'MixItem'
		        From 
		        (
		        	Select MixInfo.MixName
		        	From #MixInfo As MixInfo
		        	Group By MixInfo.MixName
		        ) As MixNameInfo
		        Left Join dbo.Name As ExistingName
		        On MixNameInfo.MixName = ExistingName.Name
		        Where ExistingName.NameID Is Null
		        
		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Add New Descriptions'
		        
		        Insert into dbo.Description
		        (
		        	[Description], 
		        	DescriptionType
		        )
		        Select MixDescriptionInfo.Description, 'MixItem'
		        From 
		        (
		        	Select MixInfo.[Description] As Description
		        	From #MixInfo As MixInfo
		        	Where Isnull(MixInfo.Description, '') <> '' 
		        	Group By MixInfo.Description
		        ) As MixDescriptionInfo
		        Left Join dbo.[Description] As ExistingDescription
		        On MixDescriptionInfo.Description = ExistingDescription.[Description]
		        Where ExistingDescription.DescriptionID Is Null
		        
		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Add Production Item Categories'
		        
		        Insert into dbo.ProductionItemCategory
		        (
		        	ItemCategory,
		        	[Description],
		        	ShortDescription,
		        	ProdItemCatType
		        )
		        Select	MixInfo.ItemCategory,
						MixInfo.ItemCategory,
						MixInfo.ItemCategory,
						'Mix'
		        From #MixInfo As MixInfo
		        Left Join dbo.ProductionItemCategory As ItemCategoryInfo
		        On	MixInfo.ItemCategory = ItemCategoryInfo.ItemCategory And
					ItemCategoryInfo.ProdItemCatType = 'Mix'
		        Where	Isnull(MixInfo.ItemCategory, '') <> '' And
						ItemCategoryInfo.ProdItemCatID Is Null
		        Group By MixInfo.ItemCategory
		        
				Raiserror('', 0, 0) With Nowait
				Raiserror('Delete Production Items Not Linked To Materials Or Mixes.', 0, 0) With Nowait

				Delete ItemMaster
				From dbo.ItemMaster As ItemMaster
				Left Join dbo.Batch As Mix
				On Mix.ItemMasterID = ItemMaster.ItemMasterID
				Left Join dbo.MATERIAL As Material
				On Material.ItemMasterID = ItemMaster.ItemMasterID
				Where	Mix.BATCHIDENTIFIER Is Null And
						Material.MATERIALIDENTIFIER Is Null
				
				If Isnull(@UpdateExistingProdItems, 1) = 1
				Begin		
		            
		            Exec dbo.Utility_DisplayConsoleMessage 'Retrieve Mixes With Production Items That Were Modified'
		            
		            Insert into @MixProdInfo (MixID)
		                Select Mix.BATCHIDENTIFIER
		                From dbo.BATCH As Mix
		                Inner Join dbo.ItemMaster As ItemMaster
		                On ItemMaster.ItemMasterID = Mix.ItemMasterID
				        Inner Join dbo.Name As ItemName
				        On ItemName.NameID = ItemMaster.NameID
				        Inner Join #MixInfo As MixInfo
				        On ItemName.Name = MixInfo.MixName
				        Left Join dbo.[Description] As ExistingDescr
				        On ExistingDescr.DescriptionID = ItemMaster.DescriptionID
				        Left Join dbo.ProductionItemCategory As ExistingCategoryInfo
				        On ExistingCategoryInfo.ProdItemCatID = ItemMaster.ProdItemCatID
				        Left Join dbo.[Description] As ItemDescr
				        On  MixInfo.[Description] = ItemDescr.[Description] And
				            ItemDescr.DescriptionType In ('Mix', 'MixItem')
				        Left Join dbo.ProductionItemCategory As CategoryInfo
				        On  MixInfo.ItemCategory = CategoryInfo.ItemCategory And
				            CategoryInfo.ProdItemCatType = 'Mix'
				        Where   MixInfo.AutoID In				    
				                (
				        	        Select Min(MixInfo.AutoID)
				        	        From #MixInfo As MixInfo
				        	        Where Isnull(MixInfo.MixName, '') <> ''
				        	        Group By MixInfo.MixName
				                ) And
				                (
				                    Isnull(MixInfo.[Description], '') <> '' And
				                    --Isnull(ItemDescr.[Description], '') <> '' And
				                    Isnull(MixInfo.[Description], '') <> Isnull(ExistingDescr.[Description], '') Or
				                    Isnull(MixInfo.ShortDescription, '') <> '' And
				                    LTrim(RTrim(Left(Isnull(MixInfo.ShortDescription, ''), (Case when dbo.GetProductionSystem('') = 'Command' Then 16 Else 1000000 End)))) <> Isnull(ItemMaster.ItemShortDescription, '') Or
				                    Isnull(MixInfo.ItemCategory, '') <> '' And
				                    --Isnull(CategoryInfo.ItemCategory, '') <> '' And
				                    Isnull(MixInfo.ItemCategory, '') <> Isnull(ExistingCategoryInfo.ItemCategory, '') Or
				                    IsNull(MixInfo.DispatchSlumpRange, '') <> '' And
				                    Isnull(MixInfo.DispatchSlumpRange, '') <> IsNull(ItemMaster.DispatchSlumpRange, '')
				                )
		                Group By Mix.BATCHIDENTIFIER

		            
		            Exec dbo.Utility_DisplayConsoleMessage 'Update Existing Production Items That Changed'
		        
				    Update ItemMaster
				        Set ItemMaster.DescriptionID =
				                Case
				                    When ItemDescr.DescriptionID Is Not null
				                    Then ItemDescr.DescriptionID
				                    Else ItemMaster.DescriptionID
				                End,
				            ItemMaster.ItemShortDescription =    
				                Case
				                    When Isnull(MixInfo.ShortDescription, '') <> ''
				                    Then Ltrim(Rtrim(Left(MixInfo.ShortDescription, (Case when dbo.GetProductionSystem('') = 'Command' Then 16 Else 1000000 End))))
				                    When ItemDescr.DescriptionID Is Not null
				                    Then Ltrim(Rtrim(Left(ItemDescr.[Description], (Case when dbo.GetProductionSystem('') = 'Command' Then 16 Else 1000000 End))))
				                    Else ItemMaster.ItemShortDescription
				                End,
				            ItemMaster.ProdItemCatID =
				                Case
				                    When CategoryInfo.ProdItemCatID Is Not null
				                    Then CategoryInfo.ProdItemCatID
				                    Else ItemMaster.ProdItemCatID
				                End,
				            ItemMaster.DispatchSlumpRange =
				                Case
				                    When Isnull(MixInfo.DispatchSlumpRange, '') <> ''
				                    Then MixInfo.DispatchSlumpRange
				                    Else ItemMaster.DispatchSlumpRange
				                End
				    From dbo.ItemMaster As ItemMaster
				    Inner Join dbo.Name As ItemName
				    On ItemName.NameID = ItemMaster.NameID
				    Inner Join #MixInfo As MixInfo
				    On ItemName.Name = MixInfo.MixName
				    Left Join dbo.[Description] As ExistingDescr
				    On ExistingDescr.DescriptionID = ItemMaster.DescriptionID
				    Left Join dbo.ProductionItemCategory As ExistingCategoryInfo
				    On ExistingCategoryInfo.ProdItemCatID = ItemMaster.ProdItemCatID
				    Left Join dbo.[Description] As ItemDescr
				    On  MixInfo.[Description] = ItemDescr.[Description] And
				        ItemDescr.DescriptionType In ('Mix', 'MixItem')
				    Left Join dbo.ProductionItemCategory As CategoryInfo
				    On  MixInfo.ItemCategory = CategoryInfo.ItemCategory And
				        CategoryInfo.ProdItemCatType = 'Mix'
				    Where   MixInfo.AutoID In				    
				            (
				        	    Select Min(MixInfo.AutoID)
				        	    From #MixInfo As MixInfo
				        	    Where Isnull(MixInfo.MixName, '') <> ''
				        	    Group By MixInfo.MixName
				            ) And
				            (
				                Isnull(MixInfo.[Description], '') <> '' And
				                --Isnull(ItemDescr.[Description], '') <> '' And
				                Isnull(MixInfo.[Description], '') <> Isnull(ExistingDescr.[Description], '') Or
				                Isnull(MixInfo.ShortDescription, '') <> '' And
				                LTrim(RTrim(Left(Isnull(MixInfo.ShortDescription, ''), (Case when dbo.GetProductionSystem('') = 'Command' Then 16 Else 1000000 End)))) <> Isnull(ItemMaster.ItemShortDescription, '') Or
				                Isnull(MixInfo.ItemCategory, '') <> '' And
				                --Isnull(CategoryInfo.ItemCategory, '') <> '' And
				                Isnull(MixInfo.ItemCategory, '') <> Isnull(ExistingCategoryInfo.ItemCategory, '') Or
				                IsNull(MixInfo.DispatchSlumpRange, '') <> '' And
				                Isnull(MixInfo.DispatchSlumpRange, '') <> IsNull(ItemMaster.DispatchSlumpRange, '')
				            )
				            
		            
		            Exec dbo.Utility_DisplayConsoleMessage 'Update Production Statuses Of Mixes With Modified Production Items'
		            
				    Update Mix
				        Set Mix.ProductionStatus = Case when Isnull(Mix.ProductionStatus, '') In ('InSync', 'Sent') Then 'OutOfSync' Else Mix.ProductionStatus End
				    From dbo.BATCH As Mix
				    Inner Join @MixProdInfo As MixProdInfo
				    On Mix.BATCHIDENTIFIER = MixProdInfo.MixID
				End

		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Add New Production Items'
		        
		        Insert into dbo.ItemMaster
		        (
		        	NameID, 
		        	DescriptionID, 
		        	ItemShortDescription,
		        	ProdItemCatID, 
		        	DispatchSlumpRange,
		        	ItemType
		        )
		        Select	MixNameInfo.NameID,
						MixDescriptionInfo.DescriptionID,
						Case 
							When Isnull(ProdItem.ShortDescription, '') = ''
							Then LTrim(RTrim(Left(MixDescriptionInfo.[Description], (Case when dbo.GetProductionSystem('') = 'Command' Then 16 Else 1000000 End))))
							Else LTrim(RTrim(Left(ProdItem.ShortDescription, (Case when dbo.GetProductionSystem('') = 'Command' Then 16 Else 1000000 End))))
						End,
						ItemCategoryInfo.ProdItemCatID,
						Ltrim(Rtrim(Left(ProdItem.DispatchSlumpRange, 30))),
						'Mix'
		        From
		        (
		        	Select	MixInfo.MixName As MixName, 
		        			MixInfo.Description As Description, 
		        			MixInfo.ShortDescription As ShortDescription,
		        			MixInfo.ItemCategory As ItemCategory,
		        			MixInfo.DispatchSlumpRange
		        	From #MixInfo As MixInfo
		        	Where	MixInfo.AutoID In
		        			(
		        				Select Min(MixInfo.AutoID)
		        				From #MixInfo As MixInfo
		        				Group By MixInfo.MixName
		        			)
		        ) As ProdItem
		        Inner Join dbo.Name As MixNameInfo
		        On ProdItem.MixName = MixNameInfo.Name
		        Left Join dbo.[Description] As MixDescriptionInfo
		        On ProdItem.Description = MixDescriptionInfo.[Description]
		        Left Join dbo.ProductionItemCategory As ItemCategoryInfo
		        On  ProdItem.ItemCategory = ItemCategoryInfo.ItemCategory And
		            ItemCategoryInfo.ProdItemCatType = 'Mix'
		        Left Join dbo.ItemMaster As ItemMaster
		        On ItemMaster.NameID = MixNameInfo.NameID
		        Where ItemMaster.ItemMasterID Is Null

			    
			    Exec dbo.Utility_DisplayConsoleMessage 'Retrieve Specified Air Content And Slump And Spread Information.'
		
			    Update MixInfo
				    Set	MixInfo.SlumpDataPointID = SlumpSpec.SpecDataPointID,
					    MixInfo.SlumpMeasID = SlumpSpec.SpecMeasID,
					    MixInfo.AirDataPointID = AirSpec.SpecDataPointID,
					    MixInfo.AirMeasID = AirSpec.SpecMeasID,
					    MixInfo.SpreadDataPointID = SpreadSpec.SpecDataPointID,
					    MixInfo.SpreadMeasID = SpreadSpec.SpecMeasID,
					    MixInfo.AggSizeDataPointID = AggSizeSpec.SpecDataPointID,
					    MixInfo.AggSizeMeasID = AggSizeSpec.SpecMeasID,
					    MixInfo.UnitWeightDataPointID = UnitWeightSpec.SpecDataPointID,
					    MixInfo.UnitWeightMeasID = UnitWeightSpec.SpecMeasID
			    From #MixInfo As MixInfo
			    Left Join dbo.RptMixSpecAirContent As AirSpec
			    On MixInfo.MixSpecID = AirSpec.MixSpecID
			    Left Join dbo.RptMixSpecSlump As SlumpSpec
			    On MixInfo.MixSpecID = SlumpSpec.MixSpecID
			    Left Join dbo.RptMixSpecSpread As SpreadSpec
			    On MixInfo.MixSpecID = SpreadSpec.MixSpecID
			    Left Join dbo.RptMixSpecAggSize As AggSizeSpec
			    On MixInfo.MixSpecID = AggSizeSpec.MixSpecID
			    Left Join dbo.RptMixSpecUnitWeight As UnitWeightSpec
			    On MixInfo.MixSpecID = UnitWeightSpec.MixSpecID
			
			    
			    Exec dbo.Utility_DisplayConsoleMessage 'Retrieve Specified Strength Information.'
		
			    Update MixInfo
				    Set	MixInfo.StrengthDataPointID = StrengthSpec.SpecDataPointID,
					    MixInfo.StrengthAgeMeasID = StrengthSpec.AgeSpecMeasID,
					    MixInfo.StrengthMeasID = StrengthSpec.StrengthSpecMeasID
			    From #MixInfo As MixInfo
			    Inner Join dbo.RptMixSpecAgeComprStrengths As StrengthSpec
			    On	MixInfo.MixSpecID = StrengthSpec.MixSpecID And
				    Round(MixInfo.StrengthAge, 8) = Round(StrengthSpec.AgeMinValue, 8)
		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Retrieve W/C Ratio Information.'
		        
		        Update MixInfo
		            Set MixInfo.WCRatio1ID = WCRatio.MixMaterialRatioSpecID,
		                MixInfo.WCNumerator1ID = WCRatio.Numerator1ID,
		                MixInfo.WCDenominator1ID = WCRatio.Denominator1ID
		        From #MixInfo As MixInfo
		        Inner Join dbo.ViewMixSpecMtrlTypeRatio_WaterToCement As WCRatio
		        On WCRatio.MixSpecID = MixInfo.MixSpecID

		        Exec dbo.Utility_DisplayConsoleMessage 'Retrieve W/CM Ratio Information.'
		        
		        Update MixInfo
		            Set MixInfo.WCMRatio1ID = WCMRatio.MixMaterialRatioSpecID,
		                MixInfo.WCMNumerator1ID = WCMRatio.Numerator1ID,
		                MixInfo.WCMDenominator1ID = WCMRatio.Denominator1ID,
		                MixInfo.WCMDenominator2ID = WCMRatio.Denominator2ID
		        From #MixInfo As MixInfo
		        Inner Join dbo.ViewMixSpecMtrlTypeRatio_WaterToCementitious As WCMRatio
		        On WCMRatio.MixSpecID = MixInfo.MixSpecID
		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Add Mix Specifications'
		        
		        Set @LastID = Null		        
		        Set @LastID = (Select Max(MixSpec.MixSpecID) From dbo.MixSpec As MixSpec)
		        
		        Insert into dbo.MixSpec
		        (
		        	Name,
		        	[Description]
		        )
		        Select '', ''
		        From #MixInfo As MixInfo
		        Where MixInfo.MixSpecID Is Null
		        
		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Link Mix Specifications To Mixes'
		        
		        Update MixInfo
					Set MixInfo.MixSpecID = MixSpecInfo.MinMixSpecID + RowNumberInfo.RowNumber - 1						
		        From #MixInfo As MixInfo
		        Inner Join
		        (
		        	Select MixInfo.AutoID, Row_number() Over (Order By MixInfo.AutoID) As RowNumber
		        	From #MixInfo As MixInfo
		        	Where MixInfo.MixSpecID Is Null
		        ) As RowNumberInfo
		        On MixInfo.AutoID = RowNumberInfo.AutoID
		        Cross Join
		        (
		        	Select Min(MixSpec.MixSpecID) As MinMixSpecID
		        	From dbo.MixSpec As MixSpec
		        	Where MixSpec.MixSpecID > Isnull(@LastID, -1)
		        ) As MixSpecInfo
		        
		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Add Spec Data Points for Strength Ages and Strengths'
		        
		        Set @LastID = Null
		        Set @LastID = (Select Max(SpecDataPoint.SpecDataPointID) From dbo.SpecDataPoint As SpecDataPoint)
		        
		        Insert into dbo.SpecDataPoint
		        (
		        	MixSpecID
		        )
		        Select MixInfo.MixSpecID
		        From #MixInfo As MixInfo
		        Where	MixInfo.StrengthDataPointID Is Null And
						IsNull(MixInfo.StrengthAge, -1.0) >= 0.0 And
						IsNull(MixInfo.Strength, -1.0) >= 0.0
		        
		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Link Mixes to the Strength Spec Data Points'
		        
		        Update MixInfo
					Set MixInfo.StrengthDataPointID = SpecDataPoint.SpecDataPointID
		        From #MixInfo As MixInfo
		        Inner Join dbo.SpecDataPoint As SpecDataPoint
		        On SpecDataPoint.MixSpecID = MixInfo.MixSpecID
		        Where SpecDataPoint.SpecDataPointID > Isnull(@LastID, -1)

		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Add Specifications for Air Content Ranges'
		        
		        Set @LastID = Null
		        Set @LastID = (Select Max(SpecDataPoint.SpecDataPointID) From dbo.SpecDataPoint As SpecDataPoint)
		        
		        Insert into dbo.SpecDataPoint
		        (
		        	MixSpecID
		        )
		        Select MixInfo.MixSpecID
		        From #MixInfo As MixInfo
		        Where	MixInfo.AirDataPointID Is Null And
						(
							IsNull(MixInfo.MinAirContent, -1.0) >= 0.0 Or
							IsNull(MixInfo.MaxAirContent, -1.0) >= 0.0 
						) 
		        
		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Link Mixes to Air Content Ranges'
		        
		        Update MixInfo
					Set MixInfo.AirDataPointID = SpecDataPoint.SpecDataPointID
		        From #MixInfo As MixInfo
		        Inner Join dbo.SpecDataPoint As SpecDataPoint
		        On SpecDataPoint.MixSpecID = MixInfo.MixSpecID
		        Where SpecDataPoint.SpecDataPointID > Isnull(@LastID, -1)

		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Add Spec Data Points for Slump Ranges'
		        
		        Set @LastID = Null
		        Set @LastID = (Select Max(SpecDataPoint.SpecDataPointID) From dbo.SpecDataPoint As SpecDataPoint)
		        
		        Insert into dbo.SpecDataPoint
		        (
		        	MixSpecID
		        )
		        Select MixInfo.MixSpecID
		        From #MixInfo As MixInfo
		        Where	MixInfo.SlumpDataPointID Is Null And
						(
							IsNull(MixInfo.MinSlump, -1.0) >= 0.0 Or 
							IsNull(MixInfo.MaxSlump, -1.0) >= 0.0
						)
		        
		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Link Mixes to Slump Ranges'
		        
		        Update MixInfo
					Set MixInfo.SlumpDataPointID = SpecDataPoint.SpecDataPointID
		        From #MixInfo As MixInfo
		        Inner Join dbo.SpecDataPoint As SpecDataPoint
		        On SpecDataPoint.MixSpecID = MixInfo.MixSpecID
		        Where SpecDataPoint.SpecDataPointID > Isnull(@LastID, -1)
		        
		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Add Spec Data Points for Spread Ranges'
		        
		        Set @LastID = Null
		        Set @LastID = (Select Max(SpecDataPoint.SpecDataPointID) From dbo.SpecDataPoint As SpecDataPoint)
		        
		        Insert into dbo.SpecDataPoint
		        (
		        	MixSpecID
		        )
		        Select MixInfo.MixSpecID
		        From #MixInfo As MixInfo
		        Where	MixInfo.SpreadDataPointID Is null And
						(
							IsNull(MixInfo.MinSpread, -1.0) >= 0.0 Or 
							IsNull(MixInfo.MaxSpread, -1.0) >= 0.0
						)
		        
		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Link Mixes to Spread Ranges'
		        
		        Update MixInfo
					Set MixInfo.SpreadDataPointID = SpecDataPoint.SpecDataPointID
		        From #MixInfo As MixInfo
		        Inner Join dbo.SpecDataPoint As SpecDataPoint
		        On SpecDataPoint.MixSpecID = MixInfo.MixSpecID
		        Where SpecDataPoint.SpecDataPointID > Isnull(@LastID, -1)
		        


		        Exec dbo.Utility_DisplayConsoleMessage 'Add Spec Data Points for Max Aggregate Size Ranges'
		        
		        Set @LastID = Null
		        Set @LastID = (Select Max(SpecDataPoint.SpecDataPointID) From dbo.SpecDataPoint As SpecDataPoint)
		        
		        Insert into dbo.SpecDataPoint
		        (
		        	MixSpecID
		        )
		        Select MixInfo.MixSpecID
		        From #MixInfo As MixInfo
		        Where	MixInfo.AggSizeDataPointID Is null And
						(
							IsNull(MixInfo.MinAggregateSize, -1.0) >= 0.0 Or 
							IsNull(MixInfo.MaxAggregateSize, -1.0) >= 0.0
						)
		        
		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Link Mixes to Max Aggregate Size Ranges'
		        
		        Update MixInfo
					Set MixInfo.AggSizeDataPointID = SpecDataPoint.SpecDataPointID
		        From #MixInfo As MixInfo
		        Inner Join dbo.SpecDataPoint As SpecDataPoint
		        On SpecDataPoint.MixSpecID = MixInfo.MixSpecID
		        Where SpecDataPoint.SpecDataPointID > Isnull(@LastID, -1)




		        Exec dbo.Utility_DisplayConsoleMessage 'Add Spec Data Points for Unit Weight Ranges'
		        
		        Set @LastID = Null
		        Set @LastID = (Select Max(SpecDataPoint.SpecDataPointID) From dbo.SpecDataPoint As SpecDataPoint)
		        
		        Insert into dbo.SpecDataPoint
		        (
		        	MixSpecID
		        )
		        Select MixInfo.MixSpecID
		        From #MixInfo As MixInfo
		        Where	MixInfo.UnitWeightDataPointID Is null And
						(
							IsNull(MixInfo.MinUnitWeight, -1.0) >= 0.0 Or 
							IsNull(MixInfo.MaxUnitWeight, -1.0) >= 0.0
						)
		        
		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Link Mixes to Unit Weight Ranges'
		        
		        Update MixInfo
					Set MixInfo.UnitWeightDataPointID = SpecDataPoint.SpecDataPointID
		        From #MixInfo As MixInfo
		        Inner Join dbo.SpecDataPoint As SpecDataPoint
		        On SpecDataPoint.MixSpecID = MixInfo.MixSpecID
		        Where SpecDataPoint.SpecDataPointID > Isnull(@LastID, -1)



		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Add Spec Meases for Strength Ages'
		        
		        Set @LastID = Null
		        Set @LastID = (Select Max(SpecMeas.SpecMeasID) From dbo.SpecMeas As SpecMeas)
		        
		        Insert into dbo.SpecMeas
		        (
					SpecDataPointID
		        )
		        Select MixInfo.StrengthDataPointID
		        From #MixInfo As MixInfo
		        Where	MixInfo.StrengthAgeMeasID Is Null And
						Isnull(MixInfo.StrengthAge, -1.0) >= 0.0 And
						IsNull(MixInfo.Strength, -1.0) >= 0.0						
		        
		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Link Mixes to Strength Age Spec Meases'
		        
		        Update MixInfo
					Set MixInfo.StrengthAgeMeasID = SpecMeas.SpecMeasID
		        From #MixInfo As MixInfo
		        Inner Join dbo.SpecMeas As SpecMeas
		        On MixInfo.StrengthDataPointID = SpecMeas.SpecDataPointID
		        Where SpecMeas.SpecMeasID > Isnull(@LastID, -1)

		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Add Spec Meases for Strengths'
		        
		        Set @LastID = Null
		        Set @LastID = (Select Max(SpecMeas.SpecMeasID) From dbo.SpecMeas As SpecMeas)
		        
		        Insert into dbo.SpecMeas
		        (
					SpecDataPointID
		        )
		        Select MixInfo.StrengthDataPointID
		        From #MixInfo As MixInfo
		        Where	MixInfo.StrengthMeasID Is Null And
						Isnull(MixInfo.StrengthAge, -1.0) >= 0.0 And
						IsNull(MixInfo.Strength, -1.0) >= 0.0						
		        
		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Link Mixes to Strength Spec Meases'
		        
		        Update MixInfo
					Set MixInfo.StrengthMeasID = SpecMeas.SpecMeasID
		        From #MixInfo As MixInfo
		        Inner Join dbo.SpecMeas As SpecMeas
		        On MixInfo.StrengthDataPointID = SpecMeas.SpecDataPointID
		        Where SpecMeas.SpecMeasID > Isnull(@LastID, -1)

		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Add Spec Meases for Air Ranges'
		        
		        Set @LastID = Null
		        Set @LastID = (Select Max(SpecMeas.SpecMeasID) From dbo.SpecMeas As SpecMeas)
		        
		        Insert into dbo.SpecMeas
		        (
					SpecDataPointID
		        )
		        Select MixInfo.AirDataPointID
		        From #MixInfo As MixInfo
		        Where	MixInfo.AirMeasID Is Null And
						(
							IsNull(MixInfo.MinAirContent, -1.0) >= 0.0 Or 
							IsNull(MixInfo.MaxAirContent, -1.0) >= 0.0
						)
		        
		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Link Mixes to Air Range Spec Meases'
		        
		        Update MixInfo
					Set MixInfo.AirMeasID = SpecMeas.SpecMeasID
		        From #MixInfo As MixInfo
		        Inner Join dbo.SpecMeas As SpecMeas
		        On MixInfo.AirDataPointID = SpecMeas.SpecDataPointID
		        Where SpecMeas.SpecMeasID > Isnull(@LastID, -1)

		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Add Spec Meases for Slump Ranges'
		        
		        Set @LastID = Null
		        Set @LastID = (Select Max(SpecMeas.SpecMeasID) From dbo.SpecMeas As SpecMeas)
		        
		        Insert into dbo.SpecMeas
		        (
					SpecDataPointID
		        )
		        Select MixInfo.SlumpDataPointID
		        From #MixInfo As MixInfo
		        Where	MixInfo.SlumpMeasID Is Null And
						(
							IsNull(MixInfo.MinSlump, -1.0) >= 0.0 Or 
							IsNull(MixInfo.MaxSlump, -1.0) >= 0.0
						)
		        
		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Link Mixes to Slump Range Spec Meases'
		        
		        Update MixInfo
					Set MixInfo.SlumpMeasID = SpecMeas.SpecMeasID
		        From #MixInfo As MixInfo
		        Inner Join dbo.SpecMeas As SpecMeas
		        On MixInfo.SlumpDataPointID = SpecMeas.SpecDataPointID
		        Where SpecMeas.SpecMeasID > Isnull(@LastID, -1)
		        
		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Add Spec Meases for Spreads'
		        
		        Set @LastID = Null
		        Set @LastID = (Select Max(SpecMeas.SpecMeasID) From dbo.SpecMeas As SpecMeas)
		        
		        Insert into dbo.SpecMeas
		        (
					SpecDataPointID
		        )
		        Select MixInfo.SpreadDataPointID
		        From #MixInfo As MixInfo
		        Where	MixInfo.SpreadMeasID Is Null And
						(
							IsNull(MixInfo.MinSpread, -1.0) >= 0.0 Or 
							IsNull(MixInfo.MaxSpread, -1.0) >= 0.0
						)		        
		        
		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Link Mixes to Spread Range Spec Meases'
		        
		        Update MixInfo
					Set MixInfo.SpreadMeasID = SpecMeas.SpecMeasID
		        From #MixInfo As MixInfo
		        Inner Join dbo.SpecMeas As SpecMeas
		        On MixInfo.SpreadDataPointID = SpecMeas.SpecDataPointID
		        Where SpecMeas.SpecMeasID > Isnull(@LastID, -1)



		        Exec dbo.Utility_DisplayConsoleMessage 'Add Spec Meases for Max Aggregate Sizes'
		        
		        Set @LastID = Null
		        Set @LastID = (Select Max(SpecMeas.SpecMeasID) From dbo.SpecMeas As SpecMeas)
		        
		        Insert into dbo.SpecMeas
		        (
					SpecDataPointID
		        )
		        Select MixInfo.AggSizeDataPointID
		        From #MixInfo As MixInfo
		        Where	MixInfo.AggSizeMeasID Is Null And
						(
							IsNull(MixInfo.MinAggregateSize, -1.0) >= 0.0 Or 
							IsNull(MixInfo.MaxAggregateSize, -1.0) >= 0.0
						)		        
		        
		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Link Mixes to Max Aggregate Size Range Spec Meases'
		        
		        Update MixInfo
					Set MixInfo.AggSizeMeasID = SpecMeas.SpecMeasID
		        From #MixInfo As MixInfo
		        Inner Join dbo.SpecMeas As SpecMeas
		        On MixInfo.AggSizeDataPointID = SpecMeas.SpecDataPointID
		        Where SpecMeas.SpecMeasID > Isnull(@LastID, -1)



		        Exec dbo.Utility_DisplayConsoleMessage 'Add Spec Meases for Unit Weight Ranges'
		        
		        Set @LastID = Null
		        Set @LastID = (Select Max(SpecMeas.SpecMeasID) From dbo.SpecMeas As SpecMeas)
		        
		        Insert into dbo.SpecMeas
		        (
					SpecDataPointID
		        )
		        Select MixInfo.UnitWeightDataPointID
		        From #MixInfo As MixInfo
		        Where	MixInfo.UnitWeightMeasID Is Null And
						(
							IsNull(MixInfo.MinUnitWeight, -1.0) >= 0.0 Or 
							IsNull(MixInfo.MaxUnitWeight, -1.0) >= 0.0
						)		        
		        
		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Link Mixes to Unit Weight Range Spec Meases'
		        
		        Update MixInfo
					Set MixInfo.UnitWeightMeasID = SpecMeas.SpecMeasID
		        From #MixInfo As MixInfo
		        Inner Join dbo.SpecMeas As SpecMeas
		        On MixInfo.UnitWeightDataPointID = SpecMeas.SpecDataPointID
		        Where SpecMeas.SpecMeasID > Isnull(@LastID, -1)



		        
		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Set Up Strength Age Spec Meases'
		        
		        Update SpecMeas
					Set SpecMeas.MeasTypeID = 2,
						SpecMeas.MinValue = MixInfo.StrengthAge,
						SpecMeas.MaxValue = MixInfo.StrengthAge,
						SpecMeas.UnitsLink = 7
		        From dbo.SpecMeas As SpecMeas
		        Inner Join #MixInfo As MixInfo
		        On SpecMeas.SpecMeasID = MixInfo.StrengthAgeMeasID
		        Where	IsNull(MixInfo.StrengthAge, -1.0) >= 0.0 And
						IsNull(MixInfo.Strength, -1.0) >= 0.0

		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Set Up Strength Spec Meases'
		        
		        Update SpecMeas
					Set SpecMeas.MeasTypeID = 22,
						SpecMeas.MinValue = MixInfo.Strength,
						SpecMeas.MaxValue = MixInfo.Strength,
						SpecMeas.UnitsLink = 6
		        From dbo.SpecMeas As SpecMeas
		        Inner Join #MixInfo As MixInfo
		        On SpecMeas.SpecMeasID = MixInfo.StrengthMeasID
		        Where	IsNull(MixInfo.StrengthAge, -1.0) >= 0.0 And
						IsNull(MixInfo.Strength, -1.0) >= 0.0

		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Set Up Air Range Spec Meases'
		        
		        Update SpecMeas
					Set SpecMeas.MeasTypeID = 10,
						SpecMeas.MinValue = MixInfo.MinAirContent,
						SpecMeas.MaxValue = MixInfo.MaxAirContent,
						SpecMeas.UnitsLink = 4
		        From dbo.SpecMeas As SpecMeas
		        Inner Join #MixInfo As MixInfo
		        On SpecMeas.SpecMeasID = MixInfo.AirMeasID
		        Where	IsNull(MixInfo.MinAirContent, -1.0) >= 0.0 Or
						IsNull(MixInfo.MaxAirContent, -1.0) >= 0.0 

		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Set Up Slump Range Spec Meases'
		        
		        Update SpecMeas
					Set SpecMeas.MeasTypeID = 28,
						SpecMeas.MinValue = MixInfo.MinSlump,
						SpecMeas.MaxValue = MixInfo.MaxSlump,
						SpecMeas.UnitsLink = 9
		        From dbo.SpecMeas As SpecMeas
		        Inner Join #MixInfo As MixInfo
		        On SpecMeas.SpecMeasID = MixInfo.SlumpMeasID
		        Where	IsNull(MixInfo.MinSlump, -1.0) >= 0.0 Or
						IsNull(MixInfo.MaxSlump, -1.0) >= 0.0

		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Set Up Spread Range Spec Meases'
		        
		        Update SpecMeas
					Set SpecMeas.MeasTypeID = 32,
						SpecMeas.MinValue = MixInfo.MinSpread,
						SpecMeas.MaxValue = MixInfo.MaxSpread,
						SpecMeas.UnitsLink = 9
		        From dbo.SpecMeas As SpecMeas
		        Inner Join #MixInfo As MixInfo
		        On SpecMeas.SpecMeasID = MixInfo.SpreadMeasID
		        Where	IsNull(MixInfo.MinSpread, -1.0) >= 0.0 Or
						IsNull(MixInfo.MaxSpread, -1.0) >= 0.0 


		        Exec dbo.Utility_DisplayConsoleMessage 'Set Up Max Aggregate Size Range Spec Meases'
		        
		        Update SpecMeas
					Set SpecMeas.MeasTypeID = 31,
						SpecMeas.MinValue = MixInfo.MinAggregateSize,
						SpecMeas.MaxValue = MixInfo.MaxAggregateSize,
						SpecMeas.UnitsLink = 9
		        From dbo.SpecMeas As SpecMeas
		        Inner Join #MixInfo As MixInfo
		        On SpecMeas.SpecMeasID = MixInfo.AggSizeMeasID
		        Where	IsNull(MixInfo.MinAggregateSize, -1.0) >= 0.0 Or
						IsNull(MixInfo.MaxAggregateSize, -1.0) >= 0.0 

		        Exec dbo.Utility_DisplayConsoleMessage 'Set Up Unit Weight Range Spec Meases'
		        
		        Update SpecMeas
					Set SpecMeas.MeasTypeID = 23,
						SpecMeas.MinValue = MixInfo.MinUnitWeight,
						SpecMeas.MaxValue = MixInfo.MaxUnitWeight,
						SpecMeas.UnitsLink = 13
		        From dbo.SpecMeas As SpecMeas
		        Inner Join #MixInfo As MixInfo
		        On SpecMeas.SpecMeasID = MixInfo.UnitWeightMeasID
		        Where	IsNull(MixInfo.MinUnitWeight, -1.0) >= 0.0 Or
						IsNull(MixInfo.MaxUnitWeight, -1.0) >= 0.0 
		        
		        -----------------------------------------------------------------------------------------
			    Raiserror('', 0, 0) With NoWait
			    Raiserror('Update Existing Mix Specified Min And Max W/CM Ratios.', 0, 0) With NoWait
		        
			    Update RatioSpec
				    Set RatioSpec.RatioMin = MixInfo.MinWCMRatio,
				        RatioSpec.RatioMax = MixInfo.MaxWCMRatio
			    From dbo.MixMaterialRatioSpec As RatioSpec
			    Inner Join #MixInfo As MixInfo
			    On RatioSpec.MixMaterialRatioSpecID = MixInfo.WCMRatio1ID
			    Where   Isnull(MixInfo.MinWCMRatio, -1.0) >= 0.0 Or
			            Isnull(MixInfo.MaxWCMRatio, -1.0) >= 0.0

			    Raiserror('', 0, 0) With NoWait
			    Raiserror('Add New Mix Specified Max W/CM Ratios.', 0, 0) With NoWait
		        
			    Set @LastID = Null
			    Set @LastID = (Select Max(RatioSpec.MixMaterialRatioSpecID) From dbo.MixMaterialRatioSpec As RatioSpec)
			
			    Insert into dbo.MixMaterialRatioSpec
			    (
				    -- MixMaterialRatioSpecID -- this column value is auto-generated
				    MixSpecIDLink,
				    RatioMin,
				    RatioMax,
				    MtrlTypeNumerCount,
				    MtrlTypeDenomCount
			    )
			    Select MixInfo.MixSpecID, MixInfo.MinWCMRatio, MixInfo.MaxWCMRatio, 1, 2
			    From #MixInfo As MixInfo			
			    Where	MixInfo.WCMRatio1ID Is Null And
			            (
			            	Isnull(MixInfo.MinWCMRatio, -1.0) >= 0.0 Or
					        Isnull(MixInfo.MaxWCMRatio, -1.0) >= 0.0
					    )
					
			    Raiserror('', 0, 0) With NoWait
			    Raiserror('Update New Mix Specified Max W/CM Ratio Links.', 0, 0) With NoWait
		        
			    Update MixInfo
				    Set MixInfo.WCMRatio1ID = RatioSpec.MixMaterialRatioSpecID
			    From #MixInfo As MixInfo
			    Inner Join dbo.MixMaterialRatioSpec As RatioSpec
			    On MixInfo.MixSpecID = RatioSpec.MixSpecIDLink
			    Where RatioSpec.MixMaterialRatioSpecID > Isnull(@LastID, -1)
			
			    Raiserror('', 0, 0) With NoWait
			    Raiserror('Add New Ratio Water Numerators.', 0, 0) With NoWait
		        
			    Set @LastID = Null
			    Set @LastID = (Select Max(NOrDMtlType.NOrDMtlTypeID) From dbo.NOrDMtlType As NOrDMtlType)
			
			    Insert into dbo.NOrDMtlType
			    (
				    -- NOrDMtlTypeID -- this column value is auto-generated
				    MtlRatioIDLink,
				    MaterialTypeID,
				    IsNumerator
			    )
			    Select	MixInfo.WCMRatio1ID,
					    5,
					    1
			    From #MixInfo As MixInfo
			    Where	MixInfo.WCMNumerator1ID Is Null And
			            (
			            	Isnull(MixInfo.MinWCMRatio, -1.0) >= 0.0 Or
					        Isnull(MixInfo.MaxWCMRatio, -1.0) >= 0.0
					    )
					
			    Raiserror('', 0, 0) With NoWait
			    Raiserror('Update New Ratio Water Numerator Links.', 0, 0) With NoWait
		        
			    Update MixInfo
				    Set MixInfo.WCMNumerator1ID = NOrDMtlType.NOrDMtlTypeID
			    From #MixInfo As MixInfo
			    Inner Join dbo.NOrDMtlType As NOrDMtlType
			    On MixInfo.WCMRatio1ID = NOrDMtlType.MtlRatioIDLink
			    Where NOrDMtlType.NOrDMtlTypeID > Isnull(@LastID, -1) 

			    Raiserror('', 0, 0) With NoWait
			    Raiserror('Add New Ratio Cement Denominators.', 0, 0) With NoWait
		        
			    Set @LastID = Null
			    Set @LastID = (Select Max(NOrDMtlType.NOrDMtlTypeID) From dbo.NOrDMtlType As NOrDMtlType)
			
			    Insert into dbo.NOrDMtlType
			    (
				    -- NOrDMtlTypeID -- this column value is auto-generated
				    MtlRatioIDLink,
				    MaterialTypeID,
				    IsNumerator
			    )
			    Select	MixInfo.WCMRatio1ID,
					    2,
					    0
			    From #MixInfo As MixInfo
			    Where	MixInfo.WCMDenominator1ID Is Null And
			            (
			            	Isnull(MixInfo.MinWCMRatio, -1.0) >= 0.0 Or
					        Isnull(MixInfo.MaxWCMRatio, -1.0) >= 0.0
					    )
					
			    Raiserror('', 0, 0) With NoWait
			    Raiserror('Update New Ratio Cement Denominator Links.', 0, 0) With NoWait
		        
			    Update MixInfo
				    Set MixInfo.WCMDenominator1ID = NOrDMtlType.NOrDMtlTypeID
			    From #MixInfo As MixInfo
			    Inner Join dbo.NOrDMtlType As NOrDMtlType
			    On MixInfo.WCMRatio1ID = NOrDMtlType.MtlRatioIDLink
			    Where NOrDMtlType.NOrDMtlTypeID > Isnull(@LastID, -1) 

			    Raiserror('', 0, 0) With NoWait
			    Raiserror('Add New Ratio Mineral Denominators.', 0, 0) With NoWait
		        
			    Set @LastID = Null
			    Set @LastID = (Select Max(NOrDMtlType.NOrDMtlTypeID) From dbo.NOrDMtlType As NOrDMtlType)
			
			    Insert into dbo.NOrDMtlType
			    (
				    -- NOrDMtlTypeID -- this column value is auto-generated
				    MtlRatioIDLink,
				    MaterialTypeID,
				    IsNumerator
			    )
			    Select	MixInfo.WCMRatio1ID,
					    4,
					    0
			    From #MixInfo As MixInfo
			    Where	MixInfo.WCMDenominator2ID Is Null And
			            (
			            	Isnull(MixInfo.MinWCMRatio, -1.0) >= 0.0 Or
					        Isnull(MixInfo.MaxWCMRatio, -1.0) >= 0.0
					    )
					
			    Raiserror('', 0, 0) With NoWait
			    Raiserror('Update New Ratio Mineral Denominator Links.', 0, 0) With NoWait
		        
			    Update MixInfo
				    Set MixInfo.WCMDenominator2ID = NOrDMtlType.NOrDMtlTypeID
			    From #MixInfo As MixInfo
			    Inner Join dbo.NOrDMtlType As NOrDMtlType
			    On MixInfo.WCMRatio1ID = NOrDMtlType.MtlRatioIDLink
			    Where NOrDMtlType.NOrDMtlTypeID > Isnull(@LastID, -1) 
		        
		        -----------------------------------------------------------------------------------------


		        -----------------------------------------------------------------------------------------
			    Raiserror('', 0, 0) With NoWait
			    Raiserror('Update Existing Mix Specified Min And Max W/C Ratios.', 0, 0) With NoWait
		        
			    Update RatioSpec
				    Set RatioSpec.RatioMin = MixInfo.MinWCRatio,
				        RatioSpec.RatioMax = MixInfo.MaxWCRatio
			    From dbo.MixMaterialRatioSpec As RatioSpec
			    Inner Join #MixInfo As MixInfo
			    On RatioSpec.MixMaterialRatioSpecID = MixInfo.WCRatio1ID
			    Where   Isnull(MixInfo.MinWCRatio, -1.0) >= 0.0 Or
			            Isnull(MixInfo.MaxWCRatio, -1.0) >= 0.0

			    Raiserror('', 0, 0) With NoWait
			    Raiserror('Add New Mix Specified Max W/C Ratios.', 0, 0) With NoWait
		        
			    Set @LastID = Null
			    Set @LastID = (Select Max(RatioSpec.MixMaterialRatioSpecID) From dbo.MixMaterialRatioSpec As RatioSpec)
			
			    Insert into dbo.MixMaterialRatioSpec
			    (
				    -- MixMaterialRatioSpecID -- this column value is auto-generated
				    MixSpecIDLink,
				    RatioMin,
				    RatioMax,
				    MtrlTypeNumerCount,
				    MtrlTypeDenomCount
			    )
			    Select MixInfo.MixSpecID, MixInfo.MinWCRatio, MixInfo.MaxWCRatio, 1, 1
			    From #MixInfo As MixInfo			
			    Where	MixInfo.WCRatio1ID Is Null And
			            (
			            	Isnull(MixInfo.MinWCRatio, -1.0) >= 0.0 Or
					        Isnull(MixInfo.MaxWCRatio, -1.0) >= 0.0
					    )
					
			    Raiserror('', 0, 0) With NoWait
			    Raiserror('Update New Mix Specified Max W/C Ratio Links.', 0, 0) With NoWait
		        
			    Update MixInfo
				    Set MixInfo.WCRatio1ID = RatioSpec.MixMaterialRatioSpecID
			    From #MixInfo As MixInfo
			    Inner Join dbo.MixMaterialRatioSpec As RatioSpec
			    On MixInfo.MixSpecID = RatioSpec.MixSpecIDLink
			    Where RatioSpec.MixMaterialRatioSpecID > Isnull(@LastID, -1)
			
			    Raiserror('', 0, 0) With NoWait
			    Raiserror('Add New Ratio Water Numerators.', 0, 0) With NoWait
		        
			    Set @LastID = Null
			    Set @LastID = (Select Max(NOrDMtlType.NOrDMtlTypeID) From dbo.NOrDMtlType As NOrDMtlType)
			
			    Insert into dbo.NOrDMtlType
			    (
				    -- NOrDMtlTypeID -- this column value is auto-generated
				    MtlRatioIDLink,
				    MaterialTypeID,
				    IsNumerator
			    )
			    Select	MixInfo.WCRatio1ID,
					    5,
					    1
			    From #MixInfo As MixInfo
			    Where	MixInfo.WCNumerator1ID Is Null And
			            (
			            	Isnull(MixInfo.MinWCRatio, -1.0) >= 0.0 Or
					        Isnull(MixInfo.MaxWCRatio, -1.0) >= 0.0
					    )
					
			    Raiserror('', 0, 0) With NoWait
			    Raiserror('Update New Ratio Water Numerator Links.', 0, 0) With NoWait
		        
			    Update MixInfo
				    Set MixInfo.WCNumerator1ID = NOrDMtlType.NOrDMtlTypeID
			    From #MixInfo As MixInfo
			    Inner Join dbo.NOrDMtlType As NOrDMtlType
			    On MixInfo.WCRatio1ID = NOrDMtlType.MtlRatioIDLink
			    Where NOrDMtlType.NOrDMtlTypeID > Isnull(@LastID, -1) 

			    Raiserror('', 0, 0) With NoWait
			    Raiserror('Add New Ratio Cement Denominators.', 0, 0) With NoWait
		        
			    Set @LastID = Null
			    Set @LastID = (Select Max(NOrDMtlType.NOrDMtlTypeID) From dbo.NOrDMtlType As NOrDMtlType)
			
			    Insert into dbo.NOrDMtlType
			    (
				    -- NOrDMtlTypeID -- this column value is auto-generated
				    MtlRatioIDLink,
				    MaterialTypeID,
				    IsNumerator
			    )
			    Select	MixInfo.WCRatio1ID,
					    2,
					    0
			    From #MixInfo As MixInfo
			    Where	MixInfo.WCDenominator1ID Is Null And
			            (
			            	Isnull(MixInfo.MinWCRatio, -1.0) >= 0.0 Or
					        Isnull(MixInfo.MaxWCRatio, -1.0) >= 0.0
					    )
					
			    Raiserror('', 0, 0) With NoWait
			    Raiserror('Update New Ratio Cement Denominator Links.', 0, 0) With NoWait
		        
			    Update MixInfo
				    Set MixInfo.WCDenominator1ID = NOrDMtlType.NOrDMtlTypeID
			    From #MixInfo As MixInfo
			    Inner Join dbo.NOrDMtlType As NOrDMtlType
			    On MixInfo.WCRatio1ID = NOrDMtlType.MtlRatioIDLink
			    Where NOrDMtlType.NOrDMtlTypeID > Isnull(@LastID, -1) 

		        -----------------------------------------------------------------------------------------
		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Remove Empty Spec Meases'
		        
		        Delete SpecMeas
		        From dbo.SpecMeas As SpecMeas
		        Where MeasTypeID Is Null
				
		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Remove Empty Spec Data Points'
		        
				Delete SpecDataPoint
				From dbo.SpecDataPoint As SpecDataPoint
				Left Join dbo.SpecMeas As SpecMeas
				On SpecMeas.SpecDataPointID = SpecDataPoint.SpecDataPointID
				Where SpecMeas.SpecMeasID Is Null

		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Remove Existing Recipes'
		        
				Delete Recipe
				From dbo.MaterialRecipe As Recipe
				Inner Join #MixInfo As MixInfo
				On  Recipe.EntityID = MixInfo.ActualMixID And
				    Recipe.EntityType = 'Mix'
				
		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Reset the Spec Meas, Spec Data Point, and Material Recipe Auto Numbers'
		        
				Exec dbo.Utilities_ResetAutoNumberInPhysicalTable 'SpecMeas'
				Exec dbo.Utilities_ResetAutoNumberInPhysicalTable 'SpecDataPoint'
				Exec dbo.Utilities_ResetAutoNumberInPhysicalTable 'MaterialRecipe'

                Exec dbo.Utility_DisplayConsoleMessage 'Add New Mix Usages'
                
                Insert into dbo.MixUsage
                (
                	-- MixUsageID -- this column value is auto-generated
                	Usage
                )
                Select MixInfo.MixUsage
                From #MixInfo As MixInfo
                Left Join dbo.MixUsage As ExistingMixUsage
                On MixInfo.MixUsage = ExistingMixUsage.Usage
                Where   IsNull(MixInfo.MixUsage, '') <> '' And 
                        ExistingMixUsage.MixUsageID Is Null
                Group By MixInfo.MixUsage
                Order By MixInfo.MixUsage
				
				Exec dbo.Utility_DisplayConsoleMessage 'Update Existing Mixes'
				
				Update Mix
				    Set Mix.AIR = Case when IsNull(MixInfo.AirContent, -1.0) >= 0.0 And Isnull(MixInfo.AirContent, -1.0) <= 90.0 Then MixInfo.AirContent Else Mix.AIR End,
				        Mix.SLUMP = Case when Isnull(MixInfo.Slump, -1.0) >= 0.0 Then MixInfo.Slump * 25.4 Else Mix.SLUMP End,
				        Mix.MixTargetSpread = Case when Isnull(MixInfo.Spread, -1.0) >= 0.0 Then MixInfo.Spread * 25.4 Else Mix.MixTargetSpread End,
				        Mix.MaximumBatchSize = Case when Isnull(MixInfo.MaxLoadSize, -1.0) > 0.0 Then MixInfo.MaxLoadSize Else Mix.MaximumBatchSize End,
				        Mix.MaxWaterQuantity = MixInfo.MaxWater / 0.26417205,
				        Mix.SackContent = Case when Isnull(MixInfo.SackContent, -1.0) > 0.0 Then MixInfo.SackContent Else Mix.SackContent End,
				        Mix.COST5 = 
				            Case
				                When Isnull(MixInfo.Price, -1.0) < 0.0 Or Isnull(MixInfo.PriceUnitName, '') Not In ('CU Yards')
				                Then Mix.COST5
				                Else MixInfo.Price * 1.307950547
				            End,
				        Mix.MixInactive = 
				            Case 
				                When    dbo.Validation_StringValueIsTrue(Isnull(MixInfo.MixInactive, '')) = 1 Or 
				                        Isnull(@DeactivateExistingMixes, 0) = 1 
				                Then 1 
				                Else Mix.MixInactive 
				            End,			        
				        Mix.MixSpecID = Case when MixInfo.MixSpecID Is Not null Then MixInfo.MixSpecID Else Mix.MixSpecID End,
				        Mix.ItemMasterID = ItemMaster.ItemMasterID,
				        Mix.DescriptionID = Case when ItemMaster.ItemMasterID Is Not Null Then ItemMaster.DescriptionID Else Mix.DescriptionID End,
				        Mix.BatchPanelCode = Case when ItemMaster.ItemMasterID Is not Null Then MixName.Name Else Null End,
				        Mix.BatchPanelDescription = ItemDescr.[Description],
				        Mix.MixUsageID = Case when Isnull(MixInfo.MixUsage, '') <> '' Then MixUsage.MixUsageID Else Mix.MixUsageID End,
				        Mix.MixUsage = Case when Isnull(MixInfo.MixUsage, '') <> '' Then Cast(MixInfo.MixUsage As Ntext) Else Mix.MixUsage End, 
				        Mix.ProductionStatus = Case when Isnull(Mix.ProductionStatus, '') In ('InSync', 'Sent') Then 'OutOfSync' Else Mix.ProductionStatus End
				From dbo.Batch As Mix
				Inner Join #MixInfo As MixInfo
				On Mix.BATCHIDENTIFIER = MixInfo.ActualMixID
				Inner Join dbo.Name As MixName
				On Mix.NameID = MixName.NameID
			    Left Join dbo.ItemMaster As ItemMaster
			    On  MixName.NameID = ItemMaster.NameID And
			        ItemMaster.ItemType = 'Mix'
			    Left Join dbo.[Description] As ItemDescr
			    On ItemMaster.DescriptionID = ItemDescr.DescriptionID
			    Left Join dbo.MixUsage As MixUsage
			    On MixUsage.Usage = MixInfo.MixUsage
				
				Exec dbo.Utility_DisplayConsoleMessage 'Deactivate Batches Linked To Existing Mixes'
					
				Update Batch
				    Set Batch.MixInactive = Mix.MixInactive
				From Batch As Batch
				Inner Join dbo.Batch As Mix
				On Batch.MixNameCode = Mix.MixNameCode And Batch.NameID Is Null And Mix.NameID Is Not null
				Inner Join #MixInfo As MixInfo
				On Mix.BATCHIDENTIFIER = MixInfo.ActualMixID
				
				Exec dbo.Utility_DisplayConsoleMessage 'Add New Mixes'
				
				Insert Into [dbo].[Batch]
				(
				    Code,
				    CrushCode,
				    Date,
				    Time,
				    MixNameCode,
				    Air,
				    ThrmCond,
				    Slump,
				    MixTargetSpread,
				    MaximumBatchSize,
				    MaxWaterQuantity,
				    SackContent,
				    COST5,
				    MixInactive,
				    Mix,
				    Plant_Link,
				    MixSpecID,
				    ItemMasterID,
				    NameID,
				    DescriptionID,
				    BatchPanelCode,
				    BatchPanelDescription,
				    MixUsageID,
				    MixUsage 
				)					
				Select  MixInfo.MixCode,
				        'S97000000000',
				        @MixDate,
				        @MixTime,
				        MixInfo.MixNameCode,
				        Isnull(MixInfo.AirContent, 1.5),
				        8.099819,
				        MixInfo.Slump * 25.4, 
				        MixInfo.Spread * 25.4, 
				        MixInfo.MaxLoadSize,
				        MixInfo.MaxWater / 0.26417205,
				        MixInfo.SackContent,
				        Case
				            When Isnull(MixInfo.Price, -1.0) < 0.0 Or Isnull(MixInfo.PriceUnitName, '') Not In ('CU Yards')
				            Then Null
				            Else MixInfo.Price * 1.307950547
				        End,
				        Case 
				            When    dbo.Validation_StringValueIsTrue(Isnull(MixInfo.MixInactive, '')) = 1 Or
				                    Isnull(@DeactivateNewMixes, 0) = 1
				            Then 1 
				            Else Null 
				        End,
				        'y',
				        Plants.PlantId,
				        MixInfo.MixSpecID,
				        ItemMaster.ItemMasterID,
				        MixNameInfo.NameID,
				        Case when ItemMaster.ItemMasterID Is Null Then MixDescriptionInfo.DescriptionID Else ItemMaster.DescriptionID End,
				        Case when ItemMaster.ItemMasterID Is Null Then Null Else MixNameInfo.Name End,
				        ItemDescrInfo.[Description],
				        MixUsage.MixUsageID,
				        Cast(MixInfo.MixUsage As Ntext)
				    From #MixInfo As MixInfo
				    Inner Join dbo.Plants As Plants
				    On MixInfo.PlantName = Plants.Name
				    Inner Join dbo.Name As MixNameInfo
				    On MixInfo.MixName = MixNameInfo.Name
				    Left Join dbo.[Description] As MixDescriptionInfo
				    On MixInfo.[Description] = MixDescriptionInfo.[Description]
				    Left Join dbo.ItemMaster As ItemMaster
				    On	ItemMaster.NameID = MixNameInfo.NameID And
						ItemMaster.ItemType = 'Mix'
				    Left Join dbo.[Description] As ItemDescrInfo
				    On ItemDescrInfo.DescriptionID = ItemMaster.DescriptionID
				    Left Join dbo.MixUsage As MixUsage
				    On MixInfo.MixUsage = MixUsage.Usage
				    Where MixInfo.ActualMixID Is Null
				
				Exec dbo.Utility_DisplayConsoleMessage 'Retrieve Mix ID Info For New Mixes'
				
				Update MixInfo
				    Set MixInfo.ActualMixID = Mix.BATCHIDENTIFIER
				From #MixInfo As MixInfo
				Inner Join dbo.BATCH As Mix
				On MixInfo.MixCode = Mix.CODE
				Where MixInfo.ActualMixID Is Null
				
				Exec dbo.Utility_DisplayConsoleMessage 'Add New Mix Recipe Ingredients'
				
			    Insert Into dbo.MaterialRecipe
			    (
			        EntityID,
			        EntityType,
			        CODE,
			        MaterialID,
			        MATERIAL,
			        QUANTITY,
			        MOISTURE
			    )				    
			    Select	MixInfo.ActualMixID,
						'Mix',
						MixInfo.MixCode,
						MixRecipeInfo.MaterialID,
						MixRecipeInfo.MaterialCode,
						MixRecipeInfo.ConvertedQuantity,
						0.0 
			    From #MixInfo As MixInfo
			    Inner Join #MixRecipeInfo As MixRecipeInfo
			    On	MixInfo.PlantName = MixRecipeInfo.PlantName And
					MixInfo.MixName = MixRecipeInfo.MixName
			    Where MixInfo.ActualMixID Is Not Null
			    
			    
			    Exec dbo.Utility_DisplayConsoleMessage 'Calculate Mix Sack Contents'

				Update Mix
					Set SackContent = Recipe.CementitiousQty / (94.0 * 0.45359240000781)
					From dbo.Batch As Mix
					Inner Join #MixInfo As MixInfo
					On Mix.CODE = MixInfo.MixCode
					Inner Join
					(
						Select MaterialRecipe.EntityID As MixID, Sum(MaterialRecipe.Quantity) As CementitiousQty
							From [dbo].[MaterialRecipe] As MaterialRecipe
							Inner Join #MixInfo As MixInfo
							On	MaterialRecipe.CODE = MixInfo.MixCode And
								MaterialRecipe.EntityType = 'Mix'							 
							Inner Join [dbo].[Material] As Material
							On MaterialRecipe.MaterialID = Material.MaterialIdentifier
							Where Material.FamilyMaterialTypeID In (2, 4)
							Group By MaterialRecipe.EntityID
					) As Recipe
					On Mix.BATCHIDENTIFIER = Recipe.MixID
				    Where IsNull(MixInfo.SackContent, -1.0) <= 0.0 
				    
				Exec dbo.Utility_DisplayConsoleMessage 'Add Mix Classes'
				
		        Insert into dbo.ClassDefinitions
		        (
		        	-- ClassDefID -- this column value is auto-generated
		        	Name,
		        	[Description]
		        )
		        Select  MixClassInfo.MixClassName, Null
		        From @MixClassInfo As MixClassInfo
		        Left Join dbo.ClassDefinitions As ClassDef
		        On MixClassInfo.MixClassName = ClassDef.Name
		        Where ClassDef.ClassDefID Is Null
		        Group By MixClassInfo.MixClassName
		        Order By MixClassInfo.MixClassName
		        
		        If Isnull(@RemoveExistingMixClasses, 0) = 1
		        Begin
				    Exec dbo.Utility_DisplayConsoleMessage 'Remove Current Mix Classes'
				
				    Delete MixClassDef
				    From dbo.MixClassDefinitions As MixClassDef
				    Inner Join #MixInfo As MixInfo
				    On MixClassDef.MixLink = MixInfo.ActualMixID
		        End
		        				
		        Exec dbo.Utility_DisplayConsoleMessage 'Link Mixes To Classes'
		        
		        Insert into dbo.MixClassDefinitions
		        (
		        	ClassDefLink,
		        	MixLink
		        )
		        Select ClassDef.ClassDefID, MixInfo.ActualMixID
		        From @MixClassInfo As MixClassInfo
		        Inner Join dbo.ClassDefinitions As ClassDef
		        On MixClassInfo.MixClassName = ClassDef.Name
		        Inner Join #MixInfo As MixInfo
		        On MixClassInfo.MixAutoID = MixInfo.AutoID
				Left Join dbo.MixClassDefinitions As MixClass
				On  MixInfo.ActualMixID = MixClass.MixLink And
				    ClassDef.ClassDefID = MixClass.ClassDefLink
		        Where MixClass.MixLink Is Null And MixInfo.ActualMixID Is Not Null
		        Group By ClassDef.ClassDefID, MixInfo.ActualMixID
		        Order By MixInfo.ActualMixID, ClassDef.ClassDefID
		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Add New Attachments'
		        
		        Set @AttachmentFilePath = Isnull((Select Top 1 Attachment.FilePath From dbo.Attachment As Attachment Where Isnull(Attachment.FilePath, '') <> ''), '')
		        
		        Insert into dbo.Attachment
		        (
		        	-- AttachmentID -- this column value is auto-generated
		        	Name,
		        	FilePath,
		        	[Description],
		        	AttachmentDate,
		        	Source,
		        	AttachmentTypeID,
		        	UserID,
		        	AttachmentKindID,
		        	AttachmentTemplateId
		        )
		        Select  AttachmentInfo.AttachmentName,
		                @AttachmentFilePath,
		                Null,
		                Getdate(),
		                Null,
		                AttachmentType.AttachmentTypeID, 
		                Null,
		                AttachmentKind.AttachmentKindID,
		                Null
		        From @AttachmentInfo As AttachmentInfo
		        Left Join dbo.Attachment As Attachment
		        On AttachmentInfo.AttachmentName = Attachment.Name
		        Inner Join dbo.AttachmentType As AttachmentType
		        On AttachmentType.Name = 'Mix'
		        Left Join dbo.AttachmentKind As AttachmentKind
		        On Right(AttachmentInfo.AttachmentName, 4) = '.' + AttachmentKind.Extension
		        Where Attachment.AttachmentID Is Null
		        Group By AttachmentInfo.AttachmentName, AttachmentType.AttachmentTypeID, AttachmentKind.AttachmentKindID
		        Order By AttachmentInfo.AttachmentName
		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Retrieve Mix Attachments That Need To Be Added For Mixes'
		        
		        Insert into @MixAttachmentInfo (MixAutoID, MixID, AttachmentID, AttachmentName, AttachmentTypeID, LastSortNumber)
		            Select  MixInfo.AutoID, MixInfo.ActualMixID, Attachment.AttachmentID, Attachment.Name, Attachment.AttachmentTypeID, Isnull(MixAttachmentOrderInfo.MaxStatedOrder, 0)
		            From @AttachmentInfo As AttachmentInfo
		            Inner Join dbo.Attachment As Attachment
		            On AttachmentInfo.AttachmentName = Attachment.Name
		            Inner Join #MixInfo As MixInfo
		            On AttachmentInfo.MixAutoID = MixInfo.AutoID
		            Left Join dbo.MixAttachment As MixAttachment
		            On  MixInfo.ActualMixID = MixAttachment.MixID And
		                Attachment.AttachmentID = MixAttachment.AttachmentID
		            Left Join
		            (
		            	Select MixInfo.ActualMixID, Max(MixAttachment.StatedOrder) As MaxStatedOrder
		            	From #MixInfo As MixInfo
		            	Inner Join dbo.MixAttachment As MixAttachment
		            	On MixInfo.ActualMixID = MixAttachment.MixID
		            	Group By MixInfo.ActualMixID
		            ) As MixAttachmentOrderInfo
		            On  MixInfo.ActualMixID = MixAttachmentOrderInfo.ActualMixID
		            Where MixAttachment.MixID Is Null
		            Group By MixInfo.AutoID, MixInfo.ActualMixID, Attachment.AttachmentID, Attachment.Name, Attachment.AttachmentTypeID, Isnull(MixAttachmentOrderInfo.MaxStatedOrder, 0)
		            Order By MixInfo.ActualMixID, Attachment.Name
		            
		        Exec dbo.Utility_DisplayConsoleMessage 'Update Sort Numbers'
		        
		        Update MixAttachmentInfo
		            Set MixAttachmentInfo.SortNumber = Isnull(MixAttachmentInfo.LastSortNumber, 0) + ((MixAttachmentInfo.AutoID - AttachmentInfo.MinAutoID) + 1)
		        From @MixAttachmentInfo As MixAttachmentInfo
		        Inner Join
		        (
		        	Select MixAttachmentInfo.MixID, Min(MixAttachmentInfo.AutoID) As MinAutoID
		        	From @MixAttachmentInfo As MixAttachmentInfo
		        	Group By MixAttachmentInfo.MixID
		        ) As AttachmentInfo
		        On MixAttachmentInfo.MixID = AttachmentInfo.MixID

		        Exec dbo.Utility_DisplayConsoleMessage 'Add Mix Attachments'
		        
		        Insert into dbo.MixAttachment
		        (
		        	MixID,
		        	AttachmentID,
		        	StatedOrder,
		        	AttachmentTypeID
		        )
		        Select  MixAttachmentInfo.MixID, 
		                MixAttachmentInfo.AttachmentID,
		                MixAttachmentInfo.SortNumber,
		                MixAttachmentInfo.AttachmentTypeID
		        From @MixAttachmentInfo As MixAttachmentInfo
		        Order By MixAttachmentInfo.MixID, MixAttachmentInfo.SortNumber, MixAttachmentInfo.AttachmentID
		        
		        Exec dbo.Utility_DisplayConsoleMessage 'Set Starting Mix Info Max Attachment Sort Numbers'
		        
		        Update MixInfo
		            Set MixInfo.MaxAttachmentSortNumber = 1
		        From #MixInfo As MixInfo
		        
		        While Exists 
		        (
		        	Select * 
		        	From dbo.MixAttachment As MixAttachment 
		        	Inner Join #MixInfo As MixInfo 
		        	On MixAttachment.MixID = MixInfo.ActualMixID 
		        	Where MixAttachment.StatedOrder Is Null
		        )
		        Begin
		        	Exec dbo.Utility_DisplayConsoleMessage 'Get Next Mix Info Max Attachment Sort Numbers'
		        	
		            Update MixInfo
		                Set MixInfo.MaxAttachmentSortNumber = SortNumInfo.MaxStatedOrder + 1
		            From #MixInfo As MixInfo
		            Inner Join
		            (
		            	Select MixAttachment.MixID, Max(MixAttachment.StatedOrder) As MaxStatedOrder
		            	From dbo.MixAttachment As MixAttachment
		            	Inner Join #MixInfo As MixInfo
		            	On MixInfo.ActualMixID = MixAttachment.MixID
		            	Where MixAttachment.StatedOrder Is Not Null
		            	Group By MixAttachment.MixID
		            ) As SortNumInfo
		            On MixInfo.ActualMixID = SortNumInfo.MixID
		            
		            Exec dbo.Utility_DisplayConsoleMessage 'Set Attachment Sort Numbers'
		            
		            Update MixAttachment
		                Set MixAttachment.StatedOrder = MixInfo.MaxAttachmentSortNumber
		            From dbo.MixAttachment As MixAttachment
		            Inner Join #MixInfo As MixInfo
		            On MixAttachment.MixID = MixInfo.ActualMixID
		            Inner Join
		            (
		            	Select MixAttachment.MixID, Min(MixAttachment.AttachmentID) As MinAttachmentID
		            	From dbo.MixAttachment As MixAttachment
		            	Inner Join #MixInfo As MixInfo
		            	On MixAttachment.MixID = MixInfo.ActualMixID
		            	Where MixAttachment.StatedOrder Is Null
		            	Group By MixAttachment.MixID
		            ) As AttachmentInfo
		            On  MixAttachment.MixID = AttachmentInfo.MixID And
		                MixAttachment.AttachmentID = AttachmentInfo.MinAttachmentID
		        End

				If IsNull(@UpdateMixReportFields, 0) = 1
				Begin
					Raiserror('', 0, 0) With NoWait
					Raiserror('Retrieve Mix Slumps, Air Contents, and Strengths for Reports.', 0, 0) With NoWait

					Insert into #MixReportInfo 
					(
            			MixID, 
            			MixSpecID, 
            			PlantName, 
            			MixName, 
            			Strength, 
            			MinSlump, 
            			MaxSlump, 
            			MinAirContent, 
            			MaxAirContent,
            			MixStrength, 
            			MixMinSlump, 
            			MixMaxSlump, 
            			MixMinAirContent, 
            			MixMaxAirContent
					)
					Select  Mix.BATCHIDENTIFIER, 
							Mix.MixSpecID,
							Plants.Name,
							MixName.Name,
							Case 
								When StrengthSpec.StrengthMinValue Is Null Or StrengthSpec.MixSpecID Is Null Or Isnull(StrengthSpec.StrengthUnitID, -1) Not In (5, 6)
								Then Null
								When StrengthSpec.StrengthUnitID In (6) -- psi
								Then StrengthSpec.StrengthMinValue * 0.006894757
								Else StrengthSpec.StrengthMinValue
							End,
							Case 
								When SlumpSpec.MinSlump Is Null Or SlumpSpec.MixSpecID Is Null Or Isnull(SlumpSpec.SlumpUnitsID, -1) Not In (8, 9)
								Then Null
								When SlumpSpec.SlumpUnitsID In (9) -- inches
								Then SlumpSpec.MinSlump * 25.4
								Else SlumpSpec.MinSlump
							End,
							Case 
								When SlumpSpec.MaxSlump Is Null Or SlumpSpec.MixSpecID Is Null Or Isnull(SlumpSpec.SlumpUnitsID, -1) Not In (8, 9)
								Then Null
								When SlumpSpec.SlumpUnitsID In (9) -- inches
								Then SlumpSpec.MaxSlump * 25.4
								Else SlumpSpec.MaxSlump
							End,
							AirSpec.MinAirContent,
							AirSpec.MaxAirContent,
							StrengthSpec.StrengthMinValue,
							SlumpSpec.MinSlump, 
							SlumpSpec.MaxSlump,
							AirSpec.MinAirContent, 
							AirSpec.MaxAirContent
					From dbo.Batch As Mix
					Inner Join #MixInfo As MixInfo
					On Mix.BATCHIDENTIFIER = MixInfo.ActualMixID
					Inner Join dbo.Plants As Plants
					On Plants.PlantId = Mix.Plant_Link
					Inner Join dbo.Name As MixName
					On MixName.NameID = Mix.NameID
					Left Join dbo.RptMixSpec28DayComprStrengths As StrengthSpec
					On StrengthSpec.MixSpecID = Mix.MixSpecID
					Left Join dbo.RptMixSpecAirContent As AirSpec
					On AirSpec.MixSpecID = Mix.MixSpecID
					Left Join dbo.RptMixSpecSlump As SlumpSpec
					On SlumpSpec.MixSpecID = Mix.MixSpecID
					Where   Mix.NameID Is Not null And
							(
                    			StrengthSpec.MixSpecID Is Not null Or
                    			SlumpSpec.MixSpecID Is Not null Or
                    			AirSpec.MixSpecID Is Not Null
							)
					Order By Plants.Name, MixName.Name

					Raiserror('', 0, 0) With NoWait
					Raiserror('Update Mix Report Strengths, Air Content Ranges, and Slump Ranges.', 0, 0) With NoWait

					Update Mix
						Set Mix.FPC =
								Case
									When Isnull(MixInfo.Strength, -1.0) <= 0.0
									Then Null
									Else Ltrim(Rtrim(Cast(Cast(MixInfo.Strength As Decimal (30,15)) As Nvarchar))) 
								End,
							Mix.SPECAIR =
								Case
									When Isnull(MixInfo.MinAirContent, -1.0) < 0.0 And Isnull(MixInfo.MaxAirContent, -1.0) < 0.0
									Then Null
									When Isnull(MixInfo.MaxAirContent, -1.0) < 0.0
									Then Ltrim(Rtrim(Cast(Cast(MixInfo.MinAirContent As Decimal(15, 2)) As Nvarchar))) 
									When Isnull(MixInfo.MinAirContent, -1.0) < 0.0
									Then Ltrim(Rtrim(Cast(Cast(MixInfo.MaxAirContent As Decimal(15, 2)) As Nvarchar))) 
									Else    Ltrim(Rtrim(Cast(Cast(MixInfo.MinAirContent As Decimal (15, 2)) As Nvarchar))) + 
											' To ' + 
											Ltrim(Rtrim(Cast(Cast(MixInfo.MaxAirContent As Decimal (15, 2)) As Nvarchar)))
								End,
							Mix.SPECSLUMP = 
								Case
									When Isnull(MixInfo.MinSlump, -1.0) < 0.0 And Isnull(MixInfo.MaxSlump, -1.0) < 0.0
									Then Null
									When Isnull(MixInfo.MaxSlump, -1.0) < 0.0
									Then Ltrim(Rtrim(Cast(Cast(MixInfo.MinSlump As Decimal(15, 2)) As Nvarchar))) 
									When Isnull(MixInfo.MinSlump, -1.0) < 0.0
									Then Ltrim(Rtrim(Cast(Cast(MixInfo.MaxSlump As Decimal(15, 2)) As Nvarchar))) 
									Else    Ltrim(Rtrim(Cast(Cast(MixInfo.MinSlump As Decimal (15, 2)) As Nvarchar))) + 
											' To ' + 
											Ltrim(Rtrim(Cast(Cast(MixInfo.MaxSlump As Decimal (15, 2)) As Nvarchar)))
								End
					From dbo.BATCH As Mix
					Inner Join #MixReportInfo As MixInfo
					On Mix.BATCHIDENTIFIER = MixInfo.MixID
				End
				
				If dbo.Validation_DatabaseTemporaryTableExists('#MixIDInfo') = 1
				Begin
				    Drop table #MixIDInfo
				End
				
				
				Exec dbo.Utility_DisplayConsoleMessage 'Create Mix ID Storage'
				
				Create table #MixIDInfo
				(
					MixID Int
				)
				
				
				Exec dbo.Utility_DisplayConsoleMessage 'Get Mix Information For Calculations'
				
				Insert into #MixIDInfo (MixID)
					Select Mix.BATCHIDENTIFIER
					From dbo.Batch As Mix
					Inner Join #MixInfo As MixInfo
					On Mix.CODE = MixInfo.MixCode
				
				
				Exec dbo.Utility_DisplayConsoleMessage 'Calculate The Mix Theoretical And Measured Values'
				
				Exec dbo.Mix_CalcTheoAndMeasCalcsByMixIDTempTable '#MixIDInfo', 'MixID', 1.5, 0
				
				
				Exec dbo.Utility_DisplayConsoleMessage 'Calculate The Mix Material Costs'
				
				Exec dbo.Mix_CalcMaterialCostsByMixIDTempTable '#MixIDInfo', 'MixID', 1.5, 0

				If dbo.Validation_DatabaseTemporaryTableExists('#MixIDInfo') = 1
				Begin
				    Drop table #MixIDInfo
				End
				--*/
			End
		End
		
		Commit Transaction
		
		
		Exec dbo.Utility_DisplayConsoleMessage 'The Mixes May Have Been Imported.'
		
    End Try
    Begin catch
		If @@TRANCOUNT > 0
		Begin
		    Rollback Transaction
		    Exec dbo.Utility_DisplayConsoleMessage 'The Transaction was rolled back.'
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
		
		Exec dbo.Utility_DisplayConsoleMessage 'The Mixes could not be imported.  Transaction Rolled Back.'
		Print @ErrorMessage

		Raiserror(@ErrorMessage, @ErrorSeverity, 1)
    End Catch

	If dbo.Validation_DatabaseTemporaryTableExists('#MixInfo') = 1
	Begin
	    Drop table #MixInfo
	End

	If dbo.Validation_DatabaseTemporaryTableExists('#MixRecipeInfo') = 1
	Begin
	    Drop table #MixRecipeInfo
	End

    If dbo.Validation_DatabaseTemporaryTableExists('#MaterialInfo') = 1
    Begin
		Drop Table #MaterialInfo
    End

	Drop Table If Exists #MixReportInfo
End
Go
