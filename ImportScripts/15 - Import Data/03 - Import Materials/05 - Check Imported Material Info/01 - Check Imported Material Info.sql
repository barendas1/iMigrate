/*
Select Material.ReportMaterialTypeID, Material.[TYPE], Material.* 
From dbo.MATERIAL As Material
Order By Material.MATERIALIDENTIFIER
*/

Declare @CheckItemCategoryDescriptions Bit = 0
Declare @CheckItemCategoryShortDescriptions Bit = 0
Declare @CheckForSameMaterialTypes Bit = 0
Declare @CheckForInactiveMaterials Bit = 0

Declare @PlantMaterialInfo Table
(
	AutoID Bigint Identity (1, 1),
	MaterialAutoID Bigint,
	PlantID Int,
	PlantCode Nvarchar (30),
	PlantName Nvarchar (100),
	FamilyMaterialTypeName Nvarchar (100),
	TradeName Nvarchar (100),
	ItemCode Nvarchar (100)
)

Insert into @PlantMaterialInfo
(
	MaterialAutoID, 
	PlantID, 
	PlantCode,
	PlantName, 
	FamilyMaterialTypeName, 
	TradeName,
	ItemCode
)
Select	MaterialInfo.AutoID,
		Case
			When MaterialInfo.FamilyMaterialTypeName = 'Aggregate' And Yard.PlantId Is Not null
			Then Yard.PlantId
			Else Plants.PlantID
		End,
		Case
			When MaterialInfo.FamilyMaterialTypeName = 'Aggregate' And Yard.PlantId Is Not null
			Then Yard.PLNTTAGShouldGoAway
			Else Plants.PLNTTAGShouldGoAway
		End,
		Case
			When MaterialInfo.FamilyMaterialTypeName = 'Aggregate' And Yard.PlantId Is Not null
			Then Yard.Name
			Else Plants.Name
		End,
		MaterialInfo.FamilyMaterialTypeName,
		MaterialInfo.TradeName,
		MaterialInfo.ItemCode
From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
Inner Join dbo.Plants As Plants
On MaterialInfo.PlantName = Plants.Name
Left Join dbo.Plants As Yard
On Plants.PlantIdForYard = Yard.PlantId

