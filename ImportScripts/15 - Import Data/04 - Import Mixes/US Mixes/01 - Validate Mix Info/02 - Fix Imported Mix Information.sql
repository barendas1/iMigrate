/*
Select *
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Where Isnull(MixInfo.QuantityUnitName, '') = ''

Update MixInfo
    Set MixInfo.QuantityUnitName = 'Oz'
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Where   Isnull(MixInfo.MaterialItemCode, '') In ('DARAFILDRY') And
        Isnull(MixInfo.QuantityUnitName, '') = ''
*/
/*
Delete MixInfo
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Where MixInfo.MixCode = 'Sand'
*/
/*
Select 
		MixInfo.MaximumWater, MixInfo.MaximumWater * 0.26417205,
		MixInfo.Slump, MixInfo.Slump / 25.4,
		MixInfo.MinSlump,
		Case
			When MixInfo.Slump / 25.4 - 2.0 < 0.0
			Then 0.0
			Else MixInfo.Slump / 25.4 - 2.0
		End,
		MixInfo.MaxSlump, MixInfo.Slump / 25.4 + 2.0,
		MixInfo.*
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Where MixInfo.Slump > 12 Or MixInfo.MixDescription Like '%Metric%'
Order By MixInfo.AutoID

Update MixInfo 
		Set MixInfo.MaximumWater = MixInfo.MaximumWater * 0.26417205,
			MixInfo.Slump = MixInfo.Slump / 25.4,
			MixInfo.MinSlump =
				Case
					When MixInfo.Slump / 25.4 - 2.0 < 0.0
					Then 0.0
					Else MixInfo.Slump / 25.4 - 2.0
				End,
			MixInfo.MaxSlump = MixInfo.Slump / 25.4 + 2.0
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Where MixInfo.Slump > 12 Or MixInfo.MixDescription Like '%Metric%'
*/