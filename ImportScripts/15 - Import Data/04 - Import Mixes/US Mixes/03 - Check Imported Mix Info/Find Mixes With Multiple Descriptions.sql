Select MixInfo.MixCode, Count(Distinct MixInfo.MixDescription), Min(MixInfo.MixDescription), Max(MixInfo.MixDescription)
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Group By MixInfo.MixCode
Having Count(Distinct MixInfo.MixDescription) > 1
Order By MixInfo.MixCode