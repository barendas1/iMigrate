Delete MixInfo
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
Where MixInfo.AutoID <> MixInfo3.AutoID

