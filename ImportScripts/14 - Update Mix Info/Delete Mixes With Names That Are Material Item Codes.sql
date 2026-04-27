Select MixInfo.*
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Where   MixInfo.MixCode In 
        (
        	Select MixInfo2.MaterialItemCode 
        	From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo2 
        	Group By MixInfo2.MaterialItemCode
        	
        	Union All
        	
        	Select MaterialInfo.ItemCode
        	From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
        	Group By MaterialInfo.ItemCode
        )
Order By MixInfo.AutoID

Delete MixInfo
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Where   MixInfo.MixCode In 
        (
        	Select MixInfo2.MaterialItemCode 
        	From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo2 
        	Group By MixInfo2.MaterialItemCode
        	
        	Union All
        	
        	Select MaterialInfo.ItemCode
        	From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
        	Group By MaterialInfo.ItemCode
        )
