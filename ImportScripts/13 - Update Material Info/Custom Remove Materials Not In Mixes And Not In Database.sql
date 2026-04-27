Delete MaterialInfo
From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
Where   MaterialInfo.AutoID Not In
        (
            Select MaterialInfo.AutoID
            From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
            Inner Join
            (
	            Select MixInfo.PlantCode As PlantName, MixInfo.MaterialItemCode As ItemCode
	            From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
	            Group By MixInfo.PlantCode, MixInfo.MaterialItemCode
            ) As MixMaterial
            On  MaterialInfo.PlantName = MixMaterial.PlantName And
                MaterialInfo.ItemCode = MixMaterial.ItemCode
            Left Join 
            (
                Select -1 As ID, Plant.Name As PlantCode, ItemName.Name As MaterialItemCode
                From dbo.Plants As Plant
                Inner Join dbo.MATERIAL As Material
                On Material.PlantID = Plant.PlantId
                Inner Join dbo.ItemMaster As ItemMaster
                On ItemMaster.ItemMasterID = Material.ItemMasterID
                Inner Join dbo.Name As ItemName
                On ItemName.NameID = ItemMaster.NameID
                Group By Plant.Name, ItemName.Name
            ) As ExistingMaterial
            On  MaterialInfo.PlantName = ExistingMaterial.PlantCode And
                MaterialInfo.ItemCode = ExistingMaterial.MaterialItemCode
            Where ExistingMaterial.ID Is Null
        )
