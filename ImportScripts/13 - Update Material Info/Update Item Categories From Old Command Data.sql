Update MaterialInfo
    Set MaterialInfo.ItemCategoryName = dbo.TrimNVarChar(ICAT.item_cat),
        MaterialInfo.ItemCategoryDescription = dbo.TrimNVarChar(ICAT.descr),
        MaterialInfo.ItemCategoryShortDescription = dbo.TrimNVarChar(ICAT.short_descr)
From Data_Import_RJ.Dbo.TestImport0000_MaterialInfo As MaterialInfo
Inner Join CmdTest_RJ.dbo.IMST As IMST
On  MaterialInfo.ItemCode = IMST.item_code
Inner Join CmdTest_RJ.dbo.ICAT As ICAT
On IMST.item_cat = ICAT.item_cat
Where Isnull(MaterialInfo.ItemCategoryName, '') = ''
