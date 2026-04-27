Select Info.PlantName, Info.TradeName
From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As Info
Group By Info.PlantName, Info.TradeName
Having Count(*) > 1

Select Info.PlantName, Info.ItemCode
From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As Info
Group By Info.PlantName, Info.ItemCode
Having Count(*) > 1
