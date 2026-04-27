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
Where ItemName.Name In ('WATREPEL')
Order By Plants.Name, FamilyMaterialType.MaterialType, ItemName.Name, TradeName.Name
