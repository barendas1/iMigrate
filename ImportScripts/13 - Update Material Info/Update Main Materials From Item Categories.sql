Update MaterialInfo
    Set MaterialInfo.FamilyMaterialTypeName = CategoryInfo.FamilyMaterialTypeName,
        MaterialInfo.MaterialTypeName = CategoryInfo.MaterialTypeName,
        --MaterialInfo.SpecificGravity = CategoryInfo.SpecificGravity,
        MaterialInfo.IsLiquidAdmix = CategoryInfo.IsLiquidAdmix
From Data_Import_RJ.dbo.TestImport0000_MainMaterialInfo As MaterialInfo
Inner Join Data_Import_RJ.dbo.TestImport0000_MaterialItemCategory As CategoryInfo
On MaterialInfo.ItemCategory = CategoryInfo.Name
Where MaterialInfo.FamilyMaterialTypeName = 'Admixture & Fiber'
