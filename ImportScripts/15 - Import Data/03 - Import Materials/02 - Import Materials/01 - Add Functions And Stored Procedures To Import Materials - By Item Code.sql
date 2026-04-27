If dbo.Validation_StoredProcedureExists('MaterialImport_ImportItemCategories') = 1
Begin
	Drop Procedure dbo.MaterialImport_ImportItemCategories
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
Create Procedure [dbo].[MaterialImport_ImportItemCategories]
As
Begin
	Declare @ErrorMessage Nvarchar (Max)
	Declare @ErrorSeverity Int
		
    --Set Nocount On
    
    Begin try
		Begin Transaction
		
		If Exists (Select * From Sys.databases As Databases Where Databases.name = 'Data_Import_RJ')
		Begin
		    If Exists(Select * From Data_Import_RJ.sys.objects As Objects Where Objects.name = 'TestImport0000_MaterialItemCategory')		    
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
		    	From Data_Import_RJ.dbo.TestImport0000_MaterialItemCategory As ItemCategoryInfo		    	
		    	Left Join dbo.ProductionItemCategory As ExistingItemCategory
		    	On	Ltrim(Rtrim(ItemCategoryInfo.Name)) = Ltrim(Rtrim(ExistingItemCategory.ItemCategory)) And
		    		Ltrim(Rtrim(ItemCategoryInfo.CategoryType)) = Ltrim(Rtrim(ExistingItemCategory.ProdItemCatType))
		    	Where	ExistingItemCategory.ProdItemCatID Is Null And
		    			ItemCategoryInfo.AutoID In
		    			(
		    				Select Min(ItemCategoryInfo.AutoID)
		    				From Data_Import_RJ.dbo.TestImport0000_MaterialItemCategory As ItemCategoryInfo
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

If dbo.Validation_FunctionExists('GetFormattedStringDateFromDateAsMMDDYYYY') = 1
Begin
    Drop function dbo.GetFormattedStringDateFromDateAsMMDDYYYY
End
Go

Set Ansi_nulls On
Go

Set Quoted_identifier On
Go
-- ================================================================================================
-- Author:		Robert Jansen
-- Create date: 06/02/2015
-- Description:	Return a String Date in the following format from a Date:
--					mm/dd/yyyy.
-- ================================================================================================
Create Function [dbo].[GetFormattedStringDateFromDateAsMMDDYYYY]
(
	@DateValue Datetime,
	@NullValue Nvarchar (40)
)
Returns Nvarchar (40)
As
Begin
	Declare @FormattedDate Nvarchar (40)
	
	If @DateValue Is Null
	Begin
	    Set @FormattedDate = @NullValue
	End
	Else
	Begin
	    Set @FormattedDate =
			Right('00' + Cast(Datepart(Month, @DateValue) As Nvarchar), 2) + '/' + 
			Right('00' + Cast(Datepart(Day, @DateValue) As Nvarchar), 2) + '/' +
			Right('0000' + Cast(Datepart(Year, @DateValue) As Nvarchar), 4)
	End
	
	Return @FormattedDate
End
Go

If dbo.Validation_FunctionExists('GetFormattedStringDateFromDateAsDDMMYYYY') = 1
Begin
    Drop function dbo.GetFormattedStringDateFromDateAsDDMMYYYY
End
Go

Set Ansi_nulls On
Go

Set Quoted_identifier On
Go
-- ================================================================================================
-- Author:		Robert Jansen
-- Create date: 06/02/2015
-- Description:	Return a String Date in the following format from a Date:
--					dd/mm/yyyy.
-- ================================================================================================
Create Function [dbo].[GetFormattedStringDateFromDateAsDDMMYYYY]
(
	@DateValue Datetime,
	@NullValue Nvarchar (40)
)
Returns Nvarchar (40)
As
Begin
	Declare @FormattedDate Nvarchar (40)
	
	If @DateValue Is Null
	Begin
	    Set @FormattedDate = @NullValue
	End
	Else
	Begin
	    Set @FormattedDate =
			Right('00' + Cast(Datepart(Day, @DateValue) As Nvarchar), 2) + '/' +
			Right('00' + Cast(Datepart(Month, @DateValue) As Nvarchar), 2) + '/' + 
			Right('0000' + Cast(Datepart(Year, @DateValue) As Nvarchar), 4)
	End
	
	Return @FormattedDate
End
Go

If dbo.Validation_StoredProcedureExists('Utility_Print') = 1
Begin
	Drop Procedure dbo.Utility_Print
End
Go

Set Ansi_nulls On
Go

Set Quoted_identifier On
Go
-- ================================================================================================
-- Author:		Robert Jansen
-- Create date: 11/18/2014
-- Description:	Print A Message
-- ================================================================================================
Create Procedure [dbo].[Utility_Print]
(
	@Message Nvarchar (Max)
)
As
Begin
	Declare @Statement Nvarchar (Max)
	
	Set @Statement = Isnull(@Message, '')
	
	Raiserror(@Statement, 0, 0) With Nowait
End
Go

If dbo.Validation_StoredProcedureExists('MaterialImport_ImportMaterials') = 1
Begin
	Drop Procedure dbo.MaterialImport_ImportMaterials
End
Go

Set Ansi_nulls On
Go

Set Quoted_identifier On
Go
-- ================================================================================================
-- Author:		Robert Jansen
-- Create date: 06/04/2015
-- Description:	Import Materials into the Yards and Plants
-- ================================================================================================
Create Procedure [dbo].[MaterialImport_ImportMaterials]
(
	@UpdateExistingProductionItems Bit,
	@UserID Int,
	@DeactivateMaterials Bit = 0
)
As
Begin
	Declare @ImportMaterialInfo Table
	(
		AutoID Bigint Identity (1, 1),
		PlantName Nvarchar (100),
		TradeName Nvarchar (100),
		MaterialDate Nvarchar (30),
		FamilyMaterialTypeName Nvarchar (100),
		MaterialTypeName Nvarchar (100),
		SpecificGravity Float,
		IsLiquidAdmix Nvarchar (30),
		MoisturePct Float,
		Cost Float,
		CostUnitName Nvarchar (30),
		ManufacturerName Nvarchar (100),
		ManufacturerSourceName Nvarchar (100),
		BatchingOrderNumber Nvarchar (100),
		ItemCode Nvarchar (100),
		ItemDescription Nvarchar (300),
		ItemShortDescription Nvarchar (100),
		ItemCategoryName Nvarchar (100),
		ItemCategoryDescription Nvarchar (300),
		ItemCategoryShortDescription Nvarchar (100),
		ComponentCategoryName Nvarchar (100),
		ComponentCategoryDescription Nvarchar (300),
		ComponentCategoryShortDescription Nvarchar (100),
		BatchPanelCode Nvarchar (100),
		IsBatchable Bit,
		FamilyMaterialTypeID Int,
		MaterialTypeID Int
	)
	
	Declare @PlantMaterialInfo Table
	(
		AutoID Bigint Identity (1, 1),
		MaterialAutoID Bigint,
		PlantID Int,
		PlantCode Nvarchar (30),
		PlantName Nvarchar (100)
	)
	
	Declare @MaterialInfo Table
	(
		AutoID Bigint Identity(1,1),
		PlantName Nvarchar (100),
		TradeName Nvarchar (100),
		MaterialDate Nvarchar (30),
		SpecificGravity Float,
		SpecificHeat Float,
		IsLiquidAdmix Nvarchar (30),
		MoisturePct Float,
		Cost Float,
		CostUnitName Nvarchar (30),
		BlaineFineness Float,
		Batchable Bit,
		ManufacturerName Nvarchar (100),
		ManufacturerSourceName Nvarchar (100),
		BatchingOrderNumber Nvarchar (100),
		ItemCode Nvarchar (100),
		ItemDescription Nvarchar (300),
		ItemShortDescription Nvarchar (100),
		ItemCategoryName Nvarchar (100),
		ItemCategoryDescription Nvarchar (300),
		ItemCategoryShortDescription Nvarchar (100),
		ComponentCategoryName Nvarchar (100),
		ComponentCategoryDescription Nvarchar (300),
		ComponentCategoryShortDescription Nvarchar (100),
		BatchPanelCode Nvarchar (100),
		IsBatchable Bit,
		FamilyMaterialTypeID Int,
		FamilyMaterialTypeName Nvarchar (100),
		MaterialTypeID Int,
		MaterialTypeName Nvarchar (100),
		ReportMaterialTypeID Int,
		ReportMaterialTypeName Nvarchar (100),
		PlantID Int,
		PlantCode Nvarchar (30),
		ConvertedDate Nvarchar (20),
		ConvertedCost Float,
		Code Nvarchar (20),
		CodePrefix Nvarchar (10),
		CodeDate Nvarchar (20),
		CodeSuffix Nvarchar (10),
		MaxCodeSuffix Nvarchar (20),
		MinAutoID BigInt
	)

	Declare @ProdItem Table
	(
		AutoID Int Identity (1, 1),
		ItemCode Nvarchar (100),
		Description Nvarchar (300),
		ShortDescription Nvarchar (100),
		ItemCategoryName Nvarchar (100),
		ComponentCategoryName Nvarchar (100)
	)
	
	Declare @ProductionSystem Nvarchar (100) = dbo.GetProductionSystem('')
	Declare @ShortDescrLength Int = Case when @ProductionSystem = 'Command' Then 16 Else 1000000 End
	Declare @PutCostsInMaterialHistory Bit
	Declare @AggregatesInYards Bit
	Declare @CurrentTimeStamp Datetime
	Declare @CodeDate Nvarchar (20)
	
	Declare @ErrorMessage Nvarchar (Max)
	Declare @ErrorSeverity Int
		
    --Set Nocount On
    
    Begin try
		Begin Transaction
		
		If Exists (Select * From Sys.databases As Databases Where Databases.name = 'Data_Import_RJ')
		Begin
		    If Exists(Select * From Data_Import_RJ.sys.objects Where Name = 'TestImport0000_MaterialInfo')
		    Begin
				Set @AggregatesInYards = IsNull(dbo.GetAggregatesInYards(), 0)
				Set @CurrentTimeStamp = Current_timestamp
				Set @CodeDate =	Right('00' + Cast(Year(@CurrentTimeStamp) As Nvarchar), 2) +
								Right('00' + Cast(Month(@CurrentTimeStamp) As Nvarchar), 2) +
								Right('00' + Cast(Day(@CurrentTimeStamp) As Nvarchar), 2)
				
				Set @PutCostsInMaterialHistory = 0
								
				If dbo.Validation_FunctionExists('GetMaterialCostsAreRetrievedFromHistory') = 1
				Begin
					Set @PutCostsInMaterialHistory = IsNull(dbo.GetMaterialCostsAreRetrievedFromHistory(), 0)
				End
								
				Exec dbo.Utility_Print ''
				Exec dbo.Utility_Print 'Import Materials'
				
				Exec dbo.Utility_Print ''
				Exec dbo.Utility_Print 'Retrieve Material Information That Might Be Imported'

		        Insert Into @ImportMaterialInfo
		        (
		            PlantName,
		            TradeName,
		            MaterialDate,
		            FamilyMaterialTypeName,
		            MaterialTypeName,
		            SpecificGravity,
		            IsLiquidAdmix,
		            MoisturePct,
		            Cost,
		            CostUnitName,
		            ManufacturerName,
		            ManufacturerSourceName,
		            BatchingOrderNumber,
		            ItemCode,
		            ItemDescription,
		            ItemShortDescription,
		            ItemCategoryName,
		            ItemCategoryDescription,
		            ItemCategoryShortDescription,
		            ComponentCategoryName,
		            ComponentCategoryDescription,
		            ComponentCategoryShortDescription,
		            BatchPanelCode,
		            IsBatchable,
		            FamilyMaterialTypeID, 
		            MaterialTypeID
		        )
		        Select  LTrim(RTrim(MaterialInfo.PlantName)),
		                LTrim(RTrim(MaterialInfo.TradeName)),
		                LTrim(RTrim(MaterialInfo.MaterialDate)),
		                LTrim(RTrim(MaterialInfo.FamilyMaterialTypeName)),
		                LTrim(RTrim(MaterialInfo.MaterialTypeName)),
		                LTrim(RTrim(MaterialInfo.SpecificGravity)),
		                LTrim(RTrim(MaterialInfo.IsLiquidAdmix)),
		                LTrim(RTrim(MaterialInfo.MoisturePct)),
		                LTrim(RTrim(MaterialInfo.Cost)),
		                LTrim(RTrim(MaterialInfo.CostUnitName)),
		                LTrim(RTrim(MaterialInfo.ManufacturerName)),
		                LTrim(RTrim(MaterialInfo.ManufacturerSourceName)),
		                Ltrim(Rtrim(MaterialInfo.BatchingOrderNumber)),
		                LTrim(RTrim(MaterialInfo.ItemCode)),
		                LTrim(RTrim(MaterialInfo.ItemDescription)),
		                LTrim(RTrim(MaterialInfo.ItemShortDescription)),
		                LTrim(RTrim(MaterialInfo.ItemCategoryName)),
		                LTrim(RTrim(MaterialInfo.ItemCategoryDescription)),
		                LTrim(RTrim(MaterialInfo.ItemCategoryShortDescription)),
		                LTrim(RTrim(MaterialInfo.ComponentCategoryName)),
		                LTrim(RTrim(MaterialInfo.ComponentCategoryDescription)),
		                LTrim(RTrim(MaterialInfo.ComponentCategoryShortDescription)),
		                LTrim(RTrim(MaterialInfo.BatchPanelCode)),
		                MaterialInfo.Batchable,
		                FamilyMaterialType.MaterialTypeID,
		                MaterialTypeInfo.MaterialTypeID
		        From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
				Inner Join dbo.MaterialType As FamilyMaterialType
				On	LTrim(RTrim(MaterialInfo.FamilyMaterialTypeName)) = FamilyMaterialType.MaterialType And
					FamilyMaterialType.MaterialTypeID In (1, 2, 3, 4, 5)
				Inner Join dbo.MaterialType As MaterialTypeInfo
				On LTrim(RTrim(MaterialInfo.MaterialTypeName)) = MaterialTypeInfo.MaterialType
		        Where	MaterialInfo.AutoID In
						(
							Select Min(MaterialInfo.AutoID)
							From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
							Left Join dbo.Plant As Plant
							On Ltrim(Rtrim(MaterialInfo.PlantName)) = Plant.PLNTNAME 
							Inner Join dbo.MaterialType As FamilyMaterialType
							On	LTrim(RTrim(MaterialInfo.FamilyMaterialTypeName)) = FamilyMaterialType.MaterialType And
								FamilyMaterialType.MaterialTypeID In (1, 2, 3, 4, 5)
							Inner Join dbo.MaterialType As MaterialTypeInfo
							On LTrim(RTrim(MaterialInfo.MaterialTypeName)) = MaterialTypeInfo.MaterialType
							Inner Join dbo.GetFamilyMaterialTypeInformation() As FamilyMaterialTypeData
							On MaterialTypeInfo.MaterialTypeID = FamilyMaterialTypeData.Static_MaterialTypeID
							Where	Ltrim(Rtrim(IsNull(MaterialInfo.PlantName, ''))) <> '' And
									Ltrim(Rtrim(IsNull(MaterialInfo.TradeName, ''))) <> '' And
									Ltrim(Rtrim(IsNull(MaterialInfo.ItemCode, ''))) <> '' And
									Isnull(MaterialInfo.SpecificGravity, -1.0) >= 0.01 And
									FamilyMaterialType.MaterialTypeID = FamilyMaterialTypeData.Family_Static_MaterialTypeID And
									(
										Ltrim(Rtrim(Isnull(MaterialInfo.PlantName, ''))) = 'ALL' Or
										Plant.PLANTIDENTIFIER Is Not Null
									)
							Group By	Ltrim(Rtrim(MaterialInfo.PlantName)),
										Ltrim(Rtrim(MaterialInfo.FamilyMaterialTypeName)),
										Ltrim(Rtrim(MaterialInfo.ItemCode))						
						)
		        Order By MaterialInfo.AutoID
		        
		        If @AggregatesInYards = 1
		        Begin
					Exec dbo.Utility_Print ''
					Exec dbo.Utility_Print 'Retrieve Specific Aggregate Yard Info'

					Insert into @PlantMaterialInfo
					(
		        		MaterialAutoID, 
		        		PlantID, 
		        		PlantCode, 
		        		PlantName
					)
					Select	MaterialInfo.AutoID,
							Case when Yard.PLANTIDENTIFIER Is Not null Then Yard.PLANTIDENTIFIER Else Plant.PLANTIDENTIFIER End,
							Case when Yard.PLANTIDENTIFIER Is Not null Then Yard.PLNTTAG Else Plant.PLNTTAG End,
							Case when Yard.PLANTIDENTIFIER Is Not null Then Yard.PLNTNAME Else Plant.PLNTNAME End
					From @ImportMaterialInfo As MaterialInfo
					Inner Join dbo.Plant As Plant
					On MaterialInfo.PlantName = Plant.PLNTNAME
					Left Join dbo.Plant As Yard
					On Plant.PlantIDForYard = Yard.PLANTIDENTIFIER
					Where	MaterialInfo.FamilyMaterialTypeID = 1 And
							MaterialInfo.PlantName <> 'ALL'

					Exec dbo.Utility_Print ''
					Exec dbo.Utility_Print 'Retrieve Yard Info For Aggregates That Should Be In All Yards'

					Insert into @PlantMaterialInfo
					(
		        		MaterialAutoID, 
		        		PlantID, 
		        		PlantCode, 
		        		PlantName
					)
					Select	MaterialInfo.AutoID,
							Yard.PLANTIDENTIFIER,
							Yard.PLNTTAG,
							Yard.PLNTNAME
					From @ImportMaterialInfo As MaterialInfo
					Cross Join dbo.Plant As Yard
					Where	MaterialInfo.FamilyMaterialTypeID = 1 And
							MaterialInfo.PlantName = 'ALL' And
							Yard.PlantKind = 'ConcreteYard'
		        End

				Exec dbo.Utility_Print ''
				Exec dbo.Utility_Print 'Retrieve Specific Material Plant Info'

				Insert into @PlantMaterialInfo
				(
	        		MaterialAutoID, 
	        		PlantID, 
	        		PlantCode, 
	        		PlantName
				)
				Select	MaterialInfo.AutoID,
						Plant.PLANTIDENTIFIER,
						Plant.PLNTTAG,
						Plant.PLNTNAME
				From @ImportMaterialInfo As MaterialInfo
				Inner Join dbo.Plant As Plant
				On MaterialInfo.PlantName = Plant.PLNTNAME
				Where	(
							MaterialInfo.FamilyMaterialTypeID In (2, 3, 4, 5) Or 
							MaterialInfo.FamilyMaterialTypeID = 1 And 
							@AggregatesInYards = 0
						) And
						MaterialInfo.PlantName <> 'ALL'

				Exec dbo.Utility_Print ''
				Exec dbo.Utility_Print 'Retrieve Plant Info For Materials That Should Be In All Plants'

				Insert into @PlantMaterialInfo
				(
	        		MaterialAutoID, 
	        		PlantID, 
	        		PlantCode, 
	        		PlantName
				)
				Select	MaterialInfo.AutoID,
						Plant.PLANTIDENTIFIER,
						Plant.PLNTTAG,
						Plant.PLNTNAME
				From @ImportMaterialInfo As MaterialInfo
				Cross Join dbo.Plant As Plant
				Where	(
							MaterialInfo.FamilyMaterialTypeID In (2, 3, 4, 5) Or 
							MaterialInfo.FamilyMaterialTypeID = 1 And 
							@AggregatesInYards = 0
						) And
						MaterialInfo.PlantName = 'ALL' And
						Plant.PlantKind = 'BatchPlant'

				Exec dbo.Utility_Print ''
				Exec dbo.Utility_Print 'Retrieve The Materials That Will Be Imported'

				Insert Into @MaterialInfo
				(
				    PlantName,
				    TradeName,
				    MaterialDate,
				    SpecificGravity,
				    SpecificHeat,
				    IsLiquidAdmix,
				    MoisturePct,
				    Cost,
				    CostUnitName,
				    BlaineFineness,
				    Batchable,
				    ManufacturerName,
				    ManufacturerSourceName,
				    BatchingOrderNumber,
				    ItemCode,
				    ItemDescription,
				    ItemShortDescription,
				    ItemCategoryName,
				    ItemCategoryDescription,
				    ItemCategoryShortDescription,
				    ComponentCategoryName,
				    ComponentCategoryDescription,
				    ComponentCategoryShortDescription,
				    BatchPanelCode,
				    IsBatchable,
				    FamilyMaterialTypeID,
				    FamilyMaterialTypeName,
				    MaterialTypeID,
				    MaterialTypeName,
				    ReportMaterialTypeID,
				    ReportMaterialTypeName,
				    PlantID,
				    PlantCode
				)
				Select	PlantMaterialInfo.PlantName,
						MaterialInfo.TradeName,
						Case 
						    When dbo.GetDBSetting_GlobalDateFormat('') = 'dd/mm/yyyy'
						    Then Case when Isdate(MaterialInfo.MaterialDate) = 1 Then dbo.GetFormattedStringDateFromDateAsDDMMYYYY(Cast(MaterialInfo.MaterialDate As Datetime), Null) Else dbo.GetFormattedStringDateFromDateAsDDMMYYYY(@CurrentTimeStamp, Null) End
						    Else Case when Isdate(MaterialInfo.MaterialDate) = 1 Then dbo.GetFormattedStringDateFromDateAsMMDDYYYY(Cast(MaterialInfo.MaterialDate As Datetime), Null) Else dbo.GetFormattedStringDateFromDateAsMMDDYYYY(@CurrentTimeStamp, Null) End
						End As MaterialDate,
						MaterialInfo.SpecificGravity,
						Case when MaterialInfo.FamilyMaterialTypeID In (3, 5) Then 4.18600005676216 Else 0.837200011352432 End,
						MaterialInfo.IsLiquidAdmix,
						MaterialInfo.MoisturePct,
						MaterialInfo.Cost, 
						MaterialInfo.CostUnitName,
						Case when MaterialInfo.FamilyMaterialTypeID = 2 Then 61.4448430867566 Else Null End,
						Null,
						MaterialInfo.ManufacturerName,
						MaterialInfo.ManufacturerSourceName,
						MaterialInfo.BatchingOrderNumber,
						MaterialInfo.ItemCode,
						MaterialInfo.ItemDescription,
						MaterialInfo.ItemShortDescription,
						MaterialInfo.ItemCategoryName,
						MaterialInfo.ItemCategoryDescription,
						MaterialInfo.ItemCategoryShortDescription,
						MaterialInfo.ComponentCategoryName,
						MaterialInfo.ComponentCategoryDescription,
						MaterialInfo.ComponentCategoryShortDescription,
						MaterialInfo.BatchPanelCode,
						MaterialInfo.IsBatchable,
						MaterialInfo.FamilyMaterialTypeID,
						MaterialInfo.FamilyMaterialTypeName,
						MaterialInfo.MaterialTypeID,
						MaterialInfo.MaterialTypeName,
						ReportMaterialTypeInfo.MaterialTypeID,
						ReportMaterialTypeInfo.MaterialType,
						PlantMaterialInfo.PlantID, 
						PlantMaterialInfo.PlantCode
				From @PlantMaterialInfo As PlantMaterialInfo
				Inner Join @ImportMaterialInfo As MaterialInfo
				On PlantMaterialInfo.MaterialAutoID = MaterialInfo.AutoID
				Inner Join
				(
					Select Min(ImportMaterialInfo.AutoID) As AutoID
					From @PlantMaterialInfo As PlantMaterialInfo
					Inner Join @ImportMaterialInfo As ImportMaterialInfo
					On PlantMaterialInfo.MaterialAutoID = ImportMaterialInfo.AutoID
					Group By	PlantMaterialInfo.PlantID,
								ImportMaterialInfo.FamilyMaterialTypeID,
								ImportMaterialInfo.ItemCode
				) As OneMaterialInfo
				On MaterialInfo.AutoID = OneMaterialInfo.AutoID
				Left Join
				(
					Select	Plants.PlantId As PlantID,
							FamilyMaterialTypeInfo.MaterialTypeID As FamilyMaterialTypeID,
							ItemNameInfo.Name As ItemCode,
							Min(Material.MATERIALIDENTIFIER) As MaterialID
					From dbo.Plants As Plants
					Inner Join dbo.MATERIAL As Material
					On Material.PlantID = Plants.PlantId
					Inner Join dbo.ItemMaster As ItemMaster
					On ItemMaster.ItemMasterID = Material.ItemMasterID
					Inner Join dbo.Name As ItemNameInfo
					On ItemNameInfo.NameID = ItemMaster.NameID
					Inner Join dbo.MaterialType As FamilyMaterialTypeInfo
					On Material.FamilyMaterialTypeID = FamilyMaterialTypeInfo.MaterialTypeID
					Group By	Plants.PlantId,
								FamilyMaterialTypeInfo.MaterialTypeID,
								ItemNameInfo.Name
				) As ExistingMaterial
				On	PlantMaterialInfo.PlantID = ExistingMaterial.PlantID And
					MaterialInfo.FamilyMaterialTypeID = ExistingMaterial.FamilyMaterialTypeID And
					MaterialInfo.ItemCode = ExistingMaterial.ItemCode
				Inner Join dbo.GetReportMaterialTypeInformation() As ReportMaterialTypeData
				On MaterialInfo.MaterialTypeID = ReportMaterialTypeData.Static_MaterialTypeID
				Inner Join dbo.MaterialType As ReportMaterialTypeInfo
				On ReportMaterialTypeData.Report_Static_MaterialTypeID = ReportMaterialTypeInfo.MaterialTypeID
				Where	ExistingMaterial.MaterialID Is Null
				Order By MaterialInfo.FamilyMaterialTypeID, PlantMaterialInfo.PlantID, MaterialInfo.ItemCode
				
				Exec dbo.Utility_Print ''
				Exec dbo.Utility_Print 'Retrieve Material Production Item Information'

				Insert into @ProdItem
				(
					ItemCode, 
					[Description], 
					ShortDescription, 
					ItemCategoryName,
					ComponentCategoryName
				)
				Select	MaterialInfo.ItemCode,
						MaterialInfo.ItemDescription,
						MaterialInfo.ItemShortDescription,
						MaterialInfo.ItemCategoryName,
						MaterialInfo.ComponentCategoryName
				From @MaterialInfo As MaterialInfo
				Where	MaterialInfo.AutoID In
						(
							Select Max(MaterialInfo.AutoID)
							From @MaterialInfo As MaterialInfo
							Where Isnull(MaterialInfo.ItemCode, '') <> ''
							Group By MaterialInfo.ItemCode
						)
		        
				Exec dbo.Utility_Print ''
				Exec dbo.Utility_Print 'Set Material Date, Code, and Cost Information'
				
				Update MaterialInfo
					Set MaterialInfo.ConvertedDate = MaterialInfo.MaterialDate, 
						MaterialInfo.CodePrefix = 
							Case
								When MaterialInfo.FamilyMaterialTypeID = 1
								Then 'A'
								When MaterialInfo.FamilyMaterialTypeID = 2
								Then 'C'
								When MaterialInfo.FamilyMaterialTypeID = 3
								Then 'H'
								When MaterialInfo.FamilyMaterialTypeID = 4
								Then 'M'
								When MaterialInfo.FamilyMaterialTypeID = 5
								Then 'W'
							End,
						CodeDate = @CodeDate,
						ConvertedCost = 
							Case
								When	IsNull(MaterialInfo.CostUnitName, '') Not In ('$//YD^3', '$/CY','CY', 'GA', 'GL', '$/GL', '$/gal', 'OZ', '$/oz', '$/TN', 'TN', '$/Ton', '$/LB', 'LB', '$/lb', 'TON', 'Tons', 'ml', 'Ml-liter', 'Liter', 'Liters', 'Litres', '$/liter', 'KG', '$/Kg', 'LT', 'L', 'LL', 'TM', 'MT', '$/MTon', '$/Metric Ton', 'Pounds', 'Fluid Oz', 'Gallons') Or 
										Isnull(MaterialInfo.Cost, -1.0) < 0.0 
								Then Null
								When IsNull(MaterialInfo.CostUnitName, '') In ('CY', '$/CY', '$//YD^3')
								Then MaterialInfo.Cost / 201.974026 * 264.17205 / (MaterialInfo.SpecificGravity * 1.0)
								When IsNull(MaterialInfo.CostUnitName, '') In ('GA', 'GL', '$/gal', '$/GL', 'Gallons')
								Then MaterialInfo.Cost * 264.17205 / (MaterialInfo.SpecificGravity * 1.0)
								When IsNull(MaterialInfo.CostUnitName, '') In ('OZ', 'Fluid Oz', '$/oz')
								Then MaterialInfo.Cost * 128.0 * 264.17205 / (MaterialInfo.SpecificGravity * 1.0)
								When IsNull(MaterialInfo.CostUnitName, '') In ('LB', '$/lb', 'Pounds', '$/LB')
								Then MaterialInfo.Cost * 2204.622719056
								When IsNull(MaterialInfo.CostUnitName, '') In ('TN', '$/Ton', 'TON', '$/TN', 'Tons')
								Then MaterialInfo.Cost * 1.102311359528
								When IsNull(MaterialInfo.CostUnitName, '') In ('Liter', 'Liters', 'Litres', 'LT', 'L', 'LL', '$/liter')
								Then MaterialInfo.Cost * 1000.0 / (MaterialInfo.SpecificGravity * 1.0)
								When IsNull(MaterialInfo.CostUnitName, '') In ('Ml-liter', 'ml')
								Then MaterialInfo.Cost * 1000.0 * 1000.0 / (MaterialInfo.SpecificGravity * 1.0)
								When IsNull(MaterialInfo.CostUnitName, '') In ('KG', '$/Kg')
								Then MaterialInfo.Cost * 1000.0
								When IsNull(MaterialInfo.CostUnitName, '') In ('TM', 'MT', '$/Metric Ton', '$/Metric Ton', '$/MTon')
								Then MaterialInfo.Cost 
							End
				From @MaterialInfo As MaterialInfo
				
				Exec dbo.Utility_Print ''
				Exec dbo.Utility_Print 'Set Max Code Suffixes'
				
				Update MaterialInfo
					Set MaterialInfo.MaxCodeSuffix = CodeInfo.MaxCodeSuffix
				From @MaterialInfo As MaterialInfo
				Left Join 
				(
					Select Material.FamilyMaterialTypeID, Max(Right(Material.CODE, 5)) As MaxCodeSuffix
					From dbo.MATERIAL As Material
					Where	Material.FamilyMaterialTypeID In (1, 2, 3, 4, 5) And
							Substring(Material.CODE, 2, 6) = @CodeDate
					Group By Material.FamilyMaterialTypeID 
				) As CodeInfo
				On MaterialInfo.FamilyMaterialTypeID = CodeInfo.FamilyMaterialTypeID
				
				Exec dbo.Utility_Print ''
				Exec dbo.Utility_Print 'Set Min Auto-Generated Numbers'
				
				Update MaterialInfo
					Set MaterialInfo.MinAutoID = AutoIDInfo.MinAutoID
				From @MaterialInfo As MaterialInfo
				Inner Join
				(
					Select MaterialInfo.FamilyMaterialTypeID, Min(MaterialInfo.AutoID) As MinAutoID
					From @MaterialInfo As MaterialInfo
					Group By MaterialInfo.FamilyMaterialTypeID
				) As AutoIDInfo
				On MaterialInfo.FamilyMaterialTypeID = AutoIDInfo.FamilyMaterialTypeID
				
				Exec dbo.Utility_Print ''
				Exec dbo.Utility_Print 'Set Code Suffixes'
				
				Update MaterialInfo
					Set MaterialInfo.CodeSuffix =
							Right
							(
								'00000' + 
								Cast
								(
									Case 
										when MaterialInfo.MaxCodeSuffix Is Null 
										Then 0 
										Else Cast(MaterialInfo.MaxCodeSuffix As Int) + 1
									End +
									(MaterialInfo.AutoID - MaterialInfo.MinAutoID) As Nvarchar
								),
								5
							)
				From @MaterialInfo As MaterialInfo
				
				Exec dbo.Utility_Print ''
				Exec dbo.Utility_Print 'Set Up Codes'
				
				Update MaterialInfo
					Set MaterialInfo.Code = MaterialInfo.CodePrefix + MaterialInfo.CodeDate + MaterialInfo.CodeSuffix
				From @MaterialInfo As MaterialInfo
				
				Exec dbo.Utility_Print ''
				Exec dbo.Utility_Print 'Show Materials that might be imported'
				
				Select * 
				From @MaterialInfo
				Order By AutoID
				
				--/*
				
				Exec dbo.Utility_Print ''
				Exec dbo.Utility_Print 'Add Material Item Codes'
				
				Insert into dbo.Name
				(
					Name,
					MaterialTypeID,
					NameType
				)
				Select MaterialInfo.ItemCode, Min(MaterialInfo.MaterialTypeID), 'MtrlItem'					
				From @MaterialInfo As MaterialInfo
				Left Join dbo.Name As Name
				On MaterialInfo.ItemCode = Name.Name 
				Where	Name.NameID Is Null And
						Isnull(MaterialInfo.ItemCode, '') <> ''
				Group By MaterialInfo.ItemCode
				Order By MaterialInfo.ItemCode
					
				Exec dbo.Utility_Print ''
				Exec dbo.Utility_Print 'Add Material Batch Panel Codes'

				Insert into dbo.Name
				(
					Name,
					MaterialTypeID,
					NameType
				)
				Select MaterialInfo.BatchPanelCode, Min(MaterialInfo.MaterialTypeID), 'MtrlBatchCode'					
				From @MaterialInfo As MaterialInfo
				Left Join dbo.Name As Name
				On MaterialInfo.BatchPanelCode = Name.Name 
				Where Isnull(MaterialInfo.BatchPanelCode, '') <> '' And Name.NameID Is Null
				Group By MaterialInfo.BatchPanelCode
				Order By MaterialInfo.BatchPanelCode
					
				Exec dbo.Utility_Print ''
				Exec dbo.Utility_Print 'Add Trade Names'

				Insert into dbo.Name
				(
					Name,
					MaterialTypeID,
					NameType
				)
				Select MaterialInfo.TradeName, Min(MaterialInfo.MaterialTypeID), 'Mtrl'					
				From @MaterialInfo As MaterialInfo
				Left Join dbo.Name As Name
				On MaterialInfo.TradeName = Name.Name 
				Where	Name.NameID Is Null And 
						Isnull(MaterialInfo.TradeName, '') <> ''
				Group By MaterialInfo.TradeName
				Order By MaterialInfo.TradeName
				
				Exec dbo.Utility_Print ''
				Exec dbo.Utility_Print 'Add Material Descriptions'
				
				Insert into dbo.[Description]
				(
					[Description],
					MaterialTypeID,
					DescriptionType
				)
				Select MaterialInfo.ItemDescription, Min(MaterialInfo.MaterialTypeID), 'MtrlItem'					
				From @MaterialInfo As MaterialInfo
				Left Join dbo.[Description] As ItemDescr
				On MaterialInfo.ItemDescription = ItemDescr.[Description]
				Where	Isnull(MaterialInfo.ItemDescription, '') <> '' And 
						ItemDescr.DescriptionID Is Null
				Group By MaterialInfo.ItemDescription
				Order By MaterialInfo.ItemDescription
				
				Exec dbo.Utility_Print ''
				Exec dbo.Utility_Print 'Add Manufacturers'
				
				Insert into dbo.Manufacturer
				(
					Name
				)
				Select MaterialInfo.ManufacturerName
				From @MaterialInfo As MaterialInfo
				Left Join dbo.Manufacturer As Manufacturer
				On MaterialInfo.ManufacturerName = Manufacturer.Name				
				Where	Manufacturer.ManufacturerID Is null And
						Isnull(MaterialInfo.ManufacturerName, '') <> ''
				Group By MaterialInfo.ManufacturerName
				
				Exec dbo.Utility_Print ''
				Exec dbo.Utility_Print 'Add Manufacturer Sources'
				
				Insert into dbo.ManufacturerSource
				(
					Name,
					ManufacturerID
				)
				Select MaterialInfo.ManufacturerSourceName, Manufacturer.ManufacturerID
				From @MaterialInfo As MaterialInfo
				Inner Join dbo.Manufacturer As Manufacturer
				On MaterialInfo.ManufacturerName = Manufacturer.Name
				Left Join dbo.ManufacturerSource As ManufacturerSource
				On	ManufacturerSource.ManufacturerID = Manufacturer.ManufacturerID And 
					MaterialInfo.ManufacturerSourceName = ManufacturerSource.Name
				Where	ManufacturerSource.ManufacturerSourceID Is Null And
						Isnull(MaterialInfo.ManufacturerSourceName, '') <> ''
				Group By Manufacturer.ManufacturerID, MaterialInfo.ManufacturerSourceName 
					
				Exec dbo.Utility_Print ''
				Exec dbo.Utility_Print 'Add Material Item Categories'
				
				Insert into dbo.ProductionItemCategory
				(
					ItemCategory, 
					[Description], 
					ShortDescription, 
					ProdItemCatType
				)
				Select	MaterialInfo.ItemCategoryName,
						Case 
							when Isnull(MaterialInfo.ItemCategoryDescription, '') <> '' 
							Then MaterialInfo.ItemCategoryDescription 
							Else MaterialInfo.ItemCategoryName
						End,
						Case 
							when Isnull(MaterialInfo.ItemCategoryShortDescription, '') <> '' 
							Then MaterialInfo.ItemCategoryShortDescription 
							when Isnull(MaterialInfo.ItemCategoryDescription, '') <> '' 
							Then MaterialInfo.ItemCategoryDescription 
							Else MaterialInfo.ItemCategoryName
						End,
						'Mtrl'
				From @MaterialInfo As MaterialInfo
				Left Join dbo.ProductionItemCategory As ItemCategoryInfo
				On	MaterialInfo.ItemCategoryName = ItemCategoryInfo.ItemCategory And
					ItemCategoryInfo.ProdItemCatType = 'Mtrl'
				Where	ItemCategoryInfo.ProdItemCatID Is Null And
						MaterialInfo.AutoID In
						(
							Select Min(MaterialInfo.AutoID)
							From @MaterialInfo As MaterialInfo
							Where	Isnull(MaterialInfo.ItemCategoryName, '') <> ''
							Group By MaterialInfo.ItemCategoryName
						)

				Exec dbo.Utility_Print ''
				Exec dbo.Utility_Print 'Add Material Component Item Categories'
				
				Insert into dbo.ProductionItemCategory
				(
					ItemCategory, 
					[Description], 
					ShortDescription, 
					ProdItemCatType
				)
				Select	MaterialInfo.ComponentCategoryName,
						Case 
							when Isnull(MaterialInfo.ComponentCategoryDescription, '') <> '' 
							Then MaterialInfo.ComponentCategoryDescription 
							Else MaterialInfo.ComponentCategoryName
						End,
						Case 
							when Isnull(MaterialInfo.ComponentCategoryShortDescription, '') <> '' 
							Then MaterialInfo.ComponentCategoryShortDescription
							when Isnull(MaterialInfo.ComponentCategoryDescription, '') <> '' 
							Then MaterialInfo.ComponentCategoryDescription 
							Else MaterialInfo.ComponentCategoryName
						End,
						'MtrlCompType'
				From @MaterialInfo As MaterialInfo
				Left Join dbo.ProductionItemCategory As ItemCategoryInfo
				On	MaterialInfo.ComponentCategoryName = ItemCategoryInfo.ItemCategory And
					ItemCategoryInfo.ProdItemCatType = 'MtrlCompType'
				Where	ItemCategoryInfo.ProdItemCatID Is Null And
						MaterialInfo.AutoID In
						(
							Select Min(MaterialInfo.AutoID)
							From @MaterialInfo As MaterialInfo
							Where	Isnull(MaterialInfo.ComponentCategoryName, '') <> ''
							Group By MaterialInfo.ComponentCategoryName
						)
				
				If Isnull(@UpdateExistingProductionItems, 0) = 1
				Begin
					Exec dbo.Utility_Print ''
					Exec dbo.Utility_Print 'Set In-Sync Materials With Production Item Changes To Out-Of-Sync'
					
					Update Material
						Set Material.ProductionStatus = 'OutOfSync'
					From dbo.MATERIAL As Material
					Inner Join dbo.ItemMaster As ItemMaster
					On ItemMaster.ItemMasterID = Material.ItemMasterID
					Inner Join dbo.Name As ItemCodeInfo
					On ItemCodeInfo.NameID = ItemMaster.NameID
					Left Join dbo.[Description] As ItemDescrInfo
					On ItemDescrInfo.DescriptionID = ItemMaster.DescriptionID
					Left Join dbo.ProductionItemCategory As ItemCategoryInfo
					On ItemCategoryInfo.ProdItemCatID = ItemMaster.ProdItemCatID
					Left Join dbo.ProductionItemCategory As ComponentCategoryInfo
					On ComponentCategoryInfo.ProdItemCatID = ItemMaster.ProdItemCompTypeID
					Inner Join @ProdItem As ProdItem
					On ItemCodeInfo.Name = ProdItem.ItemCode
					Where	Material.ProductionStatus In ('InSync', 'Sent') And
							(
								Isnull(ItemDescrInfo.[Description], '') <> Isnull(ProdItem.[Description], '') Or
								Isnull(ItemMaster.ItemShortDescription, '') <> 
								Case 
									When Isnull(ProdItem.ShortDescription, '') <> '' 
									Then Ltrim(Rtrim(Left(ProdItem.ShortDescription, @ShortDescrLength)))
									Else Ltrim(Rtrim(Left(Isnull(ProdItem.[Description], ''), @ShortDescrLength)))
								End Or
								Isnull(ItemCategoryInfo.ItemCategory, '') <> Isnull(ProdItem.ItemCategoryName, '') Or
								Isnull(ComponentCategoryInfo.ItemCategory, '') <> Isnull(ProdItem.ComponentCategoryName, '')
							)
							
					Exec dbo.Utility_Print ''
					Exec dbo.Utility_Print 'Update Existing Material Production Items'
					
					Update ItemMaster
						Set ItemMaster.DescriptionID = ItemDescrInfo.DescriptionID,
							ItemMaster.ItemShortDescription =
								Case 
									When Isnull(ProdItem.ShortDescription, '') <> '' 
									Then Ltrim(Rtrim(Left(ProdItem.ShortDescription, @ShortDescrLength)))
									Else Ltrim(Rtrim(Left(ProdItem.[Description], @ShortDescrLength)))
								End,
							ItemMaster.ProdItemCatID = ItemCategoryInfo.ProdItemCatID,
							ItemMaster.ProdItemCompTypeID = ComponentCategoryInfo.ProdItemCatID
					From dbo.ItemMaster As ItemMaster
					Inner Join dbo.Name As ItemCodeInfo
					On	ItemCodeInfo.NameID = ItemMaster.NameID And
						ItemMaster.ItemType = 'Mtrl'
					Inner Join @ProdItem As ProdItem
					On ItemCodeInfo.Name = ProdItem.ItemCode
					Left Join dbo.[Description] As ItemDescrInfo
					On ProdItem.[Description] = ItemDescrInfo.[Description]
					Left Join dbo.ProductionItemCategory As ItemCategoryInfo
					On	ProdItem.ItemCategoryName = ItemCategoryInfo.ItemCategory And
						ItemCategoryInfo.ProdItemCatType = 'Mtrl'
					Left Join dbo.ProductionItemCategory As ComponentCategoryInfo
					On	ProdItem.ComponentCategoryName = ComponentCategoryInfo.ItemCategory And
						ComponentCategoryInfo.ProdItemCatType = 'MtrlCompType'
				End
				
				Exec dbo.Utility_Print ''
				Exec dbo.Utility_Print 'Add Production Item Information'
				
				Insert into dbo.ItemMaster
				(
					NameID,
					DescriptionID,
					ItemShortDescription,
					ProdItemCatID,
					ProdItemCompTypeID,
					ItemType
				)
				Select	ItemCodeInfo.NameID,
						ItemDescr.DescriptionID,
						Case
							When Isnull(ProdItem.ShortDescription, '') <> ''
							Then LTrim(RTrim(Left(ProdItem.ShortDescription, @ShortDescrLength)))
							Else LTrim(RTrim(Left(ProdItem.[Description], @ShortDescrLength)))
						End,
						ItemCategoryInfo.ProdItemCatID,
						ComponentCategoryInfo.ProdItemCatID,
						'Mtrl'
				From @ProdItem As ProdItem
				Inner Join dbo.Name As ItemCodeInfo
				On ProdItem.ItemCode = ItemCodeInfo.Name
				Left Join dbo.ItemMaster As ItemMaster
				On ItemMaster.NameID = ItemCodeInfo.NameID
				Left Join dbo.[Description] As ItemDescr
				On ProdItem.[Description] = ItemDescr.[Description]
				Left Join dbo.ProductionItemCategory As ItemCategoryInfo
				On	ProdItem.ItemCategoryName = ItemCategoryInfo.ItemCategory And
					ItemCategoryInfo.ProdItemCatType = 'Mtrl'
				Left Join dbo.ProductionItemCategory As ComponentCategoryInfo
				On	ProdItem.ComponentCategoryName = ComponentCategoryInfo.ItemCategory And
					ComponentCategoryInfo.ProdItemCatType = 'MtrlCompType'
				Where	ItemMaster.NameID Is Null
				
				Exec dbo.Utility_Print ''
				Exec dbo.Utility_Print 'Add Material Information'
				
				Insert into dbo.Material
				(
					PlantID, 
					PLANTCODE, 
					FamilyMaterialTypeID, 
					CODE, 
					NameID, 
					DescriptionID, 
					DATE, 
					ManufacturerID,
					ManufacturerSourceID,
					MaterialTypeLink,
					ReportMaterialTypeID,
					Type, 
					SpecGr, 
					SpecHt, 
					COST,
					Moisture, 
					Blaine,
					ItemMasterID,
					BatchPanelNameID,
					BatchPanelDescription,					
					BatchingOrder,
					Inactive,
					NonBatchable
				)
				Select	MaterialInfo.PlantID,
						MaterialInfo.PlantCode,
						MaterialInfo.FamilyMaterialTypeID,
						MaterialInfo.Code,
						TradeNameInfo.NameID,
						Case when ItemMaster.ItemMasterID Is Null Then MtrlDescr.DescriptionID Else ItemDescr.DescriptionID End,
						MaterialInfo.ConvertedDate,
						Manufacturer.ManufacturerID,
						ManufacturerSource.ManufacturerSourceID,
						MaterialInfo.MaterialTypeID,
						MaterialInfo.ReportMaterialTypeID,
						MaterialInfo.ReportMaterialTypeName,
						MaterialInfo.SpecificGravity,
						MaterialInfo.SpecificHeat,
						MaterialInfo.ConvertedCost,
						Case
							When	dbo.Validation_StringValueIsTrue(MaterialInfo.IsLiquidAdmix) = 1 And 
									Isnull(MaterialInfo.MoisturePct, -1.0) >= 0.01
							Then	MaterialInfo.MoisturePct / 100.0
							When	dbo.Validation_StringValueIsTrue(MaterialInfo.IsLiquidAdmix) = 1 And 
									Isnull(MaterialInfo.MoisturePct, -1.0) < 0.01							
							Then	1E-08
							Else	0.0
						End,
						MaterialInfo.BlaineFineness,
						ItemMaster.ItemMasterID,
						Case
							When PanelCodeInfo.NameID Is Not Null
							Then PanelCodeInfo.NameID
							Else Null --ItemCodeInfo.NameID
						End,
						ItemDescr.[Description],
						MaterialInfo.BatchingOrderNumber,
						Case when Isnull(@DeactivateMaterials, 0) = 1 Then 1 Else Null End As Inactive, 
						0
				From @MaterialInfo As MaterialInfo
				Inner Join dbo.Name As TradeNameInfo
				On MaterialInfo.TradeName = TradeNameInfo.Name
				Left Join dbo.Name As ItemCodeInfo
				On MaterialInfo.ItemCode = ItemCodeInfo.Name
				Left Join dbo.ItemMaster As ItemMaster
				On	ItemMaster.NameID = ItemCodeInfo.NameID And
					ItemMaster.ItemType = 'Mtrl'
				Left Join dbo.[Description] As ItemDescr
				On ItemMaster.DescriptionID = ItemDescr.DescriptionID
				Left Join dbo.[Description] As MtrlDescr
				On MaterialInfo.ItemDescription = MtrlDescr.[Description]
				Left Join dbo.Manufacturer As Manufacturer
				On MaterialInfo.ManufacturerName = Manufacturer.Name
				Left Join dbo.ManufacturerSource As ManufacturerSource
				On	ManufacturerSource.ManufacturerID = Manufacturer.ManufacturerID And
					MaterialInfo.ManufacturerSourceName = ManufacturerSource.Name
				Left Join dbo.Name As PanelCodeInfo
				On MaterialInfo.BatchPanelCode = PanelCodeInfo.Name
							
				Exec dbo.Utility_Print ''
				Exec dbo.Utility_Print 'Add Aggregate Information'
					
				Insert into dbo.Aggregate 
				(
					MaterialID
				)
				Select Material.MATERIALIDENTIFIER
				From dbo.MATERIAL As Material
				Inner Join @MaterialInfo As MaterialInfo
				On Material.CODE = MaterialInfo.Code
				Left Join dbo.[Aggregate] As Aggregate
				On Aggregate.MaterialID = Material.MATERIALIDENTIFIER
				Where	Material.FamilyMaterialTypeID = 1 And
						Aggregate.AggregateID Is Null
				Group By Material.MATERIALIDENTIFIER
				Order By Material.MATERIALIDENTIFIER
				
				If	@PutCostsInMaterialHistory = 1					
				Begin
					If dbo.Validation_DatabaseTemporaryTableExists('#MaterialCostInfo') = 1
					Begin
					    Drop table #MaterialCostInfo
					End
					
					Create table #MaterialCostInfo
					(
						MaterialID Int,
						Cost Float
					)					
					
					Exec dbo.Utility_Print ''
					Exec dbo.Utility_Print 'Retrieve Material Cost Information'
					
					Insert into #MaterialCostInfo (MaterialID, Cost)
						Select	Material.MATERIALIDENTIFIER, MaterialInfo.ConvertedCost
						From @MaterialInfo As MaterialInfo
						Inner Join dbo.MATERIAL As Material
						On MaterialInfo.Code = Material.CODE
						Where MaterialInfo.ConvertedCost Is Not Null
					
					If @UserID Is Null
					Begin
					    Set @UserID = 5
					End	
					
					Exec dbo.Utility_Print ''
					Exec dbo.Utility_Print 'Put The Material Costs In The Cost History'
					
					Exec dbo.iMagine_Cost_InsertOrUpdateMaterialHistoryCostsFromSimpleInfoInTempTable '#MaterialCostInfo', 'MaterialID', 'Cost', @UserID				

					Exec dbo.Utility_Print ''
					Exec dbo.Utility_Print 'The Material Costs Were Put In The Cost History'
					
					If dbo.Validation_DatabaseTemporaryTableExists('#MaterialCostInfo') = 1
					Begin
					    Drop table #MaterialCostInfo
					End
				End

		    	Exec dbo.Utility_Print ''
		    	Exec dbo.Utility_Print 'Update the Types for Item Codes'
		    	
				Update ItemName
					Set ItemName.NameType = 'MtrlItem'
				From dbo.Name As ItemName
				Inner Join dbo.ItemMaster As ItemMaster
				On ItemMaster.NameID = ItemName.NameID
				Where	ItemMaster.ItemType = 'Mtrl' And
						ItemName.NameType In ('Mtrl', 'MtrlBatchCode')
						
		    	Exec dbo.Utility_Print ''
		    	Exec dbo.Utility_Print 'Update the Types for Batch Panel Codes'
		    	
				Update PanelNameInfo
					Set PanelNameInfo.NameType = 'MtrlBatchCode'
				From dbo.Name As PanelNameInfo
				Inner Join dbo.MATERIAL As Material
				On Material.BatchPanelNameID = PanelNameInfo.NameID
				Left Join dbo.ItemMaster As ItemMaster
				On ItemMaster.NameID = PanelNameInfo.NameID
				Where	ItemMaster.ItemMasterID Is Null And
						IsNull(PanelNameInfo.NameType, '') In ('Mtrl', 'MtrlItem')
				
		    	Exec dbo.Utility_Print ''
		    	Exec dbo.Utility_Print 'Update the Types for Item Descriptions'
		    	
				Update ItemDescription
					Set ItemDescription.DescriptionType = 'MtrlItem'
				From dbo.[Description] As ItemDescription
				Inner Join dbo.ItemMaster As ItemMaster
				On ItemMaster.DescriptionID = ItemDescription.DescriptionID
				Where	ItemMaster.ItemType = 'Mtrl' And
						ItemDescription.DescriptionType In ('Mtrl')
				--*/
			End
		End
		
		Commit Transaction
		
		Exec dbo.Utility_Print ''
		Exec dbo.Utility_Print 'The Materials May Have Been Imported.'
    End Try
    Begin catch
		If @@TRANCOUNT > 0
		Begin
		    Rollback Transaction
		    
		    Exec dbo.Utility_Print ''
		    Exec dbo.Utility_Print 'The Transaction Was Rolled Back'
		End
		
		Select	@ErrorMessage = Error_message(),
				@ErrorSeverity = Error_severity()

		Exec dbo.Utility_Print ''
		Exec dbo.Utility_Print 'The Materials could not be imported.  The Transaction was rolled back.'
		Print 'Error Severity - ' + Cast(@ErrorSeverity As Nvarchar) + '.  Error Message: ' + @ErrorMessage

		Raiserror(@ErrorMessage, @ErrorSeverity, 1)
    End Catch
End
Go
