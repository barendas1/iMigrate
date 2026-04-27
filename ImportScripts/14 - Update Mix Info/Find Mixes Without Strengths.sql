Select * 
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Where Isnull(MixInfo.Strength, -1.0) <= 0.0
Order By MixInfo.AutoID

Select * 
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Where Isnull(MixInfo.Strength, -1.0) = 1.0
Order By MixInfo.AutoID

Select * 
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Where MixInfo.Strength Is Not Null
Order By MixInfo.AutoID

Select *
From Data_Import_RJ.dbo.TestImport0000_XML_Mix As MixInfo
Where MixInfo.Strength = 1000
Order By MixInfo.AutoID

Select * 
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Order By MixInfo.AutoID

Select * 
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Where   Isnull(MixInfo.Strength, -1.0) <= 0.0 And
        (
            Isnull(MixInfo.MixDescription, '') Like '%Flex%' Or
            Isnull(MixInfo.MixShortDescription, '') Like '%Flex%'
        )
Order By MixInfo.AutoID

Select * 
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Where MixInfo.Strength < 100.0
Order By MixInfo.AutoID

Select * 
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Where MixInfo.Strength < 49.0
Order By MixInfo.AutoID