Select	MaterialInfo.*,		
		IsNull(Cast(Material.DATE As Datetime), -1.0) As TargetDate, 
		Isnull(Cast(MaterialInfo.MaterialDate As Datetime), -1.0) As SourceDate, 
		Isnull(MaterialTypeInfo.MaterialType, '') As TargetMaterialType, Isnull(MaterialInfo.MaterialTypeName, '') As SourceMaterialType, 
		Isnull(ReportMaterialTypeInfo.MaterialType, '') As SourceReportMaterialType, Isnull(Material.[TYPE], '') As TargetReportMaterialType, 
		Isnull(Material.SPECGR, -1.0) As TargetSpecGrav, Isnull(MaterialInfo.SpecificGravity, -1.0) As SourceSpecGrav, 
		dbo.Validation_StringValueIsTrue(MaterialInfo.IsLiquidAdmix) As IsLiquidAdmix,
		MaterialInfo.MoisturePct As SourceMoisturePct,
		Material.MOISTURE * 100.0 As TargetMoisturePct,
		Round(IsNull(Material.COST, -1.0), 6) As TargetCost,
		Case
			When MaterialInfo.Cost Is Null Or  MaterialInfo.CostUnitName Not In ('$//YD^3', '$/CY','CY', 'oz', '$/oz', 'GA', '$/GL', '$/gal', 'GL', '$/lb', 'LB', '$/TN', '$/ton', 'Tons', '$/Kg', '$/MTon', '$/Metric Ton', 'Liters', '$/Liter', 'Ml-liter', 'ml')
			Then -1.0
			When MaterialInfo.CostUnitName In ('$/CY','CY', '$//YD^3')
			Then Round(MaterialInfo.Cost / 201.974026 * 264.17205 / (MaterialInfo.SpecificGravity * 1.0), 6)
			When MaterialInfo.CostUnitName In ('GA', '$/gal', '$/GL', 'GL')
			Then Round(MaterialInfo.Cost * 264.17205 / (MaterialInfo.SpecificGravity * 1.0), 6)
			When IsNull(MaterialInfo.CostUnitName, '') In ('OZ', 'Fluid Oz', '$/oz')
			Then Round(MaterialInfo.Cost * 128.0 * 264.17205 / (MaterialInfo.SpecificGravity * 1.0), 6)
			When MaterialInfo.CostUnitName In ('$/lb', 'LB')
			Then Round(MaterialInfo.Cost * 2204.622719056, 6)
			When MaterialInfo.CostUnitName In ('$/ton', '$/TN', 'Tons')
			Then Round(MaterialInfo.Cost / 0.9071847, 6)
			When MaterialInfo.CostUnitName In ('$/Liter', 'Liters')
			Then Round(MaterialInfo.Cost * 1000.0 / (Material.SPECGR * 1.0), 6)
			When MaterialInfo.CostUnitName In ('Ml-liter', 'ml')
			Then Round(MaterialInfo.Cost * 1000.0 * 1000.0 / (Material.SPECGR * 1.0), 6)
			When MaterialInfo.CostUnitName In ('$/Kg', 'kg')
			Then Round(MaterialInfo.Cost * 1000.0, 6)
			When MaterialInfo.CostUnitName In ('$/MTon', '$/Metric Ton')
			Then Round(MaterialInfo.Cost, 6)
		End As SourceCost, 
		Isnull(Manufacturer.Name, '') As TargetManufacturer, Isnull(MaterialInfo.ManufacturerName, '') As SourceManufacturer, 
		Isnull(Manufacturer.ManufacturerID, -1) As ManufacturerID1, Isnull(ManufacturerSource.ManufacturerID, -1) As ManufacturerID2, 
		Isnull(ManufacturerSource.Name, '') As TargetManufacturer, Isnull(MaterialInfo.ManufacturerSourceName, '') As SourceManufacturerSource, 
		Isnull(ItemCodeInfo.Name, '') As TargetItemCode, Isnull(MaterialInfo.ItemCode, '') As SourceItemCode, 
		Isnull(MaterialInfo.ItemCode, '') As SourceItemCode,
		Isnull(ItemDescrInfo.[Description], '') As TargetItemDescription, Isnull(MaterialInfo.ItemDescription, '') As SourceItemDescription, 
		Isnull(MtrlDescrInfo.[Description], '') As TargetMaterialDescription, Isnull(MaterialInfo.ItemDescription, '') As SourceItemDescription, 
		Isnull(MaterialInfo.ItemCode, '') As SourceItemCode,
		Isnull(Material.BatchPanelDescription, '') As TargetBatchPanelDescription, Isnull(MaterialInfo.ItemDescription, '') As SourceBatchPanelDescription, 
		Isnull(MaterialInfo.ItemCode, '') As SourceItemCode,
		IsNull(ItemMaster.ItemShortDescription, '') As TargetItemShortDescription,
		Case
			When Isnull(MaterialInfo.ItemShortDescription, '') <> ''
			Then Ltrim(Rtrim(Left(MaterialInfo.ItemShortDescription, 16)))
			Else Ltrim(Rtrim(Left(Isnull(MaterialInfo.ItemDescription, ''), 16)))
		End As SourceItemShortDescription, 
		Isnull(PanelCodeInfo.Name, '') As TargetBatchPanelCode,  
		Case 
			When IsNull(MaterialInfo.BatchPanelCode, '') <> ''
			Then MaterialInfo.BatchPanelCode
			Else '' --Isnull(ItemCodeInfo.Name, '')
		End As SourceBatchPanelCode, 
		Isnull(ItemCategoryInfo.ItemCategory, '') As TargetItemCategory, Isnull(MaterialInfo.ItemCategoryName, '') As SourceItemCategory, 
		Isnull(ItemCategoryInfo.[Description], '') As TargetItemCategoryDescription, Isnull(MaterialInfo.ItemCategoryDescription, '') As SourceItemCategoryDescription, 
		Isnull(ItemCategoryInfo.ShortDescription, '') As TargetItemShortDescription, Isnull(MaterialInfo.ItemCategoryShortDescription, '') As SourceItemShortDescription, 
		Isnull(ComponentCategoryInfo.ItemCategory, ''), Isnull(MaterialInfo.ComponentCategoryName, ''), 
		Isnull(ComponentCategoryInfo.[Description], ''), Isnull(MaterialInfo.ComponentCategoryDescription, ''), 
		Isnull(ComponentCategoryInfo.ShortDescription, ''), Isnull(MaterialInfo.ComponentCategoryShortDescription, '')
