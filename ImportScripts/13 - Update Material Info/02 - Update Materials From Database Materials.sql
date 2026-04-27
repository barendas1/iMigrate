Declare @UpdateTradeName Bit = 0
Declare @UpdateFamilyMaterialType Bit = 0
Declare @UpdateMaterialType Bit = 0
Declare @CanUpdateDescriptionFromExistingMaterial Bit = 1

Declare @MaterialData Table
(
	AutoID Bigint,
	PlantName Nvarchar (100),
	TradeName Nvarchar (200),
	MaterialDate Nvarchar (30),
	FamilyMaterialTypeName Nvarchar (100),
	MaterialTypeName Nvarchar (100),
	SpecificGravity Float,
	IsLiquidAdmix Nvarchar (100),
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
	UpdatedFromDatabase Bit Default (0)
)

If Exists (Select * From INFORMATION_SCHEMA.TABLES As TableInfo Where TableInfo.TABLE_NAME = 'ACIBatchViewDetails')
Begin
	Insert into @MaterialData
	(
		AutoID,
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
		UpdatedFromDatabase
	)
	Select MaterialInfo.AutoID, MaterialInfo.PlantName, MaterialInfo.TradeName,
		   MaterialInfo.MaterialDate, MaterialInfo.FamilyMaterialTypeName,
		   MaterialInfo.MaterialTypeName, MaterialInfo.SpecificGravity,
		   MaterialInfo.IsLiquidAdmix, MaterialInfo.MoisturePct, MaterialInfo.Cost,
		   MaterialInfo.CostUnitName, MaterialInfo.ManufacturerName,
		   MaterialInfo.ManufacturerSourceName, MaterialInfo.BatchingOrderNumber,
		   MaterialInfo.ItemCode, MaterialInfo.ItemDescription,
		   MaterialInfo.ItemShortDescription, MaterialInfo.ItemCategoryName,
		   MaterialInfo.ItemCategoryDescription,
		   MaterialInfo.ItemCategoryShortDescription,
		   MaterialInfo.ComponentCategoryName,
		   MaterialInfo.ComponentCategoryDescription,
		   MaterialInfo.ComponentCategoryShortDescription, MaterialInfo.BatchPanelCode,
		   MaterialInfo.UpdatedFromDatabase
	From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo

	Update MaterialInfo
		Set MaterialInfo.TradeName = Case when Isnull(@UpdateTradeName, 0) = 1 Then MaterialInfo.TradeName Else ExistingMaterial.TradeName End,
			MaterialInfo.MaterialDate = 
				Case 
					When Isdate(MaterialInfo.MaterialDate) = 1
					Then Format(Cast(MaterialInfo.MaterialDate As Datetime), 'MM/dd/yyyy')
					Else ExistingMaterial.MaterialDate
				End,
			MaterialInfo.FamilyMaterialTypeName = Case when Isnull(@UpdateFamilyMaterialType, 0) = 1 Then MaterialInfo.FamilyMaterialTypeName Else ExistingMaterial.FamilyMaterialTypeName End,
			MaterialInfo.MaterialTypeName = Case when Isnull(@UpdateMaterialType, 0) = 1 Then MaterialInfo.MaterialTypeName Else ExistingMaterial.MaterialTypeName End,
			MaterialInfo.SpecificGravity = Case when Isnull(MaterialInfo.SpecificGravity, -1.0) >= 0.4 Then MaterialInfo.SpecificGravity Else ExistingMaterial.SpecificGravity End,
			MaterialInfo.IsLiquidAdmix = ExistingMaterial.IsLiquidAdmix,
			MaterialInfo.MoisturePct = Case When Isnull(MaterialInfo.MoisturePct, -1.0) >= 0.01 Then MaterialInfo.MoisturePct Else ExistingMaterial.MoisturePct End,
			MaterialInfo.Cost = 
				Case
					When Isnull(MaterialData.Cost, -1.0) >= 0.0001
					Then MaterialData.Cost 
					Else ExistingMaterial.Cost
				End,
			MaterialInfo.CostUnitName = 
				Case
					When Isnull(MaterialData.Cost, -1) >= 0.0001
					Then MaterialData.CostUnitName
					Else ExistingMaterial.CostUnitName
				End,
			MaterialInfo.ManufacturerName = 
				Case
					When Isnull(MaterialData.ManufacturerName, '') <> '' 
					Then MaterialData.ManufacturerName
					Else ExistingMaterial.ManufacturerName
				End,
			MaterialInfo.ManufacturerSourceName = 
				Case
					When Isnull(MaterialData.ManufacturerName, '') <> '' And Isnull(MaterialData.ManufacturerSourceName, '') <> ''
					Then MaterialData.ManufacturerSourceName
					When    Isnull(MaterialData.ManufacturerName, '') <> '' And 
							Isnull(MaterialData.ManufacturerName, '') = Isnull(ExistingMaterial.ManufacturerName, '') And 
							Isnull(MaterialData.ManufacturerSourceName, '') = ''
					Then ExistingMaterial.ManufacturerSourceName
					When Isnull(MaterialData.ManufacturerName, '') <> ''
					Then MaterialInfo.ManufacturerSourceName
					Else ExistingMaterial.ManufacturerSourceName
				End,
			MaterialInfo.BatchingOrderNumber = 
				Case
					When Isnull(MaterialInfo.BatchingOrderNumber, '') <> '' 
					Then MaterialInfo.BatchingOrderNumber
					Else ExistingMaterial.BatchingOrderNumber
				End,
			MaterialInfo.ItemDescription = 
				Case
					When    Isnull(ExistingMaterial.ItemDescription, '') = '' Or 
							Isnull(@CanUpdateDescriptionFromExistingMaterial, 0) = 0 And Isnull(MaterialInfo.ItemDescription, '') <> ''
					Then MaterialInfo.ItemDescription
					When Isnull(MaterialInfo.ItemDescription, '') = ''
					Then ExistingMaterial.ItemDescription
					When Len(ExistingMaterial.ItemDescription) > Len(MaterialInfo.ItemDescription)
					Then ExistingMaterial.ItemDescription
					Else MaterialInfo.ItemDescription
				End,
			MaterialInfo.ItemShortDescription = 
				Case
					When    Isnull(ExistingMaterial.ItemShortDescription, '') = '' Or 
							Isnull(@CanUpdateDescriptionFromExistingMaterial, 0) = 0 And Isnull(MaterialInfo.ItemShortDescription, '') <> ''
					Then MaterialInfo.ItemShortDescription
					When Isnull(MaterialInfo.ItemShortDescription, '') = ''
					Then ExistingMaterial.ItemShortDescription
					When Len(ExistingMaterial.ItemShortDescription) > Len(MaterialInfo.ItemShortDescription)
					Then ExistingMaterial.ItemShortDescription
					Else MaterialInfo.ItemShortDescription
				End,
			MaterialInfo.ItemCategoryName = 
				Case
					When Isnull(MaterialData.ItemCategoryName, '') <> ''
					Then MaterialData.ItemCategoryName
					Else ExistingMaterial.ItemCategoryName
				End,
			MaterialInfo.ItemCategoryDescription = 
				Case
					When Isnull(MaterialData.ItemCategoryName, '') <> ''
					Then MaterialData.ItemCategoryDescription
					Else ExistingMaterial.ItemCategoryDescription
				End,
			MaterialInfo.ItemCategoryShortDescription = 
				Case
					When Isnull(MaterialData.ItemCategoryName, '') <> ''
					Then MaterialData.ItemCategoryShortDescription
					Else ExistingMaterial.ItemCategoryShortDescription
				End,
			MaterialInfo.BatchPanelCode = 
				Case
					When Isnull(MaterialInfo.BatchPanelCode, '') <> ''
					Then MaterialInfo.BatchPanelCode
					Else ExistingMaterial.BatchPanelCode
				End,
			MaterialInfo.UpdatedFromDatabase = 1
	From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
	Inner Join @MaterialData As MaterialData
	On MaterialData.AutoID = MaterialInfo.AutoID
	Inner Join
	(
		Select	IsNull(Plants.Name, '') As PlantCode,
				IsNull(TradeName.Name, '') As TradeName,
				Material.DATE As MaterialDate,
				IsNull(FamilyMaterialType.MaterialType, '') As FamilyMaterialTypeName,
				IsNull(MaterialType.MaterialType, '') As MaterialTypeName,
				Round(Material.SPECGR, 4) As SpecificGravity,
				Case
					When Isnull(Material.FamilyMaterialTypeID, -1) = 3 And Isnull(Material.MOISTURE, -1.0) > 0.0
					Then 'Yes'
					Else 'No'
				End As IsLiquidAdmix,
				Round(Material.MOISTURE * 100.0, 2) As MoisturePct,
				Round(CostInfo.ConvertedCost, 2) As Cost,
				IsNull(CostInfo.ConvertedCostUnits, '') As CostUnitName,
				IsNull(Manufacturer.Name, '') As ManufacturerName,
				IsNull(ManufacturerSource.Name, '') As ManufacturerSourceName,
				IsNull(Material.BatchingOrder, '') As BatchingOrderNumber,
				IsNull(ItemName.Name, '') As ItemCode,
				Case 
					When Isnull(ItemDescription.[Description], '') <> '' 
					Then ItemDescription.[Description]
					When Isnull(Description.[Description], '') <> ''
					Then Description.[Description] 
					Else ''
				End As ItemDescription,
				Isnull(ItemMaster.ItemShortDescription, '') As ItemShortDescription,
				IsNull(ItemCategory.ItemCategory, '') As ItemCategoryName, 
				IsNull(ItemCategory.[Description], '') As ItemCategoryDescription,
				IsNull(ItemCategory.ShortDescription, '') As ItemCategoryShortDescription,
				IsNull(BatchPanelName.Name, '') As BatchPanelCode
		From dbo.Plants As Plants
		Inner Join dbo.MATERIAL As Material
		On Material.PlantID = Plants.PlantId
		Inner Join dbo.Name As TradeName
		On TradeName.NameID = Material.NameID
		Left Join dbo.[Description] As Description
		On Description.DescriptionID = Material.DescriptionID
		Left Join dbo.Manufacturer As Manufacturer
		On Manufacturer.ManufacturerID = Material.ManufacturerID
		Left Join dbo.ManufacturerSource As ManufacturerSource
		On ManufacturerSource.ManufacturerSourceID = Material.ManufacturerSourceID  
		Left Join iServiceDataExchange.dbo.MaterialType As FamilyMaterialType
		On Material.FamilyMaterialTypeID = FamilyMaterialType.MaterialTypeID
		Left Join iServiceDataExchange.dbo.MaterialType As MaterialType
		On Material.MaterialTypeLink = MaterialType.MaterialTypeID
		Left Join dbo.ItemMaster As ItemMaster
		On ItemMaster.ItemMasterID = Material.ItemMasterID
		Left Join dbo.Name As ItemName
		On ItemName.NameID = ItemMaster.NameID
		Left Join dbo.[Description] As ItemDescription
		On ItemDescription.DescriptionID = ItemMaster.DescriptionID
		Left Join dbo.ProductionItemCategory As ItemCategory
		On ItemCategory.ProdItemCatID = ItemMaster.ProdItemCatID
		Left Join dbo.ProductionItemCategory As ComponentCategory
		On ComponentCategory.ProdItemCatID = ItemMaster.ProdItemCompTypeID
		Left Join dbo.Name As BatchPanelName
		On BatchPanelName.NameID = Material.BatchPanelNameID
		Left Join dbo.GetMaterialConvertedCostsByUnitSys(Null, dbo.GetMaterialCostsAreRetrievedFromHistory(), Null, Null, dbo.GetDBSetting_MaterialHistoryCostsDefaultHistoryPeriod(Default), Null, 1) As CostInfo
		On Material.MATERIALIDENTIFIER = CostInfo.MaterialID
		Where   Material.MATERIALIDENTIFIER In
				(
					Select Min(Material.MATERIALIDENTIFIER)
					From dbo.MATERIAL As Material
					Where Material.ItemMasterID Is Not Null
					Group By Material.PlantID, Material.ItemMasterID
				)	
	) As ExistingMaterial
	On  MaterialInfo.PlantName = ExistingMaterial.PlantCode And
		MaterialInfo.ItemCode = ExistingMaterial.ItemCode
	Where Isnull(MaterialInfo.UpdatedFromDatabase, 0) = 0



	Update MaterialInfo
		Set MaterialInfo.TradeName = Case when Isnull(@UpdateTradeName, 0) = 1 Then MaterialInfo.TradeName Else ExistingMaterial.TradeName End,
			MaterialInfo.MaterialDate = 
				Case 
					When Isdate(MaterialInfo.MaterialDate) = 1
					Then Format(Cast(MaterialInfo.MaterialDate As Datetime), 'MM/dd/yyyy')
					Else ExistingMaterial.MaterialDate
				End,
			MaterialInfo.FamilyMaterialTypeName = Case when Isnull(@UpdateFamilyMaterialType, 0) = 1 Then MaterialInfo.FamilyMaterialTypeName Else ExistingMaterial.FamilyMaterialTypeName End,
			MaterialInfo.MaterialTypeName = Case when Isnull(@UpdateMaterialType, 0) = 1 Then MaterialInfo.MaterialTypeName Else ExistingMaterial.MaterialTypeName End,
			MaterialInfo.SpecificGravity = Case when Isnull(MaterialInfo.SpecificGravity, -1.0) >= 0.4 Then MaterialInfo.SpecificGravity Else ExistingMaterial.SpecificGravity End,
			MaterialInfo.IsLiquidAdmix = ExistingMaterial.IsLiquidAdmix,
			MaterialInfo.MoisturePct = Case When Isnull(MaterialInfo.MoisturePct, -1.0) >= 0.01 Then MaterialInfo.MoisturePct Else ExistingMaterial.MoisturePct End,
			/*
			MaterialInfo.Cost = 
				Case
					When Isnull(MaterialData.Cost, -1.0) >= 0.0001
					Then MaterialData.Cost 
					Else ExistingMaterial.Cost
				End,
			MaterialInfo.CostUnitName = 
				Case
					When Isnull(MaterialData.Cost, -1) >= 0.0001
					Then MaterialData.CostUnitName
					Else ExistingMaterial.CostUnitName
				End,
			MaterialInfo.ManufacturerName = 
				Case
					When Isnull(MaterialData.ManufacturerName, '') <> '' 
					Then MaterialData.ManufacturerName
					Else ExistingMaterial.ManufacturerName
				End,
			MaterialInfo.ManufacturerSourceName = 
				Case
					When Isnull(MaterialData.ManufacturerName, '') <> '' And Isnull(MaterialData.ManufacturerSourceName, '') <> ''
					Then MaterialData.ManufacturerSourceName
					When    Isnull(MaterialData.ManufacturerName, '') <> '' And 
							Isnull(MaterialData.ManufacturerName, '') = Isnull(ExistingMaterial.ManufacturerName, '') And 
							Isnull(MaterialData.ManufacturerSourceName, '') = ''
					Then ExistingMaterial.ManufacturerSourceName
					When Isnull(MaterialData.ManufacturerName, '') <> ''
					Then MaterialInfo.ManufacturerSourceName
					Else ExistingMaterial.ManufacturerSourceName
				End,
			*/
			MaterialInfo.BatchingOrderNumber = 
				Case
					When Isnull(MaterialInfo.BatchingOrderNumber, '') <> '' 
					Then MaterialInfo.BatchingOrderNumber
					Else ExistingMaterial.BatchingOrderNumber
				End,
			MaterialInfo.ItemDescription = 
				Case
					When    Isnull(ExistingMaterial.ItemDescription, '') = '' Or 
							Isnull(@CanUpdateDescriptionFromExistingMaterial, 0) = 0 And Isnull(MaterialInfo.ItemDescription, '') <> ''
					Then MaterialInfo.ItemDescription
					When Isnull(MaterialInfo.ItemDescription, '') = ''
					Then ExistingMaterial.ItemDescription
					When Len(ExistingMaterial.ItemDescription) > Len(MaterialInfo.ItemDescription)
					Then ExistingMaterial.ItemDescription
					Else MaterialInfo.ItemDescription
				End,
			MaterialInfo.ItemShortDescription = 
				Case
					When    Isnull(ExistingMaterial.ItemShortDescription, '') = '' Or 
							Isnull(@CanUpdateDescriptionFromExistingMaterial, 0) = 0 And Isnull(MaterialInfo.ItemShortDescription, '') <> ''
					Then MaterialInfo.ItemShortDescription
					When Isnull(MaterialInfo.ItemShortDescription, '') = ''
					Then ExistingMaterial.ItemShortDescription
					When Len(ExistingMaterial.ItemShortDescription) > Len(MaterialInfo.ItemShortDescription)
					Then ExistingMaterial.ItemShortDescription
					Else MaterialInfo.ItemShortDescription
				End,
			MaterialInfo.ItemCategoryName = 
				Case
					When Isnull(MaterialData.ItemCategoryName, '') <> ''
					Then MaterialData.ItemCategoryName
					Else ExistingMaterial.ItemCategoryName
				End,
			MaterialInfo.ItemCategoryDescription = 
				Case
					When Isnull(MaterialData.ItemCategoryName, '') <> ''
					Then MaterialData.ItemCategoryDescription
					Else ExistingMaterial.ItemCategoryDescription
				End,
			MaterialInfo.ItemCategoryShortDescription = 
				Case
					When Isnull(MaterialData.ItemCategoryName, '') <> ''
					Then MaterialData.ItemCategoryShortDescription
					Else ExistingMaterial.ItemCategoryShortDescription
				End,
			/*
			MaterialInfo.BatchPanelCode = 
				Case
					When Isnull(MaterialInfo.BatchPanelCode, '') <> ''
					Then MaterialInfo.BatchPanelCode
					Else ExistingMaterial.BatchPanelCode
				End,
			*/
			MaterialInfo.UpdatedFromDatabase = 1
	From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
	Inner Join @MaterialData As MaterialData
	On MaterialData.AutoID = MaterialInfo.AutoID
	Inner Join
	(
		Select	IsNull(Plants.Name, '') As PlantCode,
				IsNull(TradeName.Name, '') As TradeName,
				Material.DATE As MaterialDate,
				IsNull(FamilyMaterialType.MaterialType, '') As FamilyMaterialTypeName,
				IsNull(MaterialType.MaterialType, '') As MaterialTypeName,
				Round(Material.SPECGR, 4) As SpecificGravity,
				Case
					When Isnull(Material.FamilyMaterialTypeID, -1) = 3 And Isnull(Material.MOISTURE, -1.0) > 0.0
					Then 'Yes'
					Else 'No'
				End As IsLiquidAdmix,
				Round(Material.MOISTURE * 100.0, 2) As MoisturePct,
				Round(CostInfo.ConvertedCost, 2) As Cost,
				IsNull(CostInfo.ConvertedCostUnits, '') As CostUnitName,
				IsNull(Manufacturer.Name, '') As ManufacturerName,
				IsNull(ManufacturerSource.Name, '') As ManufacturerSourceName,
				IsNull(Material.BatchingOrder, '') As BatchingOrderNumber,
				IsNull(ItemName.Name, '') As ItemCode,
				Case 
					When Isnull(ItemDescription.[Description], '') <> '' 
					Then ItemDescription.[Description]
					When Isnull(Description.[Description], '') <> ''
					Then Description.[Description] 
					Else ''
				End As ItemDescription,
				Isnull(ItemMaster.ItemShortDescription, '') As ItemShortDescription,
				IsNull(ItemCategory.ItemCategory, '') As ItemCategoryName, 
				IsNull(ItemCategory.[Description], '') As ItemCategoryDescription,
				IsNull(ItemCategory.ShortDescription, '') As ItemCategoryShortDescription,
				IsNull(BatchPanelName.Name, '') As BatchPanelCode
		From dbo.Plants As Plants
		Inner Join dbo.MATERIAL As Material
		On Material.PlantID = Plants.PlantId
		Inner Join dbo.Name As TradeName
		On TradeName.NameID = Material.NameID
		Left Join dbo.[Description] As Description
		On Description.DescriptionID = Material.DescriptionID
		Left Join dbo.Manufacturer As Manufacturer
		On Manufacturer.ManufacturerID = Material.ManufacturerID
		Left Join dbo.ManufacturerSource As ManufacturerSource
		On ManufacturerSource.ManufacturerSourceID = Material.ManufacturerSourceID  
		Left Join iServiceDataExchange.dbo.MaterialType As FamilyMaterialType
		On Material.FamilyMaterialTypeID = FamilyMaterialType.MaterialTypeID
		Left Join iServiceDataExchange.dbo.MaterialType As MaterialType
		On Material.MaterialTypeLink = MaterialType.MaterialTypeID
		Inner Join dbo.ItemMaster As ItemMaster
		On ItemMaster.ItemMasterID = Material.ItemMasterID
		Inner Join dbo.Name As ItemName
		On ItemName.NameID = ItemMaster.NameID
		Left Join dbo.[Description] As ItemDescription
		On ItemDescription.DescriptionID = ItemMaster.DescriptionID
		Left Join dbo.ProductionItemCategory As ItemCategory
		On ItemCategory.ProdItemCatID = ItemMaster.ProdItemCatID
		Left Join dbo.ProductionItemCategory As ComponentCategory
		On ComponentCategory.ProdItemCatID = ItemMaster.ProdItemCompTypeID
		Left Join dbo.Name As BatchPanelName
		On BatchPanelName.NameID = Material.BatchPanelNameID
		Left Join dbo.GetMaterialConvertedCostsByUnitSys(Null, dbo.GetMaterialCostsAreRetrievedFromHistory(), Null, Null, dbo.GetDBSetting_MaterialHistoryCostsDefaultHistoryPeriod(Default), Null, 1) As CostInfo
		On Material.MATERIALIDENTIFIER = CostInfo.MaterialID
		Where   Material.MATERIALIDENTIFIER In
				(
					Select Max(Material.MATERIALIDENTIFIER)
					From dbo.MATERIAL As Material
					Where Material.ItemMasterID Is Not Null
					Group By Material.ItemMasterID
				)	
	) As ExistingMaterial
	On  MaterialInfo.ItemCode = ExistingMaterial.ItemCode
	Where Isnull(MaterialInfo.UpdatedFromDatabase, 0) = 0


	Update MaterialInfo
		Set MaterialInfo.TradeName = MaterialInfo.ItemCode
	--Select *    
	From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
	Inner Join
	(
		Select MaterialInfo.PlantName, MaterialInfo.ItemCode, Min(MaterialInfo.AutoID) As AutoID
		From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
		Group By MaterialInfo.PlantName, MaterialInfo.ItemCode
		Having Count(*) > 1	
	) As CurMaterialInfo
	On  MaterialInfo.PlantName = CurMaterialInfo.PlantName And
		MaterialInfo.ItemCode = CurMaterialInfo.ItemCode
	Where MaterialInfo.AutoID <> CurMaterialInfo.AutoID
End
Go
