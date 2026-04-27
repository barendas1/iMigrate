Select  MixInfo.PlantCode As [Plant Name],
        MixInfo.MixCode As [Mix Name],
        MixInfo.MixDescription As [Mix Description]
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Inner Join
(
    Select MixInfo2.MixCode
    From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo2
    Group By MixInfo2.MixCode
    Having Count(Distinct MixInfo2.MixDescription) > 1
) As MixNameInfo
On MixInfo.MixCode = MixNameInfo.MixCode
Group By MixInfo.PlantCode, MixInfo.MixCode, MixInfo.MixDescription
Order By MixInfo.MixCode, MixInfo.PlantCode, MixInfo.MixDescription
