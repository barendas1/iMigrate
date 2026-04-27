Select *
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Where MixInfo.Slump > 12.0
Order By MixInfo.AutoID

Select *
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Where MixInfo.MixDescription Like '%Metric%'
Order By MixInfo.AutoID

Select Distinct MixInfo.QuantityUnitName
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
