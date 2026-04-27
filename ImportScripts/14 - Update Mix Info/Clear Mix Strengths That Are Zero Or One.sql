Select *
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Where Isnull(MixInfo.Strength, -1.0) = 1.0
Order By MixInfo.AutoID

Select *
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Where Isnull(MixInfo.Strength, -1.0) = 0.0
Order By MixInfo.AutoID

Update MixInfo
    Set MixInfo.StrengthAge = Null,
        MixInfo.Strength = Null
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Where Isnull(MixInfo.Strength, -1.0) = 1.0

Update MixInfo
    Set MixInfo.StrengthAge = Null,
        MixInfo.Strength = Null
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Where Isnull(MixInfo.Strength, -1.0) = 0.0

Select *
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Where Isnull(MixInfo.Strength, -1.0) = 1.0
Order By MixInfo.AutoID

Select *
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Where Isnull(MixInfo.Strength, -1.0) = 0.0
Order By MixInfo.AutoID
