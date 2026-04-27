If  ObjectProperty(Object_ID(N'[dbo].[ACIBatchViewDetails]'), N'IsUserTable') = 1 And
    Exists (Select * From Data_Import_RJ.sys.objects Where Name = 'TestImport0000_MaterialInfo') And
    Db_name() In ('', '')
Begin
	Declare @ProductionSystem Nvarchar (50) = dbo.GetProductionSystem('')
	
	Declare @ErrorMessage Nvarchar (Max)
	Declare @ErrorSeverity Int
	
	Declare @MaterialInfo Table 
	(
		AutoID Int Identity (1, 1) Index IX_MaterialInfo_AutoID Unique,
		PlantCode Nvarchar (100) Index IX_MaterialInfo_PlantCode,
		TradeName Nvarchar (100) Index IX_MaterialInfo_TradeName,
		ItemCode Nvarchar (100) Index IX_MaterialInfo_ItemCode,
		ItemDescription Nvarchar (300) Index IX_MaterialInfo_ItemDescription,
		ItemShortDescription Nvarchar (100),
		ItemCategoryName Nvarchar (100) Index IX_MaterialInfo_ItemCategoryName,
		ItemCategoryDescription Nvarchar (300),
		ItemCategoryShortDescription Nvarchar (100),
		FamilyMaterialTypeID Int Index IX_MaterialInfo_FamilyMaterialTypeID,
		MaterialTypeID Int Index IX_MaterialInfo_MaterialTypeID,
		MaterialTypeName Nvarchar (100),		
		Cost Float,
		CostUnitName Nvarchar (100),
		CurrentCost Float,
		ConvertedCost Float,
		ManufacturerName Nvarchar (100),
		ManufacturerSourceName Nvarchar (100),
		SpecificGravity Float,
		CurSpecificGravity Float,
		BatchPanelCode Nvarchar (100),
		MaterialID Int Index IX_MaterialInfo_MaterialID,
		CurManufacturerID Int,
		ManufacturerID Int,
		ManufacturerSourceID Int
	)
	
	Declare @ProdItem Table
	(
		AutoID Int Identity (1, 1) Index IX_ProdItem_AutoID Unique,
		ItemCode Nvarchar (100) Index IX_ProdItem_ItemCode Unique,
		ItemDescription Nvarchar (300),
		ItemShortDescription Nvarchar (100),
		ItemCategoryName Nvarchar (100),
		ItemMasterID Int,
		ItemNameID Int,
		ItemDescriptionID Int,
		ItemCategoryID Int
	)
	
	Begin Try
		Begin Transaction

        Raiserror('', 0, 0) With Nowait
		Raiserror('Update Material Properties', 0, 0) With Nowait
		
		If dbo.Validation_DatabaseTemporaryTableExists('#MixInfo') = 1
		Begin
		    Drop table #MixInfo
		End
		
		Create table #MixInfo
		(
			MixID Int Index IX_MixInfo_MixID
		)
		
		If dbo.Validation_DatabaseTemporaryTableExists('#BatchInfo') = 1
		Begin
		    Drop table #BatchInfo
		End
		
		Create table #BatchInfo
		(
			BatchID Int Index IX_BatchInfo_BatchID
		)
		
		Insert into @MaterialInfo 
		(   
            PlantCode, TradeName, ItemCode, ItemDescription, ItemShortDescription, ItemCategoryName, 
            ItemCategoryDescription, ItemCategoryShortDescription, MaterialTypeID, MaterialTypeName, 
            SpecificGravity, Cost, CostUnitName, ManufacturerName, ManufacturerSourceName, BatchPanelCode
		)
		Select MaterialInfo.PlantName, MaterialInfo.TradeName,
		       MaterialInfo.ItemCode, MaterialInfo.ItemDescription,
		       MaterialInfo.ItemShortDescription, MaterialInfo.ItemCategoryName,
		       MaterialInfo.ItemCategoryDescription,
		       MaterialInfo.ItemCategoryShortDescription, 
		       MaterialType.Static_MaterialTypeID, MaterialInfo.MaterialTypeName, 
		       MaterialInfo.SpecificGravity, MaterialInfo.Cost, MaterialInfo.CostUnitName, 
		       MaterialInfo.ManufacturerName, MaterialInfo.ManufacturerSourceName, MaterialInfo.BatchPanelCode
		From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
		Left Join dbo.Static_MaterialType As MaterialType
		On MaterialInfo.MaterialTypeName = MaterialType.Name
		Where   MaterialInfo.AutoID In
		        (
		        	Select Min(MaterialInfo.AutoID)
		        	From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
		        	Where   Isnull(MaterialInfo.PlantName, '') <> '' And
		        	        Isnull(MaterialInfo.TradeName, '') <> '' And
		        	        Isnull(MaterialInfo.ItemCode, '') <> ''
		            Group By MaterialInfo.PlantName, MaterialInfo.ItemCode		        	     
		        )
        Order By MaterialInfo.AutoID
        
        Update MaterialInfo
            Set MaterialInfo.MaterialID = Material.MATERIALIDENTIFIER,
                MaterialInfo.FamilyMaterialTypeID = Material.FamilyMaterialTypeID,
                MaterialInfo.CurSpecificGravity = Material.SPECGR,
                MaterialInfo.CurrentCost = Material.COST,
                MaterialInfo.CurManufacturerID = Material.ManufacturerID
        From @MaterialInfo As MaterialInfo
        Inner Join dbo.Plants As Plant
        On MaterialInfo.PlantCode = Plant.Name
        Inner Join dbo.Name As ItemName
        On MaterialInfo.ItemCode = ItemName.Name
        Inner Join dbo.ItemMaster As ItemMaster
        On ItemMaster.NameID = ItemName.NameID
        Inner Join dbo.MATERIAL As Material
        On  Material.PlantID = Plant.PlantId And
            Material.ItemMasterID = ItemMaster.ItemMasterID
            
        Update MaterialInfo
			Set	ConvertedCost = 
					Case
						When	IsNull(MaterialInfo.CostUnitName, '') Not In ('ml', 'li', '/m', 'to', 'CY', '/y', 'GL', 'GA', '$/gal', 'OZ', 'Dry Oz', '$/Dry Oz', 'TN', '$/Ton', 'LB', '$/lb', 'TON', 'Liter', 'Liters', 'Litres', '$/liter', 'KG', '$/Kg', 'LT', 'L', 'LL', 'TM', 'MT', '$/MTon') Or 
								Isnull(MaterialInfo.Cost, -1.0) < 0.0 
						Then Null
						When IsNull(MaterialInfo.CostUnitName, '') In ('CY', '/y')
						Then MaterialInfo.Cost / 201.974026 * 264.17205 / (MaterialInfo.SpecificGravity * 1.0)
						When IsNull(MaterialInfo.CostUnitName, '') In ('GL', '$/gal', 'GA')
						Then MaterialInfo.Cost * 264.17205 / (MaterialInfo.SpecificGravity * 1.0)
						When IsNull(MaterialInfo.CostUnitName, '') In ('OZ')
						Then MaterialInfo.Cost * 128.0 * 264.17205 / (MaterialInfo.SpecificGravity * 1.0)
						When IsNull(MaterialInfo.CostUnitName, '') In ('LB', '$/lb')
						Then MaterialInfo.Cost * 2204.622719056
						When IsNull(MaterialInfo.CostUnitName, '') In ('Dry Oz', '$/Dry Oz')
						Then MaterialInfo.Cost * 16.0 * 2204.622719056
						When IsNull(MaterialInfo.CostUnitName, '') In ('TN', '$/Ton', 'TON')
						Then MaterialInfo.Cost * 1.102311359528
						When IsNull(MaterialInfo.CostUnitName, '') In ('li','Liter', 'Liters', 'Litres', 'LT', 'L', 'LL', '$/liter')
						Then MaterialInfo.Cost * 1000.0 / (MaterialInfo.SpecificGravity * 1.0)

						When IsNull(MaterialInfo.CostUnitName, '') In ('ml')
						Then MaterialInfo.Cost * 1000.0 * 1000.0 / (MaterialInfo.SpecificGravity * 1.0)

						When IsNull(MaterialInfo.CostUnitName, '') In ('/m', 'm3', '/m3', '$/m3')
						Then MaterialInfo.Cost * 0.001 * 1000.0 / (MaterialInfo.SpecificGravity * 1.0)

						When IsNull(MaterialInfo.CostUnitName, '') In ('KG', '$/Kg')
						Then MaterialInfo.Cost * 1000.0
						When IsNull(MaterialInfo.CostUnitName, '') In ('to', 'TM', 'MT', '$/Metric Ton', '$/MTon')
						Then MaterialInfo.Cost 
					End        
        From @MaterialInfo As MaterialInfo

        Insert into #MixInfo (MixID)
        Select Mix.BATCHIDENTIFIER
        From dbo.Batch As Mix
        Inner Join dbo.MaterialRecipe As Recipe
        On Recipe.EntityID = Mix.BATCHIDENTIFIER And Mix.NameID Is Not Null
        Inner Join @MaterialInfo As MaterialInfo
        On MaterialInfo.MaterialID = Recipe.MaterialID
        Where   (
        	        Isnull(MaterialInfo.SpecificGravity, -1.0) >= 0.1 And
                    Isnull(MaterialInfo.SpecificGravity, -1.0) <> Isnull(MaterialInfo.CurSpecificGravity, -1.0) And                
                    MaterialInfo.FamilyMaterialTypeID In (1, 2, 4)
                ) Or
                (
                    Isnull(MaterialInfo.Cost, -1.0) >= 0.001 And 
                    Round(Isnull(MaterialInfo.ConvertedCost, -1.0), 6) <> Round(Isnull(MaterialInfo.CurrentCost, -1.0), 6)
                )
        Group By Mix.BATCHIDENTIFIER
        
        Insert into #BatchInfo (BatchID)
        Select Batch.BATCHIDENTIFIER
        From dbo.Batch As Batch
        Inner Join dbo.MaterialRecipe As Recipe
        On Recipe.EntityID = Batch.BATCHIDENTIFIER And Batch.NameID Is Null
        Inner Join @MaterialInfo As MaterialInfo
        On MaterialInfo.MaterialID = Recipe.MaterialID
        Where   (
        	        Isnull(MaterialInfo.SpecificGravity, -1.0) >= 0.1 And
                    Isnull(MaterialInfo.SpecificGravity, -1.0) <> Isnull(MaterialInfo.CurSpecificGravity, -1.0) And                
                    MaterialInfo.FamilyMaterialTypeID In (1, 2, 4)
                ) Or
                (
                    Isnull(MaterialInfo.Cost, -1.0) >= 0.001 And 
                    Round(Isnull(MaterialInfo.ConvertedCost, -1.0), 6) <> Round(Isnull(MaterialInfo.CurrentCost, -1.0), 6)
                )
        Group By Batch.BATCHIDENTIFIER
        
        Insert into dbo.Manufacturer (Name)
        Select MaterialInfo.ManufacturerName
        From @MaterialInfo As MaterialInfo
        Left Join dbo.Manufacturer As Manufacturer
        On MaterialInfo.ManufacturerName = Manufacturer.Name
        Where Manufacturer.ManufacturerID Is Null And Isnull(MaterialInfo.ManufacturerName, '') <> ''
        Group By MaterialInfo.ManufacturerName
        Order By MaterialInfo.ManufacturerName
        
        Update MaterialInfo
            Set MaterialInfo.ManufacturerID = Manufacturer.ManufacturerID
        From @MaterialInfo As MaterialInfo
        Inner Join dbo.Manufacturer As Manufacturer
        On MaterialInfo.ManufacturerName = Manufacturer.Name
        
        Insert into dbo.ManufacturerSource (Name, ManufacturerID)
        Select MaterialInfo.ManufacturerSourceName, MaterialInfo.ManufacturerID
        From @MaterialInfo As MaterialInfo
        Left Join dbo.ManufacturerSource As ManufacturerSource
        On  MaterialInfo.ManufacturerID = ManufacturerSource.ManufacturerID And
            MaterialInfo.ManufacturerSourceName = ManufacturerSource.Name
        Where   Isnull(MaterialInfo.ManufacturerID, -1) > 0 And
                Isnull(MaterialInfo.ManufacturerSourceName, '') <> '' And
                ManufacturerSource.ManufacturerSourceID Is Null
        Group By MaterialInfo.ManufacturerID, MaterialInfo.ManufacturerSourceName
        Order By MaterialInfo.ManufacturerID, MaterialInfo.ManufacturerSourceName	
        
        Update MaterialInfo
            Set MaterialInfo.ManufacturerSourceID = ManufacturerSource.ManufacturerSourceID
        From @MaterialInfo As MaterialInfo
        Inner Join dbo.ManufacturerSource As ManufacturerSource
        On  MaterialInfo.ManufacturerID = ManufacturerSource.ManufacturerID And
            MaterialInfo.ManufacturerSourceName = ManufacturerSource.Name
                
        Insert into @ProdItem (ItemCode, ItemDescription, ItemShortDescription, ItemCategoryName)
        Select  MaterialInfo.ItemCode, 
                Max(MaterialInfo.ItemDescription), 
                Max(MaterialInfo.ItemShortDescription), 
                Max(MaterialInfo.ItemCategoryName)
        From @MaterialInfo As MaterialInfo
        Where Isnull(MaterialInfo.ItemCode, '') <> ''
        Group By MaterialInfo.ItemCode
        Order By MaterialInfo.ItemCode
        
        Insert into dbo.Name (Name, MaterialTypeID, NameType)
        Select MaterialInfo.BatchPanelCode, Max(MaterialInfo.MaterialTypeID), 'MtrlBatchCode'
        From @MaterialInfo As MaterialInfo
        Left Join dbo.Name As PanelCode
        On MaterialInfo.BatchPanelCode = PanelCode.Name
        Where PanelCode.NameID Is Null And Isnull(MaterialInfo.BatchPanelCode, '') <> ''
        Group By MaterialInfo.BatchPanelCode
        Order By MaterialInfo.BatchPanelCode
        
        Insert into dbo.Name (Name, MaterialTypeID, NameType)
        Select MaterialInfo.TradeName, Max(MaterialInfo.MaterialTypeID), 'Mtrl'
        From @MaterialInfo As MaterialInfo
        Left Join dbo.Name As TradeNameInfo
        On MaterialInfo.TradeName = TradeNameInfo.Name
        Where TradeNameInfo.NameID Is Null And Isnull(MaterialInfo.TradeName, '') <> ''
        Group By MaterialInfo.TradeName
        Order By MaterialInfo.TradeName
        
        Insert into dbo.Description ([Description], MaterialTypeID, DescriptionType)
        Select MaterialInfo.ItemDescription, Max(MaterialInfo.MaterialTypeID), 'MtrlItem'
        From @MaterialInfo As MaterialInfo
        Left Join dbo.[Description] As MtrlDescr
        On MaterialInfo.ItemDescription = MtrlDescr.[Description]
        Where MtrlDescr.DescriptionID Is Null And Isnull(MaterialInfo.ItemDescription, '') <> ''
        Group By MaterialInfo.ItemDescription
        Order By MaterialInfo.ItemDescription
        
        Insert into dbo.ProductionItemCategory (ItemCategory, [Description], ShortDescription, ProdItemCatType)
        Select MaterialInfo.ItemCategoryName, Max(MaterialInfo.ItemCategoryDescription), Max(MaterialInfo.ItemCategoryShortDescription), 'Mtrl'
        From @MaterialInfo As MaterialInfo
        Left Join dbo.ProductionItemCategory As CategoryInfo
        On MaterialInfo.ItemCategoryName = CategoryInfo.ItemCategory And CategoryInfo.ProdItemCatType = 'Mtrl'
        Where CategoryInfo.ProdItemCatID Is Null And Isnull(MaterialInfo.ItemCategoryName, '') <> ''
        Group By MaterialInfo.ItemCategoryName
        Order By MaterialInfo.ItemCategoryName
        
        Update ProdItem 
            Set ProdItem.ItemShortDescription = 
                    Case 
                        When Isnull(@ProductionSystem, '') = 'Command'
                        Then Ltrim(Rtrim(Left(ProdItem.ItemDescription, 16)))
                        Else Ltrim(Rtrim(ProdItem.ItemDescription))
                    End
        From @ProdItem As ProdItem
        Where   Isnull(ProdItem.ItemDescription, '') <> '' And
                Isnull(ProdItem.ItemShortDescription, '') = ''

        Update ProdItem 
            Set ProdItem.ItemShortDescription = Ltrim(Rtrim(Left(ProdItem.ItemShortDescription, 16)))
        From @ProdItem As ProdItem
        Where @ProductionSystem = 'Command'
        
        Update ProdItem
            Set ProdItem.ItemNameID = ItemName.NameID
        From @ProdItem As ProdItem
        Inner Join dbo.Name As ItemName
        On ProdItem.ItemCode = ItemName.Name
        
        Update ProdItem
            Set ProdItem.ItemMasterID = ItemMaster.ItemMasterID
        From @ProdItem As ProdItem
        Inner Join dbo.ItemMaster As ItemMaster
        On  ProdItem.ItemNameID = ItemMaster.NameID And
            ItemMaster.ItemType = 'Mtrl' 

        Update ProdItem
            Set ProdItem.ItemDescriptionID = ItemDescr.DescriptionID
        From @ProdItem As ProdItem
        Inner Join dbo.[Description] As ItemDescr
        On ProdItem.ItemDescription = ItemDescr.[Description] 

        Update ProdItem
            Set ProdItem.ItemCategoryID = CategoryInfo.ProdItemCatID
        From @ProdItem As ProdItem
        Inner Join dbo.ProductionItemCategory As CategoryInfo
        On  ProdItem.ItemCategoryName = CategoryInfo.ItemCategory And
            CategoryInfo.ProdItemCatType = 'Mtrl'
        /*
        Update ItemMaster
            Set ItemMaster.DescriptionID =
                    Case
                        When Isnull(ProdItem.ItemDescriptionID, -1) < 1
                        Then ItemMaster.DescriptionID
                        Else ProdItem.ItemDescriptionID
                    End,
                ItemMaster.ProdItemCatID =
                    Case
                        When Isnull(ProdItem.ItemCategoryID, -1) < 1
                        Then ItemMaster.ProdItemCatID
                        Else ProdItem.ItemCategoryID
                    End,
                ItemMaster.ItemShortDescription =
                    Case
                        When Isnull(ProdItem.ItemShortDescription, '') = ''
                        Then ItemMaster.ItemShortDescription
                        Else ProdItem.ItemShortDescription
                    End
        From dbo.ItemMaster As ItemMaster
        Inner Join @ProdItem As ProdItem
        On ProdItem.ItemMasterID = ItemMaster.ItemMasterID
        */
        Update Material
            Set /*Material.NameID = 
                    Case
                        When Isnull(TradeNameInfo.NameID, -1) < 1
                        Then Material.NameID
                        Else TradeNameInfo.NameID
                    End,
                Material.DescriptionID = ItemDescr.DescriptionID,    
                Material.MaterialTypeLink = 
                    Case
                        When Isnull(MaterialInfo.MaterialTypeID, -1) > 0
                        Then MaterialInfo.MaterialTypeID
                        Else Material.MaterialTypeLink
                    End,
                Material.ReportMaterialTypeID =
                    Case
                        When Isnull(MaterialInfo.MaterialTypeID, -1) > 0
                        Then ReportMaterialType.Static_MaterialTypeID
                        Else Material.ReportMaterialTypeID
                    End,
                Material.[TYPE] =
                    Case
                        When Isnull(MaterialInfo.MaterialTypeID, -1) > 0
                        Then ReportMaterialType.Name
                        Else Material.[TYPE]
                    End,
                Material.SPECGR =
                    Case
                        When    Material.FamilyMaterialTypeID In (1, 2, 4) And 
                                Isnull(MaterialInfo.SpecificGravity, -1.0) >= 0.1 And 
                                Isnull(Material.SPECGR, -1.0) <> Isnull(MaterialInfo.SpecificGravity, -1.0)
                        Then MaterialInfo.SpecificGravity
                        Else Material.SPECGR
                    End,*/
                Material.COST =
                    Case
                        When Isnull(Material.Cost, -1.0) > 0.0001 And Isnull(MaterialInfo.ConvertedCost, -1.0) <= 0.0001
                        Then Material.COST
                        When Isnull(MaterialInfo.ConvertedCost, -1.0) < 0.0
                        Then Material.Cost
                        Else MaterialInfo.ConvertedCost
                    End/*,          
                Material.ManufacturerID =
                    Case
                        When Isnull(MaterialInfo.ManufacturerID, -1) > 0
                        Then MaterialInfo.ManufacturerID
                        Else Material.ManufacturerID
                    End,
                Material.ManufacturerSourceID =
                    Case
                        When Isnull(MaterialInfo.ManufacturerSourceID, -1) > 0
                        Then MaterialInfo.ManufacturerSourceID
                        When    Isnull(MaterialInfo.ManufacturerID, -1) < 1 Or 
                                Isnull(MaterialInfo.ManufacturerID, -1) = Isnull(MaterialInfo.CurManufacturerID, -1)
                        Then Material.ManufacturerSourceID
                        Else Null
                    End,
                Material.BatchPanelNameID =
                    Case
                        When Isnull(PanelCode.NameID, -1) < 1
                        Then Material.BatchPanelNameID
                        Else PanelCode.NameID
                    End,
                Material.BatchPanelDescription = ItemDescr.[Description]--,*/
                /*
                Material.ProductionStatus = 
                    Case 
                        When Isnull(Material.ProductionStatus, '') In ('InSync', 'Sent') 
                        Then 'OutOfSync' 
                        Else Material.ProductionStatus 
                    End                    
                */
        From dbo.Material As Material
        Inner Join @MaterialInfo As MaterialInfo
        On Material.MATERIALIDENTIFIER = MaterialInfo.MaterialID
        Inner Join dbo.ItemMaster As ItemMaster
        On ItemMaster.ItemMasterID = Material.ItemMasterID
        Left Join dbo.[Description] As ItemDescr
        On ItemDescr.DescriptionID = ItemMaster.DescriptionID
        Left Join dbo.Name As TradeNameInfo
        On  MaterialInfo.TradeName = TradeNameInfo.Name And
            TradeNameInfo.NameType In ('Mtrl', 'MtrlItem', 'MtrlBatchCode')
        Left Join dbo.Name As PanelCode
        On  MaterialInfo.BatchPanelCode = PanelCode.Name And
            PanelCode.NameType In ('Mtrl', 'MtrlItem', 'MtrlBatchCode')
        Left Join dbo.GetReportMaterialTypeInformation() As ReportInfo
        On MaterialInfo.MaterialTypeID = ReportInfo.Static_MaterialTypeID
        Left Join dbo.Static_MaterialType As ReportMaterialType
        On ReportInfo.Report_Static_MaterialTypeID = ReportMaterialType.Static_MaterialTypeID
                
        --Exec dbo.Mix_CalcTheoAndMeasCalcsByMixIDTempTable '#MixInfo', 'MixID', 1.5, 0
        
        If dbo.GetMaterialCostsAreRetrievedFromHistory() = 0
        Begin
            Exec dbo.Mix_CalcMaterialCostsByMixIDTempTable
        	    @MixIDTempTableName = '#MixInfo',
        	    @MixIDFieldName = 'MixID',
        	    @AirContent = 1.5,
        	    @UseMeasYield = 0        
        End
        
        --Exec dbo.Batch_CalcTheoAndMeasCalcsByBatchIDTempTable '#BatchInfo', 'BatchID', 1.5, 1

        If dbo.GetMaterialCostsAreRetrievedFromHistory() = 0
        Begin
            Exec dbo.Batch_CalcMaterialCostsByBatchIDTempTable '#BatchInfo', 'BatchID', 1.5, 1
        End
        
		Raiserror('', 0, 0) With Nowait
		Raiserror('Remove Unlinked Production Items', 0, 0) With Nowait

		Delete ItemMaster
		From dbo.ItemMaster As ItemMaster
		Left Join dbo.BATCH As Mix
		On Mix.ItemMasterID = ItemMaster.ItemMasterID
		Left Join dbo.MATERIAL As Material
		On Material.ItemMasterID = ItemMaster.ItemMasterID
		Where	Mix.BATCHIDENTIFIER Is Null And
				Material.MATERIALIDENTIFIER Is Null

		Raiserror('', 0, 0) With Nowait
		Raiserror('Test Error.  Stop Transaction.', 18, 1) With Nowait
		
		Commit Transaction
	    
		Raiserror('', 0, 0) With Nowait
		Raiserror('One or more Materials may have been imported.', 0, 0) With Nowait
	End Try
	Begin catch
		If @@TRANCOUNT > 0
		Begin
			Rollback Transaction
		End

		Select	@ErrorMessage = Error_message(),
				@ErrorSeverity = Error_severity()

		Raiserror('', 0, 0) With Nowait
		Raiserror('The Materials could not be imported.  The Import was rolled back.', 0, 0) With Nowait
		Print 'Error Severity - ' + Cast(@ErrorSeverity As Nvarchar) + '.  Error Message: ' + @ErrorMessage
	End Catch
End