From dbo.Plants As Plants
Inner Join dbo.Material As Material
On Material.PlantID = Plants.PlantId
Inner Join dbo.Name As TradeNameInfo
On TradeNameInfo.NameID = Material.NameID
Left Join dbo.[Description] As MtrlDescrInfo
On MtrlDescrInfo.DescriptionID = Material.DescriptionID
Left Join dbo.MaterialType As FamilyMaterialTypeInfo
On Material.FamilyMaterialTypeID = FamilyMaterialTypeInfo.MaterialTypeID
Left Join dbo.MaterialType As MaterialTypeInfo
On Material.MaterialTypeLink = MaterialTypeInfo.MaterialTypeID
Left Join dbo.MaterialType As ReportMaterialTypeInfo
On Material.ReportMaterialTypeID = ReportMaterialTypeInfo.MaterialTypeID
Left Join dbo.Manufacturer As Manufacturer
On Manufacturer.ManufacturerID = Material.ManufacturerID
Left Join dbo.ManufacturerSource As ManufacturerSource
On ManufacturerSource.ManufacturerSourceID = Material.ManufacturerSourceID
Left Join dbo.ItemMaster As ItemMaster
On ItemMaster.ItemMasterID = Material.ItemMasterID
Left Join dbo.Name As ItemCodeInfo
On ItemCodeInfo.NameID = ItemMaster.NameID
Left Join dbo.[Description] As ItemDescrInfo
On ItemDescrInfo.DescriptionID = ItemMaster.DescriptionID
Left Join dbo.ProductionItemCategory As ItemCategoryInfo
On	ItemCategoryInfo.ProdItemCatID = ItemMaster.ProdItemCatID And
	ItemCategoryInfo.ProdItemCatType = 'Mtrl'
Left Join dbo.ProductionItemCategory As ComponentCategoryInfo
On	ComponentCategoryInfo.ProdItemCatID = ItemMaster.ProdItemCompTypeID And
	ComponentCategoryInfo.ProdItemCatType = 'MtrlCompType'
Left Join dbo.Name As PanelCodeInfo
On PanelCodeInfo.NameID = Material.BatchPanelNameID
Inner Join @PlantMaterialInfo As PlantMaterialInfo
On	Plants.Name = PlantMaterialInfo.PlantName And
	FamilyMaterialTypeInfo.MaterialType = PlantMaterialInfo.FamilyMaterialTypeName And
	ItemCodeInfo.Name = PlantMaterialInfo.ItemCode
