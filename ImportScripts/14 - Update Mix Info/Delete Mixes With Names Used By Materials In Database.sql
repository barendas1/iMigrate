Select MixInfo.*
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Where   MixInfo.MixCode In 
        (
        	Select ItemName.Name
        	From dbo.MATERIAL As Material
        	Inner Join dbo.ItemMaster As ItemMaster
        	On ItemMaster.ItemMasterID = Material.ItemMasterID
        	Inner Join dbo.Name As ItemName
        	On ItemName.NameID = ItemMaster.NameID
        	Group By ItemName.Name
        	
        	Union All
        	
        	Select ItemCode.Name
        	From dbo.Name As ItemCode
        	Where ItemCode.NameType In ('Mtrl', 'MtrlItem', 'MtrlBatchCode')
        )
Order By MixInfo.AutoID

Delete MixInfo
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Where   MixInfo.MixCode In 
        (
        	Select ItemName.Name
        	From dbo.MATERIAL As Material
        	Inner Join dbo.ItemMaster As ItemMaster
        	On ItemMaster.ItemMasterID = Material.ItemMasterID
        	Inner Join dbo.Name As ItemName
        	On ItemName.NameID = ItemMaster.NameID
        	Group By ItemName.Name
        	
        	Union All
        	
        	Select ItemCode.Name
        	From dbo.Name As ItemCode
        	Where ItemCode.NameType In ('Mtrl', 'MtrlItem', 'MtrlBatchCode')
        )
