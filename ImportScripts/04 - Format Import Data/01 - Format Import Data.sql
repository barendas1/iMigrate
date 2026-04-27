If Exists (Select * From Sys.databases Where Name = 'Data_Import_RJ')
Begin
    If Exists (Select * From Data_Import_RJ.sys.objects Where Name = 'TestImport0000_MaterialItemCategory')
    Begin
		Update ItemCategoryInfo
			Set	ItemCategoryInfo.Name = LTrim(RTrim(Replace(ItemCategoryInfo.Name, Char(160), ' '))),
				ItemCategoryInfo.Description = LTrim(RTrim(Replace(ItemCategoryInfo.Description, Char(160), ' '))),
				ItemCategoryInfo.ShortDescription = LTrim(RTrim(Replace(ItemCategoryInfo.ShortDescription, Char(160), ' '))),
				ItemCategoryInfo.CategoryNumber = LTrim(RTrim(Replace(ItemCategoryInfo.CategoryNumber, Char(160), ' '))),
				ItemCategoryInfo.CategoryType = LTrim(RTrim(Replace(ItemCategoryInfo.CategoryType, Char(160), ' '))),
				ItemCategoryInfo.FamilyMaterialTypeName = LTrim(RTrim(Replace(ItemCategoryInfo.FamilyMaterialTypeName, Char(160), ' '))),
				ItemCategoryInfo.MaterialTypeName = LTrim(RTrim(Replace(ItemCategoryInfo.MaterialTypeName, Char(160), ' '))),
				ItemCategoryInfo.IsLiquidAdmix = LTrim(RTrim(Replace(ItemCategoryInfo.IsLiquidAdmix, Char(160), ' ')))
		From Data_Import_RJ.dbo.TestImport0000_MaterialItemCategory As ItemCategoryInfo
	End
End
Go

If Exists (Select * From Sys.databases Where Name = 'Data_Import_RJ')
Begin
    If Exists (Select * From Data_Import_RJ.sys.objects Where Name = 'TestImport0000_MixItemCategory')
    Begin
		Update ItemCategoryInfo
			Set	ItemCategoryInfo.Name = LTrim(RTrim(Replace(ItemCategoryInfo.Name, Char(160), ' '))),
				ItemCategoryInfo.Description = LTrim(RTrim(Replace(ItemCategoryInfo.Description, Char(160), ' '))),
				ItemCategoryInfo.ShortDescription = LTrim(RTrim(Replace(ItemCategoryInfo.ShortDescription, Char(160), ' '))),
				ItemCategoryInfo.CategoryNumber = LTrim(RTrim(Replace(ItemCategoryInfo.CategoryNumber, Char(160), ' '))),
				ItemCategoryInfo.CategoryType = LTrim(RTrim(Replace(ItemCategoryInfo.CategoryType, Char(160), ' ')))
		From Data_Import_RJ.dbo.TestImport0000_MixItemCategory As ItemCategoryInfo
	End
End
Go

If Exists (Select * From Sys.databases Where Name = 'Data_Import_RJ')
Begin
    If Exists (Select * From Data_Import_RJ.sys.objects Where Name = 'TestImport0000_PlantInfo')
    Begin
		Update PlantInfo
			Set PlantInfo.Name = LTrim(RTrim(Replace(PlantInfo.Name, Char(160), ' '))),
				PlantInfo.Description = LTrim(RTrim(Replace(PlantInfo.Description, Char(160), ' '))),
				PlantInfo.MaxBatchSizeUnitName = LTrim(RTrim(Replace(PlantInfo.MaxBatchSizeUnitName, Char(160), ' ')))
		From Data_Import_RJ.dbo.TestImport0000_PlantInfo As PlantInfo
	End
End
Go

If Exists (Select * From Sys.databases Where Name = 'Data_Import_RJ')
Begin
    If Exists (Select * From Data_Import_RJ.sys.objects Where Name = 'TestImport0000_MaterialInfo')
    Begin
		Update MaterialInfo
			Set MaterialInfo.PlantName = LTrim(RTrim(Replace(MaterialInfo.PlantName, Char(160), ' '))),
				MaterialInfo.TradeName = LTrim(RTrim(Replace(MaterialInfo.TradeName, Char(160), ' '))),
				MaterialInfo.MaterialDate = LTrim(RTrim(Replace(MaterialInfo.MaterialDate, Char(160), ' '))),
				MaterialInfo.FamilyMaterialTypeName = LTrim(RTrim(Replace(MaterialInfo.FamilyMaterialTypeName, Char(160), ' '))),
				MaterialInfo.MaterialTypeName = LTrim(RTrim(Replace(MaterialInfo.MaterialTypeName, Char(160), ' '))),
				MaterialInfo.IsLiquidAdmix = LTrim(RTrim(Replace(MaterialInfo.IsLiquidAdmix, Char(160), ' '))),
				MaterialInfo.CostUnitName = LTrim(RTrim(Replace(MaterialInfo.CostUnitName, Char(160), ' '))),
				MaterialInfo.ManufacturerName = LTrim(RTrim(Replace(MaterialInfo.ManufacturerName, Char(160), ' '))),
				MaterialInfo.ManufacturerSourceName = LTrim(RTrim(Replace(MaterialInfo.ManufacturerSourceName, Char(160), ' '))),
				MaterialInfo.BatchingOrderNumber = LTrim(RTrim(Replace(MaterialInfo.BatchingOrderNumber, Char(160), ' '))),
				MaterialInfo.ItemCode = LTrim(RTrim(Replace(MaterialInfo.ItemCode, Char(160), ' '))),
				MaterialInfo.ItemDescription = LTrim(RTrim(Replace(MaterialInfo.ItemDescription, Char(160), ' '))),
				MaterialInfo.ItemShortDescription = LTrim(RTrim(Replace(MaterialInfo.ItemShortDescription, Char(160), ' '))),
				MaterialInfo.ItemCategoryName = LTrim(RTrim(Replace(MaterialInfo.ItemCategoryName, Char(160), ' '))),
				MaterialInfo.ItemCategoryDescription = LTrim(RTrim(Replace(MaterialInfo.ItemCategoryDescription, Char(160), ' '))),
				MaterialInfo.ItemCategoryShortDescription = LTrim(RTrim(Replace(MaterialInfo.ItemCategoryShortDescription, Char(160), ' '))),
				MaterialInfo.ComponentCategoryName = LTrim(RTrim(Replace(MaterialInfo.ComponentCategoryName, Char(160), ' '))),
				MaterialInfo.ComponentCategoryDescription = LTrim(RTrim(Replace(MaterialInfo.ComponentCategoryDescription, Char(160), ' '))),
				MaterialInfo.ComponentCategoryShortDescription = LTrim(RTrim(Replace(MaterialInfo.ComponentCategoryShortDescription, Char(160), ' '))),
				MaterialInfo.BatchPanelCode = LTrim(RTrim(Replace(MaterialInfo.BatchPanelCode, Char(160), ' ')))
		From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
    End
End
Go

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
