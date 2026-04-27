If Exists (Select * From Sys.databases Where Name = 'Data_Import_RJ')
Begin
    If Exists (Select * From Data_Import_RJ.sys.objects Where Name = 'TestImport0000_MaterialInfo')
    Begin
		--> Delete From Data_Import_RJ.dbo.TestImport0000_MainMaterialInfo
		
    	Insert into Data_Import_RJ.dbo.TestImport0000_MainMaterialInfo
    	(
    		Name, Description, ShortDescription, ItemCategory,
    		ItemCategoryDescription, FamilyMaterialTypeName, MaterialTypeName,
    		SpecificGravity, MoisturePct, IsLiquidAdmix
    	)
		
    	Select  MaterialInfo.ItemCode, MaterialInfo.ItemDescription,
    	        MaterialInfo.ItemShortDescription, MaterialInfo.ItemCategoryName,
    	        MaterialInfo.ItemCategoryDescription,
    	        MaterialInfo.FamilyMaterialTypeName, MaterialInfo.MaterialTypeName,
    	        MaterialInfo.SpecificGravity, MaterialInfo.MoisturePct, MaterialInfo.IsLiquidAdmix
    	From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
    	Left Join Data_Import_RJ.dbo.TestImport0000_MainMaterialInfo As MainInfo
    	On MaterialInfo.ItemCode = MainInfo.Name
    	Where   MainInfo.AutoID Is Null And
    	        --Isnull(MaterialInfo.MaterialTypeName, '') = '' And
    	        MaterialInfo.AutoID In
    	        (
    	            Select Min(MaterialInfo.AutoID)
    	            From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
    	            Group By MaterialInfo.ItemCode
    	        )
    	Order By MaterialInfo.FamilyMaterialTypeName, MaterialInfo.ItemCategoryName, MaterialInfo.ItemDescription
    	Update MaterialInfo
    	    Set MaterialInfo.SpecificGravity = TargetInfo.SpecificGravity
    	From Data_Import_RJ.dbo.TestImport0000_MainMaterialInfo As MaterialInfo
    	Inner Join Data_Import_RJ.dbo.TestImport0000_MaterialInfo As TargetInfo
    	On  MaterialInfo.Name = TargetInfo.ItemCode And
    	    Isnull(MaterialInfo.SpecificGravity, -1.0) < 0.4 And
    	    Isnull(TargetInfo.SpecificGravity, -1.0) >= 0.4

    	Update MaterialInfo
    	    Set MaterialInfo.MoisturePct = 0.0, MaterialInfo.IsLiquidAdmix = 'No'
    	From Data_Import_RJ.dbo.TestImport0000_MainMaterialInfo As MaterialInfo
    	Where Isnull(MaterialInfo.FamilyMaterialTypeName, '') <> 'Admixture & Fiber'
    End
End
Go
