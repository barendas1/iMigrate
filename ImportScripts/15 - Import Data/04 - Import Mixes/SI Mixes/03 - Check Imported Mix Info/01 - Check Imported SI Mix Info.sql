Declare @MixesShouldBeDeactivated Bit = 0
Declare @CheckForMatchingRecipeQuantities Bit = 0

Select	Plants.Name,
		MixNameInfo.Name,
		MixInfo.StrengthAge, 
		MixInfo.Strength,
		StrengthSpec.AgeMaxValue, 
		StrengthSpec.StrengthMaxValue
From dbo.Plants As Plants
Inner Join dbo.BATCH As Mix
On Mix.Plant_Link = Plants.PlantId
Inner Join dbo.Name As MixNameInfo
On MixNameInfo.NameID = Mix.NameID
Inner Join Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
On	Plants.Name = MixInfo.PlantCode And
	MixNameInfo.Name = MixInfo.MixCode
Inner Join
(
	Select Min(MixInfo.AutoID) As AutoID
	From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
	Group By MixInfo.PlantCode, MixInfo.MixCode
) As FirstMix
On FirstMix.AutoID = MixInfo.AutoID
Left Join dbo.RptMixSpecAgeComprStrengths As StrengthSpec
On Mix.MixSpecID = StrengthSpec.MixSpecID And StrengthSpec.AgeMinValue = MixInfo.StrengthAge
Where	Isnull(MixInfo.StrengthAge, -1.0) <> Isnull(StrengthSpec.AgeMaxValue, -1.0) Or
		Isnull(MixInfo.Strength, -1.0) <> Isnull(StrengthSpec.StrengthMaxValue, -1.0) 

Select	Plants.Name,
		MixNameInfo.Name,
		ItemName.Name,
		Mix.BatchPanelCode,
		MixInfo.MixCode,
		MixInfo.MixDescription As ExpectedDescription,
		MixInfo.MixShortDescription As ExportedShortDescription,
		MixDescription.[Description],
		ItemDescription.[Description],
		Mix.BatchPanelDescription,
		ItemMaster.ItemShortDescription,
		MixInfo.MixShortDescription,
		ItemCategoryInfo.ItemCategory,
		MixInfo.ItemCategory,
		MixInfo.AirContent,
		MixInfo.MinAirContent, 
		MixInfo.MaxAirContent,
		Mix.AIR,
		AirContentSpec.MinAirContent, 
		AirContentSpec.MaxAirContent,
		MixInfo.Slump, 
		MixInfo.MinSlump, 
		MixInfo.MaxSlump,
		Round(Mix.SLUMP, 6),
		SlumpSpec.MinSlump, 
		SlumpSpec.MaxSlump,
		Mix.MixTargetSpread,
		SpreadSpec.MinSpread, 
		SpreadSpec.MaxSpread,
		MixInfo.Price,
		Mix.COST5,
		MixInfo.PriceUnitName,
		MixInfo.MixInactive,
		Mix.MixInactive,
		MixInfo.MaximumWater,
		Mix.MaxWaterQuantity As CurrentMaxWaterQuantity,
		MixInfo.MinWCRatio,
		MixInfo.MaxWCRatio,
		MixInfo.MinWCMRatio,
		MixInfo.MaxWCMRatio,
		WCRatio.MinRatio,
		WCRatio.MaxRatio,
		WCMRatio.MinRatio,
		WCMRatio.MaxRatio
From dbo.Plants As Plants
Inner Join dbo.BATCH As Mix
On Mix.Plant_Link = Plants.PlantId
Inner Join dbo.Name As MixNameInfo
On MixNameInfo.NameID = Mix.NameID
Inner Join Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
On	Plants.Name = MixInfo.PlantCode And
	MixNameInfo.Name = MixInfo.MixCode
Inner Join
(
	Select Min(MixInfo.AutoID) As AutoID
	From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
	Group By MixInfo.PlantCode, MixInfo.MixCode
) As FirstMix
On FirstMix.AutoID = MixInfo.AutoID
Left Join dbo.[Description] As MixDescription
On MixDescription.DescriptionID = Mix.DescriptionID
Left Join dbo.ItemMaster As ItemMaster
On ItemMaster.ItemMasterID = Mix.ItemMasterID
Left Join dbo.Name As ItemName
On ItemName.NameID = ItemMaster.NameID
Left Join dbo.[Description] As ItemDescription
On ItemDescription.DescriptionID = ItemMaster.DescriptionID
Left Join dbo.ProductionItemCategory As ItemCategoryInfo
On	MixInfo.ItemCategory = ItemCategoryInfo.ItemCategory And
	ItemCategoryInfo.ProdItemCatType = 'Mix'
