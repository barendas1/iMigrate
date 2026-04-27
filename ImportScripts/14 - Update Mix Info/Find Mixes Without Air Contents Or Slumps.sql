Select *
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Where Isnull(MixInfo.MinAirContent, -1.0) < 0.0 And Isnull(MixInfo.MaxAirContent, -1.0) < 0.0
Order By MixInfo.AutoID

Select *
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Where Isnull(MixInfo.MinSlump, -1.0) < 0.0 And Isnull(MixInfo.MaxSlump, -1.0) < 0.0
Order By MixInfo.AutoID