Inner Join Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
On PlantMaterialInfo.MaterialAutoID = MaterialInfo.AutoID
Where	--IsNull(Cast(Material.DATE As Datetime), -1.0) <> Isnull(Cast(MaterialInfo.MaterialDate As Datetime), -1.0) Or
        Isnull(@CheckForInactiveMaterials, 0) = 1 And Isnull(Material.Inactive, 0) <> 1 Or
		Isnull(@CheckForSameMaterialTypes, 0) = 0 And Isnull(MaterialTypeInfo.MaterialType, '') <> Isnull(MaterialInfo.MaterialTypeName, '') Or
		Isnull(@CheckForSameMaterialTypes, 0) = 1 And Isnull(MaterialTypeInfo.MaterialType, '') = Isnull(MaterialInfo.MaterialTypeName, '') Or
		Isnull(ReportMaterialTypeInfo.MaterialType, '') <> Isnull(Material.[TYPE], '') Or
		Isnull(Material.SPECGR, -1.0) <> Isnull(MaterialInfo.SpecificGravity, -1.0) Or
		dbo.Validation_StringValueIsTrue(MaterialInfo.IsLiquidAdmix) = 1 And
		(
			Material.FamilyMaterialTypeID <> 3 And Isnull(Material.MOISTURE, 0.0) <> 0.0 Or
			Material.FamilyMaterialTypeID = 3 And Isnull(Material.MOISTURE, 0.0) = 0.0 Or
			Material.FamilyMaterialTypeID = 3 And Isnull(MaterialInfo.MoisturePct, -1.0) > 0.0 And
			Isnull(MaterialInfo.MoisturePct, -1.0) <> Isnull(Material.MOISTURE * 100.0, -1.0)			
		) Or
		dbo.Validation_StringValueIsTrue(MaterialInfo.IsLiquidAdmix) = 0 And
		(
			Material.FamilyMaterialTypeID <> 3 And Isnull(Material.MOISTURE, 0.0) <> 0.0 Or
			Material.FamilyMaterialTypeID = 3 And Isnull(Material.MOISTURE, 0.0) <> 0.0
		) Or
		
		Round(IsNull(Material.COST, -1.0), 6) <>
		Case
			When MaterialInfo.Cost Is Null Or MaterialInfo.CostUnitName Not In ('$//YD^3', '$/CY','CY', 'oz', '$/oz', 'lb', 'TN', 'Tons', 'GA', '$/GL', '$/gal', 'GL', '$/lb', '$/TN', '$/ton', '$/Kg', 'Kg', '$/MTon', '$/Metric Ton', 'ml', 'Ml-liter', 'Liters', '$/Liter', 'MT', 'L', 'Gallons', 'Pounds', 'Fluid Oz')
			Then -1.0
			When MaterialInfo.CostUnitName In ('$/CY','CY', '$//YD^3')
			Then Round(MaterialInfo.Cost / 201.974026 * 264.17205 / (MaterialInfo.SpecificGravity * 1.0), 6)
			When MaterialInfo.CostUnitName In ('$/gal', 'Gallons', 'GA', '$/GL', 'GL')
			Then Round(MaterialInfo.Cost * 264.17205 / (MaterialInfo.SpecificGravity * 1.0), 6)
			When IsNull(MaterialInfo.CostUnitName, '') In ('OZ', 'Fluid Oz', '$/oz')
			Then Round(MaterialInfo.Cost * 128.0 * 264.17205 / (MaterialInfo.SpecificGravity * 1.0), 6)
			When MaterialInfo.CostUnitName In ('$/lb', 'Pounds', 'lb')
			Then Round(MaterialInfo.Cost * 2204.622719056, 6)
			When MaterialInfo.CostUnitName In ('$/ton', 'Tn', '$/TN', 'Tons')
			Then Round(MaterialInfo.Cost / 0.9071847, 6)
			When MaterialInfo.CostUnitName In ('$/Liter', 'L', 'Liters')
			Then Round(MaterialInfo.Cost * 1000.0 / (Material.SPECGR * 1.0), 6)
			When MaterialInfo.CostUnitName In ('Ml-liter', 'ml')
			Then Round(MaterialInfo.Cost * 1000.0 * 1000.0 / (Material.SPECGR * 1.0), 6)
			When MaterialInfo.CostUnitName In ('$/Kg', 'Kg')
			Then Round(MaterialInfo.Cost * 1000.0, 6)
			When MaterialInfo.CostUnitName In ('$/MTon', '$/Metric Ton', 'MT')
			Then Round(MaterialInfo.Cost, 6)
		End Or
		Isnull(MaterialInfo.ManufacturerName, '') <> '' And Isnull(Manufacturer.Name, '') <> Isnull(MaterialInfo.ManufacturerName, '') Or
		Isnull(MaterialInfo.ManufacturerSourceName, '') <> '' And
		Isnull(Manufacturer.ManufacturerID, -1) <> Isnull(ManufacturerSource.ManufacturerID, -1) Or
		Isnull(MaterialInfo.ManufacturerSourceName, '') <> '' And Isnull(ManufacturerSource.Name, '') <> Isnull(MaterialInfo.ManufacturerSourceName, '') Or
		
		Isnull(ItemCodeInfo.Name, '') <> Isnull(MaterialInfo.ItemCode, '') Or
		Isnull(MaterialInfo.ItemCode, '') <> '' And
		Isnull(ItemDescrInfo.[Description], '') <> Isnull(MaterialInfo.ItemDescription, '') Or
		Isnull(MtrlDescrInfo.[Description], '') <> Isnull(MaterialInfo.ItemDescription, '') Or
		Isnull(MaterialInfo.ItemCode, '') <> '' And 
		Isnull(Material.BatchPanelDescription, '') <> Isnull(MaterialInfo.ItemDescription, '') Or
		Isnull(MaterialInfo.ItemCode, '') <> '' And
		IsNull(ItemMaster.ItemShortDescription, '') <>
		Case
			When Isnull(MaterialInfo.ItemShortDescription, '') <> ''
			Then Ltrim(Rtrim(Left(MaterialInfo.ItemShortDescription, (Case when dbo.GetProductionSystem('') = 'Command' Then 16 Else 100000 End))))
			Else Ltrim(Rtrim(Left(Isnull(MaterialInfo.ItemDescription, ''), (Case when dbo.GetProductionSystem('') = 'Command' Then 16 Else 100000 End))))
		End Or
		Isnull(PanelCodeInfo.Name, '') <> 
		Case 
			When IsNull(MaterialInfo.BatchPanelCode, '') <> ''
			Then MaterialInfo.BatchPanelCode
			Else '' --Isnull(ItemCodeInfo.Name, '')
		End Or
		Isnull(ItemCategoryInfo.ItemCategory, '') <> Isnull(MaterialInfo.ItemCategoryName, '') Or
		Isnull(@CheckItemCategoryDescriptions, 0) = 1 And Isnull(ItemCategoryInfo.[Description], '') <> Case when Isnull(MaterialInfo.ItemCategoryDescription, '') <> '' Then Isnull(MaterialInfo.ItemCategoryDescription, '') Else Isnull(MaterialInfo.ItemCategoryName, '') End Or
		Isnull(@CheckItemCategoryShortDescriptions, 0) = 1 And Isnull(ItemCategoryInfo.ShortDescription, '') <> Case when Isnull(MaterialInfo.ItemCategoryShortDescription, '') <> '' Then Isnull(MaterialInfo.ItemCategoryShortDescription, '') Else Isnull(MaterialInfo.ItemCategoryName, '') End Or
		Isnull(ComponentCategoryInfo.ItemCategory, '') <> Isnull(MaterialInfo.ComponentCategoryName, '') Or
		Isnull(@CheckItemCategoryDescriptions, 0) = 1 And Isnull(ComponentCategoryInfo.[Description], '') <> Isnull(MaterialInfo.ComponentCategoryDescription, '') Or
		Isnull(@CheckItemCategoryShortDescriptions, 0) = 1 And Isnull(ComponentCategoryInfo.ShortDescription, '') <> Isnull(MaterialInfo.ComponentCategoryShortDescription, '') 