Left Join dbo.RptMixSpecAirContent As AirContentSpec
On Mix.MixSpecID = AirContentSpec.MixSpecID
Left Join dbo.RptMixSpecSlump As SlumpSpec
On Mix.MixSpecID = SlumpSpec.MixSpecID
Left Join dbo.RptMixSpecSpreadInfo As SpreadSpec
On Mix.MixSpecID = SpreadSpec.MixSpecID
Left Join dbo.ViewMixSpecMtrlTypeRatio_WaterToCement As WCRatio
On Mix.MixSpecID = WCRatio.MixSpecID
Left Join dbo.ViewMixSpecMtrlTypeRatio_WaterToCementitious As WCMRatio
On Mix.MixSpecID = WCMRatio.MixSpecID
Where	Ltrim(Rtrim(Isnull(MixInfo.MixCode, ''))) <> Ltrim(Rtrim(Isnull(ItemName.Name, ''))) Or
		Ltrim(Rtrim(Isnull(MixInfo.MixCode, ''))) <> Ltrim(Rtrim(Isnull(Mix.BatchPanelCode, ''))) Or
		Ltrim(Rtrim(Isnull(MixInfo.MixDescription, ''))) <> Ltrim(Rtrim(Isnull(MixDescription.[Description], ''))) Or
		Ltrim(Rtrim(Isnull(MixInfo.MixDescription, ''))) <> Ltrim(Rtrim(Isnull(ItemDescription.[Description], ''))) Or
		Ltrim(Rtrim(Isnull(MixInfo.MixDescription, ''))) <> Ltrim(Rtrim(Isnull(Mix.BatchPanelDescription, ''))) Or
		Ltrim(Rtrim(Isnull(MixInfo.ItemCategory, ''))) <> Ltrim(Rtrim(Isnull(ItemCategoryInfo.ItemCategory, ''))) Or
		Case When Ltrim(Rtrim(Isnull(MixInfo.MixShortDescription, ''))) <> '' Then RTrim(Left(Ltrim(Rtrim(Isnull(MixInfo.MixShortDescription, ''))), (Case when dbo.GetProductionSystem('') = 'Command' Then 16 Else 1000000 End))) Else RTrim(Left(Ltrim(Rtrim(Isnull(MixInfo.MixDescription, ''))), (Case when dbo.GetProductionSystem('') = 'Command' Then 16 Else 1000000 End))) End <> Ltrim(Rtrim(Isnull(ItemMaster.ItemShortDescription, ''))) Or
		Round(Isnull(MixInfo.AirContent, 1.5), 8) <> Round(Isnull(Mix.AIR, -1.0), 8) Or
		Round(Isnull(MixInfo.MinAirContent, -1.0), 8) <> Round(Isnull(AirContentSpec.MinAirContent, -1.0), 8) Or
		Round(Isnull(MixInfo.MaxAirContent, -1.0), 8) <> Round(Isnull(AirContentSpec.MaxAirContent, -1.0), 8) Or
		(Round(Isnull(MixInfo.Slump, -1.0), 6) <= 12.0 * 25.4 And Round(Isnull(MixInfo.MinSlump, -1.0), 6) <= 12.0 * 25.4 And Round(Isnull(MixInfo.MaxSlump, -1.0), 6) <= 12.0 * 25.4) And
		(
			Round(Isnull(MixInfo.Slump, -1.0), 6) <> Round(Isnull(Mix.SLUMP, -1.0), 6) Or
			Isnull(MixInfo.MinSlump, -1.0) <> Isnull(SlumpSpec.MinSlump, -1.0) Or
			Isnull(MixInfo.MaxSlump, -1.0) <> Isnull(SlumpSpec.MaxSlump, -1.0)
		) Or
		(Round(Isnull(MixInfo.Slump, -1.0), 6) > 12.0 * 25.4 Or Round(Isnull(MixInfo.MinSlump, -1.0), 6) > 12.0 * 25.4 Or Round(Isnull(MixInfo.MaxSlump, -1.0), 6) > 12.0 * 25.4) And
		(
			Round(Isnull(MixInfo.Slump, -1.0), 6) <> Round(Isnull(Mix.MixTargetSpread, -1.0), 6) Or
			Isnull(MixInfo.MinSlump, -1.0) <> Isnull(SpreadSpec.MinSpread, -1.0) Or
			Isnull(MixInfo.MaxSlump, -1.0) <> Isnull(SpreadSpec.MaxSpread, -1.0)
		) Or
		Isnull(MixInfo.MaxLoadSize, -1.0) > 0.0 And 
		Round(Isnull(MixInfo.MaxLoadSize, -1.0), 8) <> Round(Isnull(Mix.MaximumBatchSize, -1.0), 8) Or
		Isnull(MixInfo.MaximumWater, -1.0) > 0.0 And 
		Round(Isnull(MixInfo.MaximumWater, -1.0), 8) <> Round(Isnull(Mix.MaxWaterQuantity, -1.0), 8) Or
		Isnull(MixInfo.SackContent, -1.0) > 0.0 And 
		Round(Isnull(MixInfo.SackContent, -1.0), 8) <> Round(Isnull(Mix.SackContent, -1.0), 8) Or
	    Isnull(MixInfo.Price, -1.0) > 0.0 And Isnull(MixInfo.PriceUnitName, '') In ('m3', 'METRES') And 
	    Round(Isnull(MixInfo.Price, -1.0) * 1.0, 8) <> Round(Isnull(Mix.COST5, -1.0), 8) Or
	    Isnull(@MixesShouldBeDeactivated, 0) = 0 And dbo.Validation_StringValueIsTrue(Isnull(MixInfo.MixInactive, '')) <> Isnull(Mix.MixInactive, 0) Or
	    Isnull(@MixesShouldBeDeactivated, 0) = 1 And Isnull(Mix.MixInactive, 0) <> 1 Or
	    Isnull(MixInfo.MinWCRatio, -1.0) >= 0.0 And Isnull(MixInfo.MinWCRatio, -1.0) <> Isnull(WCRatio.MinRatio, -1.0) Or
		Isnull(MixInfo.MaxWCRatio, -1.0) >= 0.0 And Isnull(MixInfo.MaxWCRatio, -1.0) <> Isnull(WCRatio.MaxRatio, -1.0) Or
	    Isnull(MixInfo.MinWCMRatio, -1.0) >= 0.0 And Isnull(MixInfo.MinWCMRatio, -1.0) <> Isnull(WCMRatio.MinRatio, -1.0) Or
		Isnull(MixInfo.MaxWCMRatio, -1.0) >= 0.0 And Isnull(MixInfo.MaxWCMRatio, -1.0) <> Isnull(WCMRatio.MaxRatio, -1.0) 
		
