Update MainInfo
    Set MainInfo.Name = Ltrim(Rtrim(Replace(MainInfo.Name, Char(160), ' '))),
    	MainInfo.Description = Ltrim(Rtrim(Replace(MainInfo.Description, Char(160), ' '))),
    	MainInfo.ShortDescription = Ltrim(Rtrim(Replace(MainInfo.ShortDescription, Char(160), ' '))),
    	MainInfo.ItemCategory = Ltrim(Rtrim(Replace(MainInfo.ItemCategory, Char(160), ' '))),
    	MainInfo.ItemCategoryDescription = Ltrim(Rtrim(Replace(MainInfo.ItemCategoryDescription, Char(160), ' '))),
    	MainInfo.FamilyMaterialTypeName = Ltrim(Rtrim(Replace(MainInfo.FamilyMaterialTypeName, Char(160), ' '))),
    	MainInfo.MaterialTypeName = Ltrim(Rtrim(Replace(MainInfo.MaterialTypeName, Char(160), ' '))),
    	MainInfo.IsLiquidAdmix = Ltrim(Rtrim(Replace(MainInfo.IsLiquidAdmix, Char(160), ' ')))
From Data_Import_RJ.dbo.TestImport0000_MainMaterialInfo As MainInfo

Update MaterialInfo
    Set MaterialInfo.SpecificGravity =
            Case 
                When Isnull(MaterialInfo.SpecificGravity, -1.0) >= 0.4
                Then MaterialInfo.SpecificGravity
                When Isnull(MaterialInfo.FamilyMaterialTypeName, '') = 'Admixture & Fiber' And Isnull(MaterialInfo.MaterialTypeName, '') In ('Color')
                Then 1.5
                When Isnull(MaterialInfo.FamilyMaterialTypeName, '') = 'Admixture & Fiber' And Isnull(MaterialInfo.MaterialTypeName, '') In ('Fibers', 'Blended Fibers', 'Glass Fibers', 'Natural Fibers', 'Steel Fibers', 'Structural Fibers', 'Synthetic Fibers')
                Then 0.91
                When Isnull(MaterialInfo.FamilyMaterialTypeName, '') = 'Admixture & Fiber'
                Then 1.0
                When Isnull(MaterialInfo.FamilyMaterialTypeName, '') = 'Aggregate'
                Then 2.65
                When Isnull(MaterialInfo.FamilyMaterialTypeName, '') = 'Cement'
                Then 3.15
                When Isnull(MaterialInfo.FamilyMaterialTypeName, '') = 'Mineral'
                Then 2.6
                When Isnull(MaterialInfo.FamilyMaterialTypeName, '') = 'Water'
                Then 0.9982
                Else MaterialInfo.SpecificGravity
            End,
        MaterialInfo.IsLiquidAdmix =
            Case 
                When Isnull(MaterialInfo.FamilyMaterialTypeName, '') = 'Admixture & Fiber' And Isnull(MaterialInfo.IsLiquidAdmix, '') In ('Yes', 'No')
                Then MaterialInfo.IsLiquidAdmix
                When Isnull(MaterialInfo.FamilyMaterialTypeName, '') = 'Admixture & Fiber' And Isnull(MaterialInfo.MaterialTypeName, '') Not In ('Color', 'Fibers', 'Blended Fibers', 'Glass Fibers', 'Natural Fibers', 'Steel Fibers', 'Structural Fibers', 'Synthetic Fibers')
                Then 'Yes'
                Else 'No'
            End,
        MaterialInfo.MoisturePct =
            Case
                When Isnull(MaterialInfo.FamilyMaterialTypeName, '') = 'Admixture & Fiber' 
                Then Isnull(MaterialInfo.MoisturePct, 0.0)
                Else Null
            End
From Data_Import_RJ.dbo.TestImport0000_MainMaterialInfo As MaterialInfo