Select Material.PlantID, Material.ItemMasterID
From dbo.Material As Material
Where Isnull(Material.ItemMasterID, -1) > 0
Group By Material.PlantID, Material.ItemMasterID
Having Count(Distinct Material.NameID) > 1

Select Material.PlantID, Material.NameID
From dbo.Material As Material
Group By Material.PlantID, Material.NameID
Having Count(Distinct Isnull(Material.ItemMasterID, -1)) > 1

Select  Plant.Name As [Plant Name],
        FamilyMaterialType.Name As [Family Material Type],
        TradeNameInfo.Name As [Trade Name],
        ItemName.Name As [Item Code],
        Isnull(ItemDescr.[Description], MtrlDescr.[Description]) As [Material Description],
        Material.[DATE] As [Material Date],
        MaterialType.Name As [Material Type]
From dbo.Plants As Plant
Inner Join dbo.MATERIAL As Material
On Material.PlantID = Plant.PlantId
Inner Join dbo.Name As TradeNameInfo
On TradeNameInfo.NameID = Material.NameID
Left Join dbo.[Description] As MtrlDescr
On MtrlDescr.DescriptionID = Material.DescriptionID
Inner Join dbo.Static_MaterialType As FamilyMaterialType
On Material.FamilyMaterialTypeID = FamilyMaterialType.Static_MaterialTypeID
Inner Join dbo.Static_MaterialType As MaterialType
On Material.MaterialTypeLink = MaterialType.Static_MaterialTypeID
Left Join dbo.ItemMaster As ItemMaster
On ItemMaster.ItemMasterID = Material.ItemMasterID
Left Join dbo.Name As ItemName
On ItemName.NameID = ItemMaster.NameID
Left Join dbo.[Description] As ItemDescr
On ItemDescr.DescriptionID = ItemMaster.DescriptionID
Inner Join
(
    Select Material.PlantID, Material.ItemMasterID
    From dbo.Material As Material
    Where Isnull(Material.ItemMasterID, -1) > 0
    Group By Material.PlantID, Material.ItemMasterID
    Having Count(Distinct Material.NameID) > 1	
) As MultMaterial
On Plant.PlantId = MultMaterial.PlantID And Isnull(Material.ItemMasterID, -1) = Isnull(MultMaterial.ItemMasterID, -1)
Order By Plant.Name, TradeNameInfo.Name

