Select *
From Data_Import_RJ.dbo.TestImport0000_MaterialInfo

Select ILOC.loc_code, ILOC.item_code, IMLB.batch_code, PanelName.Name
From CmdTest_RJ.dbo.imst As IMST
Inner Join Data_Import_RJ.dbo.TestImport0000_MaterialItemCategory As CategoryInfo
On Ltrim(Rtrim(IMST.item_cat)) = Ltrim(Rtrim(CategoryInfo.Name))
Inner Join CmdTest_RJ.dbo.icat As ICAT
On Ltrim(Rtrim(IMST.item_cat)) = Ltrim(Rtrim(ICAT.item_cat))
Inner Join CmdTest_RJ.dbo.iloc As ILOC
On LTrim(RTrim(ILOC.item_code)) = LTrim(RTrim(IMST.item_code))
Left Join CmdTest_RJ.dbo.imlb As IMLB
On	LTrim(RTrim(IMLB.loc_code)) = LTrim(RTrim(ILOC.loc_code)) And
	LTrim(RTrim(IMLB.item_code)) = LTrim(RTrim(ILOC.item_code))
Inner Join Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
On	LTrim(RTrim(ILOC.loc_code)) = LTrim(RTrim(MaterialInfo.PlantName)) And
	LTrim(RTrim(ILOC.item_code)) = LTrim(RTrim(MaterialInfo.ItemCode))
Inner Join dbo.Name As ItemName
On Ltrim(Rtrim(Imst.item_code)) = ItemName.Name
Inner Join dbo.ItemMaster As ItemMaster
On ItemMaster.NameID = ItemName.NameID
Left Join dbo.[Description] As ItemDescr
On ItemDescr.DescriptionID = ItemMaster.DescriptionID
Left Join dbo.ProductionItemCategory As ProdCategoryInfo
On ProdCategoryInfo.ProdItemCatID = ItemMaster.ProdItemCatID
Inner Join dbo.Plants As Plants
On Ltrim(Rtrim(iloc.loc_code)) = Plants.Name
Inner Join dbo.MATERIAL As Material
On	Material.PlantID = Plants.PlantId And
	Material.ItemMasterID = ItemMaster.ItemMasterID
Inner Join dbo.Name As TradeName
On TradeName.NameID = Material.NameID
Left Join dbo.[Description] As MtrlDescr
On MtrlDescr.DescriptionID = Material.DescriptionID
Left Join dbo.Name As PanelName
On PanelName.NameID = Material.BatchPanelNameID
Inner Join iServiceDataExchange.dbo.MaterialType As FamilyMaterialType
On Material.FamilyMaterialTypeID = FamilyMaterialType.MaterialTypeID
Inner Join iServiceDataExchange.dbo.MaterialType As MaterialTypeInfo
On Material.MaterialTypeLink = MaterialTypeInfo.MaterialTypeID
Where	Ltrim(Rtrim(Isnull(IMST.descr, ''))) <> Ltrim(Rtrim(Isnull(ItemDescr.[Description], ''))) Or
		Ltrim(Rtrim(Isnull(IMST.descr, ''))) <> Ltrim(Rtrim(Isnull(TradeName.Name, ''))) Or
		Ltrim(Rtrim(Isnull(Imst.descr, ''))) <> Ltrim(Rtrim(Isnull(MtrlDescr.[Description], ''))) Or
		Ltrim(Rtrim(Isnull(IMST.descr, ''))) <> Ltrim(Rtrim(Isnull(Material.BatchPanelDescription, ''))) Or
		Ltrim(Rtrim(Isnull(IMST.short_descr, ''))) <> Ltrim(Rtrim(Isnull(ItemMaster.ItemShortDescription, ''))) Or
		Ltrim(Rtrim(Isnull(IMLB.batch_code, ''))) <> Ltrim(Rtrim(Isnull(PanelName.Name, ''))) Or
		Ltrim(Rtrim(Isnull(IMST.item_cat, ''))) <> Ltrim(Rtrim(Isnull(ProdCategoryInfo.ItemCategory, ''))) Or
		Ltrim(Rtrim(Isnull(ICAT.descr, ''))) <> Ltrim(Rtrim(Isnull(ProdCategoryInfo.[Description], ''))) Or
		Ltrim(Rtrim(Isnull(ICAT.short_descr, ''))) <> Ltrim(Rtrim(Isnull(ProdCategoryInfo.ShortDescription, ''))) Or
		Ltrim(Rtrim(Isnull(MaterialInfo.FamilyMaterialTypeName, ''))) <> Ltrim(Rtrim(Isnull(FamilyMaterialType.MaterialType, ''))) Or
		Ltrim(Rtrim(Isnull(MaterialInfo.MaterialTypeName, ''))) <> Ltrim(Rtrim(Isnull(MaterialTypeInfo.MaterialType, ''))) Or
		Ltrim(Rtrim(Isnull(MaterialInfo.SpecificGravity, ''))) <> Ltrim(Rtrim(Isnull(Material.SPECGR, '')))