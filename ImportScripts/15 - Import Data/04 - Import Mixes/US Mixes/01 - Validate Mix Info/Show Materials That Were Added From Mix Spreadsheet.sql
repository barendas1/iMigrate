/************************************************************
 * Code formatted by SoftTree SQL Assistant © v12.3.427
 * Time: 11/15/2023 5:36:34 PM
 ************************************************************/

Select  Isnull(MaterialInfo.PlantName, '') As [Plant Name],
        Isnull(MaterialInfo.TradeName, '') As [Trade Name],
        Isnull(MaterialInfo.MaterialDate, '') As [Material Date],
        Isnull(MaterialInfo.FamilyMaterialTypeName, '') As [Family Material Type Name],
        Isnull(MaterialInfo.MaterialTypeName, '') As [Material Type Name],
        Isnull(Cast(Cast(MaterialInfo.SpecificGravity As Numeric (15, 4)) As Nvarchar), '') As [Specific Gravity],
        Isnull(MaterialInfo.IsLiquidAdmix, '') As [Is Liquid Admix],
        Isnull(Cast(Cast(MaterialInfo.MoisturePct As Numeric (15, 2)) As Nvarchar), '') As [Moisture (%)],
        Isnull(Cast(Cast(MaterialInfo.Cost As Numeric (15, 2)) As Nvarchar), '')  As [Cost],
        Isnull(MaterialInfo.CostUnitName, '') As [Cost Unit Name],
        Isnull(MaterialInfo.ManufacturerName, '') As [Manufacturer Name],
        Isnull(MaterialInfo.ManufacturerSourceName, '') As [Manufacturer Source Name],
        Isnull(MaterialInfo.BatchingOrderNumber, '') As [Batching Order Number],
        Isnull(MaterialInfo.ItemCode, '') As [Item Code],
        Isnull(MaterialInfo.ItemDescription, '') As [Item Description],
        Isnull(MaterialInfo.ItemShortDescription, '') As [Item Short Description],
        Isnull(MaterialInfo.ItemCategoryName, '') As [Item Category Name],
        Isnull(MaterialInfo.ItemCategoryDescription, '') As [Item Category Description],
        Isnull(MaterialInfo.ItemCategoryShortDescription, '') As [Item Category Short Description],
        Isnull(MaterialInfo.BatchPanelCode, '') As [Batch Panel Code]        
From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
Order By MaterialInfo.PlantName, MaterialInfo.FamilyMaterialTypeName, MaterialInfo.TradeName