Select  Plant.Name As [Plant Name],
        FamilyMaterialType.Name As [Family Material Type],
        TradeNameInfo.Name As [Trade Name],
        ItemName.Name As [Item Code],
        Isnull(ItemDescr.[Description], MtrlDescr.[Description]) As [Material Description],
        Material.[DATE] As [Material Date],
        MaterialType.Name As [Material Type]
From dbo.Plants As Plant
Inner Join dbo.MATERIAL As Material
On Material.PlantID = Plant.PlantId
Inner Join dbo.Name As TradeNameInfo
On TradeNameInfo.NameID = Material.NameID
Left Join dbo.[Description] As MtrlDescr
On MtrlDescr.DescriptionID = Material.DescriptionID
Inner Join dbo.Static_MaterialType As FamilyMaterialType
On Material.FamilyMaterialTypeID = FamilyMaterialType.Static_MaterialTypeID
Inner Join dbo.Static_MaterialType As MaterialType
On Material.MaterialTypeLink = MaterialType.Static_MaterialTypeID
Left Join dbo.ItemMaster As ItemMaster
On ItemMaster.ItemMasterID = Material.ItemMasterID
Left Join dbo.Name As ItemName
On ItemName.NameID = ItemMaster.NameID
Left Join dbo.[Description] As ItemDescr
On ItemDescr.DescriptionID = ItemMaster.DescriptionID
Inner Join
(
    Select Material.PlantID, Material.NameID
    From dbo.Material As Material
    Group By Material.PlantID, Material.NameID
    Having Count(Distinct Isnull(Material.ItemMasterID, -1)) > 1	
) As MultMaterial
On Plant.PlantId = MultMaterial.PlantID And Material.NameID = MultMaterial.NameID
Order By Plant.Name, TradeNameInfo.Name
