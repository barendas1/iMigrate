SELECT        Name, Description, FamilyMaterialTypeName, MaterialTypeName, SpecificGravity, MoisturePct, IsLiquidAdmix, ShortDescription, ItemCategory, ItemCategoryDescription, AutoID
FROM            TestImport0000_MainMaterialInfo
Order By FamilyMaterialTypeName, Description, Name