Declare @CementitiousInfo Table
(
	MixID Int Primary Key,
	TotalQuantity Float
)

Insert into @CementitiousInfo (MixID, TotalQuantity)
	Select MaterialRecipe.EntityID, Sum(Isnull(MaterialRecipe.Quantity, 0.0))
	From dbo.MaterialRecipe As MaterialRecipe
	Inner Join dbo.MATERIAL As Material
	On Material.MATERIALIDENTIFIER = MaterialRecipe.MaterialID
	Where	Material.FamilyMaterialTypeID In (2, 4) And
			MaterialRecipe.EntityType = 'Mix'
	Group By MaterialRecipe.EntityID
		
Select	Plants.Name,
		MixNameInfo.Name,
		MixRecipe.MaterialItemCode, 
		MixRecipe.MaterialItemDescription,
		MixRecipe.Quantity, 
		MixRecipe.QuantityUnitName
From dbo.Plants As Plants
Inner Join dbo.Batch As Mix
On Mix.Plant_Link = Plants.PlantId
Inner Join dbo.Name As MixNameInfo
On MixNameInfo.NameID = Mix.NameID
Left Join @CementitiousInfo As CementitiousInfo
On Mix.BATCHIDENTIFIER = CementitiousInfo.MixID
Inner Join dbo.MaterialRecipe As MaterialRecipe
On MaterialRecipe.EntityID = Mix.BATCHIDENTIFIER
Inner Join dbo.MATERIAL As Material
On Material.MATERIALIDENTIFIER = MaterialRecipe.MaterialID
Inner Join dbo.ItemMaster As MtrlProdItem
On MtrlProdItem.ItemMasterID = Material.ItemMasterID
Inner Join dbo.Name As MtrlItemCode
On MtrlItemCode.NameID = MtrlProdItem.NameID
Inner Join Data_Import_RJ.dbo.TestImport0000_MixInfo AS MixRecipe
On	Plants.Name = MixRecipe.PlantCode And
	MixNameInfo.Name = MixRecipe.MixCode And
	MtrlItemCode.Name = MixRecipe.MaterialItemCode
