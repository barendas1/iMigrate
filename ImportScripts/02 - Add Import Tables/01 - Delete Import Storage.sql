If Exists (Select * From Sys.databases Where Name = 'Data_Import_RJ')
Begin
	If Exists (Select * From Data_Import_RJ.sys.objects Where Name = 'TestImport0000_MixItemCategory')
	Begin
		Drop Table Data_Import_RJ.dbo.TestImport0000_MixItemCategory
	End

	If Exists (Select * From Data_Import_RJ.sys.objects Where Name = 'TestImport0000_MaterialItemCategory')
	Begin
		Drop Table Data_Import_RJ.dbo.TestImport0000_MaterialItemCategory
	End

	If Exists (Select * From Data_Import_RJ.sys.objects Where Name = 'TestImport0000_MainMaterialInfo')
	Begin
		Drop Table Data_Import_RJ.dbo.TestImport0000_MainMaterialInfo
	End

	If Exists (Select * From Data_Import_RJ.sys.objects Where Name = 'TestImport0000_MaterialInfo')
	Begin
		Drop Table Data_Import_RJ.dbo.TestImport0000_MaterialInfo
	End

	If Object_ID(N'[Data_Import_RJ].[dbo].[TestImport0000_MixInfo]') Is Not Null
	Begin
		Drop Table [Data_Import_RJ].[dbo].[TestImport0000_MixInfo]
	End
	
	--Drop Table [Data_Import_RJ].[dbo].[TestImport0000_PlantInfo]
	If Object_ID(N'[Data_Import_RJ].[dbo].[TestImport0000_PlantInfo]') Is Not Null
	Begin
		Drop Table [Data_Import_RJ].[dbo].[TestImport0000_PlantInfo]
	End	
	
	If Object_ID(N'[Data_Import_RJ].[dbo].[TestImport0000_MixInfoNotDeleted]') Is Not Null
	Begin
		Drop Table [Data_Import_RJ].[dbo].[TestImport0000_MixInfoNotDeleted]
	End	
	
	If Object_ID(N'[Data_Import_RJ].[dbo].[TestImport0000_MaterialItemCode]') Is Not Null
	Begin
		Drop Table [Data_Import_RJ].[dbo].[TestImport0000_MaterialItemCode]
	End	

	If Object_ID(N'[Data_Import_RJ].[dbo].[TestImport0000_OtherMaterialItemCategory]') Is Not Null
	Begin
		Drop Table [Data_Import_RJ].[dbo].[TestImport0000_OtherMaterialItemCategory]
	End	
End
Go

If Exists (Select * From Sys.databases Where Name = 'Data_Import_RJ')
Begin
	If Exists (Select * From Data_Import_RJ.sys.objects Where Name = 'TestImport0000_XML_Location')
	Begin
		Drop Table Data_Import_RJ.dbo.TestImport0000_XML_Location
	End
	
	If Exists (Select * From Data_Import_RJ.sys.objects Where Name = 'TestImport0000_XML_Plant')
	Begin
		Drop Table Data_Import_RJ.dbo.TestImport0000_XML_Plant
	End
	
	If Exists (Select * From Data_Import_RJ.sys.objects Where Name = 'TestImport0000_XML_ItemCategory')
	Begin
		Drop Table Data_Import_RJ.dbo.TestImport0000_XML_ItemCategory
	End
	
	If Exists (Select * From Data_Import_RJ.sys.objects Where Name = 'TestImport0000_XML_ItemType')
	Begin
		Drop Table Data_Import_RJ.dbo.TestImport0000_XML_ItemType
	End
	
	If Exists (Select * From Data_Import_RJ.sys.objects Where Name = 'TestImport0000_XML_Material')
	Begin
		Drop Table Data_Import_RJ.dbo.TestImport0000_XML_Material
	End
	
	If Exists (Select * From Data_Import_RJ.sys.objects Where Name = 'TestImport0000_XML_Mix')
	Begin
		Drop Table Data_Import_RJ.dbo.TestImport0000_XML_Mix
	End
	
	If Exists (Select * From Data_Import_RJ.sys.objects Where Name = 'TestImport0000_XML_MixProps')
	Begin
		Drop Table Data_Import_RJ.dbo.TestImport0000_XML_MixProps
	End
	
End
Go
