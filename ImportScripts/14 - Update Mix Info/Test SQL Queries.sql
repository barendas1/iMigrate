Select *
From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
Order By MaterialInfo.AutoID

Select *
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Order By MixInfo.AutoID

Select *
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Where MixInfo.MixDescription Is Not Null
Order By MixInfo.AutoID

Select MixInfo.*
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Inner Join
(
	Select MixInfo2.PlantCode, MixInfo2.MixCode, MixInfo2.MaterialItemCode, Max(MixInfo2.Quantity) - Min(MixInfo2.Quantity) As QuantityDiff, Min(MixInfo2.AutoID) As AutoID
	From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo2
	Group By MixInfo2.PlantCode, MixInfo2.MixCode, MixInfo2.MaterialItemCode
	Having Count(*) > 1
) As MixInfo3
On  MixInfo.PlantCode = MixInfo3.PlantCode And
    MixInfo.MixCode = MixInfo3.MixCode And
    MixInfo.MaterialItemCode = MixInfo3.MaterialItemCode
Order By MixInfo.PlantCode, MixInfo.MixCode, MixInfo.MaterialItemCode

	Select MixInfo2.PlantCode, MixInfo2.MixCode, MixInfo2.MaterialItemCode, Min(MixInfo2.AutoID) As AutoID
	From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo2
	Group By MixInfo2.PlantCode, MixInfo2.MixCode, MixInfo2.MaterialItemCode
	Having Count(*) > 1


Select MixInfo.*
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Inner Join
(
	Select MixInfo2.PlantCode, MixInfo2.MixCode, MixInfo2.MaterialItemCode, Min(MixInfo2.AutoID) As AutoID
	From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo2
	Group By MixInfo2.PlantCode, MixInfo2.MixCode, MixInfo2.MaterialItemCode
	Having Count(*) > 1
) As MixInfo3
On  MixInfo.PlantCode = MixInfo3.PlantCode And
    MixInfo.MixCode = MixInfo3.MixCode And
    MixInfo.MaterialItemCode = MixInfo3.MaterialItemCode
Where MixInfo.Quantity = 0.0 And MixInfo.AutoID <> MixInfo3.AutoID

