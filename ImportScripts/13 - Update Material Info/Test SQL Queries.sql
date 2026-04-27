Select * 
From Data_Import_RJ.dbo.TestImport0000_MainMaterialInfo As MaterialInfo 
Order By    MaterialInfo.FamilyMaterialTypeName,
            MaterialInfo.ItemCategory,        
            MaterialInfo.Description
                                                                                       
Select * 
From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
Order By MaterialInfo.AutoID

Select * 
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Order By MixInfo.AutoID

Select * 
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Where Strength Is Not Null
Order By MixInfo.AutoID

Select *
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Where MixInfo.MaterialItemCode = 'SP BACKFILL'

Print Format(Getdate(), 'MM-dd-yyyy')             

Select *
From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
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
Where   --Round(Isnull(MaterialInfo.SpecificGravity, -1.0), 4) <> Round(Isnull(ExistingMaterial.SpecificGravity, -1.0), 4) Or
        --Isnull(MaterialInfo.FamilyMaterialTypeName, '') <> Isnull(ExistingMaterial.FamilyMaterialTypeName, '') Or
        --Isnull(MaterialInfo.ManufacturerName, '') <> '' And Isnull(ExistingMaterial.ManufacturerName, '') <> '' And Isnull(MaterialInfo.ManufacturerName, '') <> Isnull(ExistingMaterial.ManufacturerName, '') Or
        Isnull(MaterialInfo.ManufacturerSourceName, '') <> '' Or Isnull(ExistingMaterial.ManufacturerSourceName, '') <> ''