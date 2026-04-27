If	Exists (Select * From Sys.databases Where Name = 'Data_Import_RJ') And
	Exists (Select * From INFORMATION_SCHEMA.TABLES As TableInfo Where TableInfo.TABLE_NAME = 'ACIBatchViewDetails')
Begin
    If Exists (Select * From Data_Import_RJ.sys.objects Where Name = 'TestImport0000_MaterialInfo')
    Begin
    	Update MaterialInfo
    	    Set MaterialInfo.TradeName = MaterialInfo.ItemCode
    	--Select *
    	From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
    	Inner Join
    	(
    		Select Plant.Name As PlantCode, TradeName.Name As TradeName, Min(ItemName.Name) As ItemCode
    		From dbo.Plants As Plant
    		Inner Join dbo.MATERIAL As Material
    		On Material.PlantID = Plant.PlantId
    		Inner Join dbo.Name As TradeName
    		On TradeName.NameID = Material.NameID
    		Inner Join dbo.ItemMaster As ItemMaster
    		On ItemMaster.ItemMasterID = Material.ItemMasterID
    		Inner Join dbo.Name As ItemName
    		On ItemName.NameID = ItemMaster.NameID
    		Group By Plant.Name, TradeName.Name
    	) As MaterialData
    	On  MaterialInfo.PlantName = MaterialData.PlantCode And
    	    MaterialInfo.TradeName = MaterialData.TradeName
    	Where Isnull(MaterialInfo.ItemCode, '') <> Isnull(MaterialData.ItemCode, '')
    End
End
Go
