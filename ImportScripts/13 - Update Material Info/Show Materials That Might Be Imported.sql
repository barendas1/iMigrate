Declare @PlantInfo Table (PlantName Nvarchar (100))

Insert into @PlantInfo (PlantName)
Select dbo.GetTrimmedValue(PlantInfo.PlantName) As PlantName
From
(
	Select '409' As PlantName
	Union All
	Select '420' As PlantName
	Union All
	Select '453' As PlantName
	Union All
	Select '455' As PlantName
	Union All
	Select '' As PlantName
	Union All
	Select '' As PlantName
) As PlantInfo
Where dbo.GetTrimmedValue(PlantInfo.PlantName) <> ''
Group By dbo.GetTrimmedValue(PlantInfo.PlantName)
Order By dbo.GetTrimmedValue(PlantInfo.PlantName)

If Exists (Select * From @PlantInfo)
Begin
    Select  Isnull(MaterialInfo.PlantName, '') As PlantName,
            Isnull(MaterialInfo.TradeName, '') As TradeName,
            Isnull(MaterialInfo.MaterialDate, '') As MaterialDate,
            Isnull(MaterialInfo.FamilyMaterialTypeName, '') As FamilyMaterialTypeName,
            Isnull(MaterialInfo.MaterialTypeName, '') As MaterialTypeName,
            Isnull(Cast(Cast(MaterialInfo.SpecificGravity As Numeric (15, 4)) As Nvarchar), '') As SpecificGravity,
            Isnull(MaterialInfo.IsLiquidAdmix, '') As IsLiquidAdmix,
            Isnull(Cast(Cast(MaterialInfo.MoisturePct As Numeric (15, 2)) As Nvarchar), '') As MoisturePercent,
            Isnull(Cast(Cast(MaterialInfo.Cost As Numeric (15, 2)) As Nvarchar), '') As Cost ,
            Isnull(MaterialInfo.CostUnitName, '') As CostUnitName,
            Isnull(MaterialInfo.ManufacturerName, '') As ManufacturerName,
            Isnull(MaterialInfo.ManufacturerSourceName, '') As ManufacturerSourceName,
            Isnull(MaterialInfo.BatchingOrderNumber, '') As BatchingOrderNumber,
            Isnull(MaterialInfo.ItemCode, '') As ItemCode,
            Isnull(MaterialInfo.ItemDescription, '') As ItemDescription,
            Isnull(MaterialInfo.ItemShortDescription, '') As ItemShortDescription,
            Isnull(ItemCategory.Name, '') As ItemCategoryName,
            Isnull(ItemCategory.Description, '') As ItemCategoryDescription,
            Isnull(ItemCategory.ShortDescription, '') As ItemCategoryShortDescription,
            Isnull(MaterialInfo.BatchPanelCode, '') As BatchPanelCode
    From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
    Inner Join @PlantInfo As PlantInfo
    On MaterialInfo.PlantName = PlantInfo.PlantName
    Left Join Data_Import_RJ.dbo.TestImport0000_MaterialItemCategory As ItemCategory
    On MaterialInfo.ItemCategoryName = ItemCategory.Name
    Left Join 
    (
	    Select -1 As ID, Plant.Name As PlantName, ItemName.Name As ItemCode
	    From dbo.Plants As Plant
	    Inner Join dbo.MATERIAL As Material
	    On Material.PlantID = Plant.PlantId
	    Inner Join dbo.ItemMaster As ItemMaster
	    On ItemMaster.ItemMasterID = Material.ItemMasterID
	    Inner Join dbo.Name As ItemName
	    On ItemName.NameID = ItemMaster.NameID
	    Group By Plant.Name, ItemName.Name	
    ) As ExistingPlant
    On MaterialInfo.PlantName = ExistingPlant.PlantName And MaterialInfo.ItemCode = ExistingPlant.ItemCode
    Where ExistingPlant.ID Is Null
    Order By MaterialInfo.FamilyMaterialTypeName, MaterialInfo.PlantName, MaterialInfo.TradeName
End
Else
Begin
    Select  Isnull(MaterialInfo.PlantName, '') As PlantName,
            Isnull(MaterialInfo.TradeName, '') As TradeName,
            Isnull(MaterialInfo.MaterialDate, '') As MaterialDate,
            Isnull(MaterialInfo.FamilyMaterialTypeName, '') As FamilyMaterialTypeName,
            Isnull(MaterialInfo.MaterialTypeName, '') As MaterialTypeName,
            Isnull(Cast(Cast(MaterialInfo.SpecificGravity As Numeric (15, 4)) As Nvarchar), '') As SpecificGravity,
            Isnull(MaterialInfo.IsLiquidAdmix, '') As IsLiquidAdmix,
            Isnull(Cast(Cast(MaterialInfo.MoisturePct As Numeric (15, 2)) As Nvarchar), '') As MoisturePercent,
            Isnull(Cast(Cast(MaterialInfo.Cost As Numeric (15, 2)) As Nvarchar), '') As Cost ,
            Isnull(MaterialInfo.CostUnitName, '') As CostUnitName,
            Isnull(MaterialInfo.ManufacturerName, '') As ManufacturerName,
            Isnull(MaterialInfo.ManufacturerSourceName, '') As ManufacturerSourceName,
            Isnull(MaterialInfo.BatchingOrderNumber, '') As BatchingOrderNumber,
            Isnull(MaterialInfo.ItemCode, '') As ItemCode,
            Isnull(MaterialInfo.ItemDescription, '') As ItemDescription,
            Isnull(MaterialInfo.ItemShortDescription, '') As ItemShortDescription,
            Isnull(ItemCategory.Name, '') As ItemCategoryName,
            Isnull(ItemCategory.Description, '') As ItemCategoryDescription,
            Isnull(ItemCategory.ShortDescription, '') As ItemCategoryShortDescription,
            Isnull(MaterialInfo.BatchPanelCode, '') As BatchPanelCode
    From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
    Left Join Data_Import_RJ.dbo.TestImport0000_MaterialItemCategory As ItemCategory
    On MaterialInfo.ItemCategoryName = ItemCategory.Name
    Left Join 
    (
	    Select -1 As ID, Plant.Name As PlantName, ItemName.Name As ItemCode
	    From dbo.Plants As Plant
	    Inner Join dbo.MATERIAL As Material
	    On Material.PlantID = Plant.PlantId
	    Inner Join dbo.ItemMaster As ItemMaster
	    On ItemMaster.ItemMasterID = Material.ItemMasterID
	    Inner Join dbo.Name As ItemName
	    On ItemName.NameID = ItemMaster.NameID
	    Group By Plant.Name, ItemName.Name	
    ) As ExistingPlant
    On MaterialInfo.PlantName = ExistingPlant.PlantName And MaterialInfo.ItemCode = ExistingPlant.ItemCode
    Where ExistingPlant.ID Is Null
    Order By MaterialInfo.FamilyMaterialTypeName, MaterialInfo.PlantName, MaterialInfo.TradeName    
End	