Where	Isnull(@CheckForMatchingRecipeQuantities, 0) = 0 And
        Round(IsNull(MixRecipe.Quantity, -1.0), 6) <>
		Case
			When Isnull(MaterialRecipe.QUANTITY, -1.0) < 0.0 Or Isnull(MixRecipe.QuantityUnitName, '') = ''
			Then -1.0
			When MixRecipe.QuantityUnitName In ('CW', 'oz/cwt CM', 'OZ/CWT')
			Then Round(MaterialRecipe.QUANTITY * 100.0 / (Material.SPECGR * 0.0651984837440621 * CementitiousInfo.TotalQuantity), 6)
			When MixRecipe.QuantityUnitName In ('GA', 'GL', 'GAL', 'GALLONS')
			Then Round(MaterialRecipe.QUANTITY * 0.26417205 / (Material.SPECGR * 1.0), 6)
			When MixRecipe.QuantityUnitName In ('LB', 'Pounds')
			Then Round(MaterialRecipe.QUANTITY * 2.204622476, 6)
			When MixRecipe.QuantityUnitName In ('OZ', 'LQ OZ', 'Ounces', 'fl oz', 'Fluid Oz')
			Then Round(MaterialRecipe.QUANTITY / (Material.SPECGR * 0.0651984837440621 * 0.45359240000781), 6)
			When MixRecipe.QuantityUnitName = 'KG'
			Then Round(MaterialRecipe.QUANTITY, 6)
			When MixRecipe.QuantityUnitName = 'GR'
			Then Round(MaterialRecipe.QUANTITY, 6) * 1000.0
			When MixRecipe.QuantityUnitName In ('L', 'LT', 'Liters', 'Litre')
			Then Round(MaterialRecipe.QUANTITY / Material.SPECGR / 1.0, 6)
			When MixRecipe.QuantityUnitName In ('ML', 'CC', 'Ml-liter', 'Bag', 'BG', 'DS')
			Then Round(MaterialRecipe.QUANTITY / Material.SPECGR / 1.0 * 1000.0, 6)
			When MixRecipe.QuantityUnitName In ('Each', 'EA')
			Then Round(MaterialRecipe.QUANTITY, 6)
			When MixRecipe.QuantityUnitName In ('Cubic Yards')
			Then Round(MaterialRecipe.QUANTITY / (201.974026 * Material.SPECGR * 1.0) * 0.26417205, 6)
			Else -1.0
		End Or
        Isnull(@CheckForMatchingRecipeQuantities, 0) = 1 And
        Round(IsNull(MixRecipe.Quantity, -1.0), 6) =
		Case
			When Isnull(MaterialRecipe.QUANTITY, -1.0) < 0.0 Or Isnull(MixRecipe.QuantityUnitName, '') = ''
			Then -1.0
			When MixRecipe.QuantityUnitName In ('CW', 'oz/cwt CM', 'OZ/CWT')
			Then Round(MaterialRecipe.QUANTITY * 100.0 / (Material.SPECGR * 0.0651984837440621 * CementitiousInfo.TotalQuantity), 6)
			When MixRecipe.QuantityUnitName In ('GA', 'GL', 'GAL', 'GALLONS')
			Then Round(MaterialRecipe.QUANTITY * 0.26417205 / (Material.SPECGR * 1.0), 6)
			When MixRecipe.QuantityUnitName In ('LB', 'Pounds')
			Then Round(MaterialRecipe.QUANTITY * 2.204622476, 6)
			When MixRecipe.QuantityUnitName In ('OZ', 'LQ OZ', 'Ounces', 'fl oz', 'Fluid Oz')
			Then Round(MaterialRecipe.QUANTITY / (Material.SPECGR * 0.0651984837440621 * 0.45359240000781), 6)
			When MixRecipe.QuantityUnitName = 'KG'
			Then Round(MaterialRecipe.QUANTITY, 6)
			When MixRecipe.QuantityUnitName = 'GR'
			Then Round(MaterialRecipe.QUANTITY, 6) * 1000.0
			When MixRecipe.QuantityUnitName In ('L', 'LT', 'Liters', 'Litre')
			Then Round(MaterialRecipe.QUANTITY / Material.SPECGR / 1.0, 6)
			When MixRecipe.QuantityUnitName In ('ML', 'CC', 'Ml-liter', 'Bag', 'BG', 'DS')
			Then Round(MaterialRecipe.QUANTITY / Material.SPECGR / 1.0 * 1000.0, 6)
			When MixRecipe.QuantityUnitName In ('Each', 'EA')
			Then Round(MaterialRecipe.QUANTITY, 6)
			When MixRecipe.QuantityUnitName In ('Cubic Yards')
			Then Round(MaterialRecipe.QUANTITY / (201.974026 * Material.SPECGR * 1.0) * 0.26417205, 6)
			Else -1.0
		End 
Go
