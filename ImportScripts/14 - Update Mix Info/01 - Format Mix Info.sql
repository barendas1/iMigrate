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

If Exists (Select * From Sys.databases Where Name = 'Data_Import_RJ')
Begin
    If Exists (Select * From Data_Import_RJ.sys.objects Where Name = 'TestImport0000_MixInfo')
    Begin
    	/*
		Update MixInfo
			Set MixInfo.PlantCode = Upper(MixInfo.PlantCode),
				MixInfo.MixCode = Upper(MixInfo.MixCode),
				MixInfo.MixDescription = Upper(MixInfo.MixDescription),
				MixInfo.MixShortDescription = Upper(MixInfo.MixShortDescription),
				MixInfo.ItemCategory = Upper(MixInfo.ItemCategory),
				MixInfo.Padding1 = Upper(MixInfo.Padding1),
				MixInfo.MaterialItemCode = Upper(MixInfo.MaterialItemCode),
				MixInfo.MaterialItemDescription = Upper(MixInfo.MaterialItemDescription),
				MixInfo.QuantityUnitName = Upper(MixInfo.QuantityUnitName)
		From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
        */
        
		Update MixInfo
			Set MixInfo.MinAirContent = 
					Case 
						when Round(Isnull(MixInfo.MinAirContent, -1.0), 2) <= 0.0 And Round(Isnull(MixInfo.MaxAirContent, -1.0), 2) <= 0.0
						Then Null
						Else MixInfo.MinAirContent
					End,
				MixInfo.MaxAirContent =
					Case 
						when Round(Isnull(MixInfo.MinAirContent, -1.0), 2) <= 0.0 And Round(Isnull(MixInfo.MaxAirContent, -1.0), 2) <= 0.0
						Then Null
						Else MixInfo.MaxAirContent
					End,
				MixInfo.Slump = 
					Case 
						when Round(Isnull(MixInfo.Slump, -1.0), 2) <= 0.0 
						Then Null 
						Else MixInfo.Slump 
					End,
				MixInfo.MinSlump =
					Case 
						when Round(Isnull(MixInfo.MinSlump, -1.0), 2) <= 0.0 And Round(Isnull(MixInfo.MaxSlump, -1.0), 2) <= 0.0
						Then Null
						Else MixInfo.MinSlump
					End,
				MixInfo.MaxSlump =
					Case 
						when Round(Isnull(MixInfo.MinSlump, -1.0), 2) <= 0.0 And Round(Isnull(MixInfo.MaxSlump, -1.0), 2) <= 0.0
						Then Null
						Else MixInfo.MaxSlump
					End,
				MixInfo.MaxLoadSize = 
					Case 
						when Round(Isnull(MixInfo.MaxLoadSize, -1.0), 4) <= 0.0
						Then Null
						Else MixInfo.MaxLoadSize
					End,
				MixInfo.SackContent = 
					Case 
						when Round(Isnull(MixInfo.SackContent, -1.0), 4) <= 0.0
						Then Null
						Else MixInfo.SackContent
					End,
				MixInfo.Price = 
					Case 
						when Round(Isnull(MixInfo.Price, -1.0), 4) < 0.0
						Then Null
						Else MixInfo.Price
					End				    
		From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
    End
End
Go
