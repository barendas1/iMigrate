/*
Update MaterialInfo
    Set MaterialInfo.Cost = Null,
        MaterialInfo.CostUnitName = Null
From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
*/
Select *
From iServiceDataExchange.dbo.MaterialType As MaterialType
Order By MaterialType.RecipeOrder


Select *
From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
Where	MaterialInfo.PlantName = 'P04' And
		MaterialInfo.ItemCode = '9071D999'

Select *
From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
Where	MaterialInfo.PlantName = 'Q07' And
		MaterialInfo.TradeName = 'WEST PARIS AGGREGATES_40-20MM ROOFING STONE GRVL_PARIS, ON'
		
		
Select MaterialInfo.PlantName, Ltrim(Rtrim(Left(MaterialInfo.TradeName, 70)))
From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
Group By MaterialInfo.PlantName, Ltrim(Rtrim(Left(MaterialInfo.TradeName, 70)))
Having Count(*) > 1

Select MaterialInfo.PlantName, Ltrim(Rtrim(Left(MaterialInfo.TradeName, 70)))
From Data_Import_RJ.dbo.Import01_MaterialInfo_WCAN As MaterialInfo
Group By MaterialInfo.PlantName, Ltrim(Rtrim(Left(MaterialInfo.TradeName, 70)))
Having Count(*) > 1

Select Material.PlantID, Material.NameID
From CanEst_Quadrel_Prod_RJ.dbo.MATERIAL As Material
Group By Material.PlantID, Material.NameID
Having Count(*) > 1

Select Material.PlantID, Material.NameID
From CanWst_Quadrel_Prod_RJ.dbo.MATERIAL As Material
Group By Material.PlantID, Material.NameID
Having Count(*) > 1

Select *
From CmdTest_RJ.dbo.iloc As ILOC

Select UOMS.descr, Count(*)
From CmdTest_RJ.dbo.icst As ICST
Inner Join CmdTest_RJ.dbo.uoms As UOMS
On ICST.qty_uom = UOMS.uom
Group By UOMS.descr

Select *
From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
Where Isnull(MaterialInfo.Cost, -1.0) > 0.0
