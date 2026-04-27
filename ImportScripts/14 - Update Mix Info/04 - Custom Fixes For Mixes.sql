If Exists (Select * From Sys.databases Where Name = 'Data_Import_RJ')
Begin
    If Exists (Select * From Data_Import_RJ.sys.objects Where Name = 'TestImport0000_MixInfo')
    Begin
		Update MixInfo
			Set MixInfo.PlantCode = LTrim(RTrim(Replace(MixInfo.PlantCode, Char(160), ' '))),
				MixInfo.MixCode = LTrim(RTrim(Replace(MixInfo.MixCode, Char(160), ' '))),
				MixInfo.MixDescription = LTrim(RTrim(Replace(MixInfo.MixDescription, Char(160), ' '))),
				MixInfo.MixShortDescription = LTrim(RTrim(Replace(MixInfo.MixShortDescription, Char(160), ' '))),
				MixInfo.ItemCategory = LTrim(RTrim(Replace(MixInfo.ItemCategory, Char(160), ' '))),
				MixInfo.DispatchSlumpRange = LTrim(RTrim(Replace(MixInfo.DispatchSlumpRange, Char(160), ' '))),
				MixInfo.PriceUnitName = LTrim(RTrim(Replace(MixInfo.PriceUnitName, Char(160), ' '))),
				MixInfo.MixInactive = LTrim(RTrim(Replace(MixInfo.MixInactive, Char(160), ' '))),
		        MixInfo.MixClassNames = LTrim(RTrim(Replace(MixInfo.MixClassNames, Char(160), ' '))),
		        MixInfo.MixUsage = LTrim(RTrim(Replace(MixInfo.MixUsage, Char(160), ' '))),
		        MixInfo.AttachmentFileNames = LTrim(RTrim(Replace(MixInfo.AttachmentFileNames, Char(160), ' '))),
				MixInfo.Padding1 = LTrim(RTrim(Replace(MixInfo.Padding1, Char(160), ' '))),
				MixInfo.MaterialItemCode = LTrim(RTrim(Replace(MixInfo.MaterialItemCode, Char(160), ' '))),
				MixInfo.MaterialItemDescription = LTrim(RTrim(Replace(MixInfo.MaterialItemDescription, Char(160), ' '))),
				MixInfo.QuantityUnitName = LTrim(RTrim(Replace(MixInfo.QuantityUnitName, Char(160), ' ')))
		From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
    End
End
Go

Select	MixInfo.Slump, 
		Case
			When IsNull(MixInfo.Slump, -1.0) <= 0.0
			Then Null
			Else Round(MixInfo.Slump / 25.4, 4)
		End,
		MixInfo.Strength, 
		Case 
			When IsNull(MixInfo.Strength, -1.0) <= 0.0 
			Then Null 
			Else Round(MixInfo.Strength * 145.037743897283, 2)
		End
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo


Update MixInfo
Set	MixInfo.Slump =
		Case
			When IsNull(MixInfo.Slump, -1.0) <= 0.0
			Then Null
			Else Round(MixInfo.Slump / 25.4, 4)
		End,
		MixInfo.Strength =
		Case 
			When IsNull(MixInfo.Strength, -1.0) <= 0.0 
			Then Null 
			Else Round(MixInfo.Strength * 145.037743897283, 2)
		End
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo

