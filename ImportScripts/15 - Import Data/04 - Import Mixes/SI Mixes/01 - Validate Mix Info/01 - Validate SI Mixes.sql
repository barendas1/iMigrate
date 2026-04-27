Declare @CheckForMixExistence Bit = 1
Declare @IncludeInactiveMaterials Bit = 0

If Object_id('TempDB..#MixIDList') Is Not null
Begin
	Drop table #MixIDList
End

If Object_id('TempDB..#MaterialInfo') Is Not null
Begin
	Drop table #MaterialInfo
End

Create Table #MixIDList 
(
	AutoID Int Identity (1, 1), 
	MixAutoID Int Primary Key
)

Create Index IX_MixIDList_AutoID On #MixIDList (AutoID)
Create Index IX_MixIDList_MixAutoID On #MixIDList (MixAutoID)
	
Create Table #MaterialInfo 
(
	AutoID Int Identity (1, 1), 
	FamilyMaterialTypeName Nvarchar (100), 
	PlantCode Nvarchar (100), 
	ItemCode Nvarchar (100)
)

Create Index IX_MaterialInfo_AutoID On #MaterialInfo (AutoID)
Create Index IX_MaterialInfo_FamilyMaterialTypeName On #MaterialInfo (FamilyMaterialTypeName)
Create Index IX_MaterialInfo_PlantCode On #MaterialInfo (PlantCode)
Create Index IX_MaterialInfo_ItemCode On #MaterialInfo (ItemCode)

Insert into #MaterialInfo (FamilyMaterialTypeName, PlantCode, ItemCode)
Select FamilyMaterialType.MaterialType, Plants.Name, ItemName.Name
From dbo.Plants As Plants
Inner Join dbo.MATERIAL As Material
On Material.PlantID = Plants.PlantId
Inner Join dbo.ItemMaster As ItemMaster
On ItemMaster.ItemMasterID = Material.ItemMasterID
Inner Join dbo.Name As ItemName
On ItemName.NameID = ItemMaster.NameID
Inner Join dbo.MaterialType As FamilyMaterialType
On Material.FamilyMaterialTypeID = FamilyMaterialType.MaterialTypeID
Where   (
	        Isnull(@IncludeInactiveMaterials, 0) = 1 Or
	        Isnull(@IncludeInactiveMaterials, 0) = 0 And
            Isnull(Material.Inactive, 0) = 0 
        ) And
		Isnull(Material.NotAllowedInMixAndBatchRecipes, 0) = 0 And
		Isnull(Material.OnlyAllowedInImportedBatchRecipes, 0) = 0


Insert into #MaterialInfo (FamilyMaterialTypeName, PlantCode, ItemCode)
Select FamilyMaterialType.MaterialType, Plants.Name, ItemName.Name
From dbo.Plants As Yards
Inner Join dbo.MATERIAL As Material
On Material.PlantID = Yards.PlantId
Inner Join dbo.Plants As Plants
On Yards.PlantId = Plants.PlantIdForYard
Inner Join dbo.ItemMaster As ItemMaster
On ItemMaster.ItemMasterID = Material.ItemMasterID
Inner Join dbo.Name As ItemName
On ItemName.NameID = ItemMaster.NameID
Inner Join dbo.MaterialType As FamilyMaterialType
On Material.FamilyMaterialTypeID = FamilyMaterialType.MaterialTypeID
Where   (
	        Isnull(@IncludeInactiveMaterials, 0) = 1 Or
	        Isnull(@IncludeInactiveMaterials, 0) = 0 And
            Isnull(Material.Inactive, 0) = 0 
        ) And
		Isnull(Material.NotAllowedInMixAndBatchRecipes, 0) = 0 And
		Isnull(Material.OnlyAllowedInImportedBatchRecipes, 0) = 0

/*
Select *
From #MaterialInfo As MaterialInfo
Order By MaterialInfo.PlantCode, MaterialInfo.ItemCode
*/
Insert into #MixIDList (MixAutoID)
Select Min(MixInfo.AutoID)
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Group By MixInfo.PlantCode, MixInfo.MixCode

Select	MixInfo.PlantCode As [Plant Name], 
		MixInfo.MixCode As [Mix Name], 
		MixInfo.MixDescription As [Mix Description],
		Case
			When Isnull(MixInfo.PlantCode, '') = ''
			Then 'The Plant Name is Missing.'
			Else ''
		End As [Status Message],
		Case
			When Isnull(MixInfo.MixCode, '') = ''
			Then 'The Mix Name is Missing.'
			Else ''
		End As [Status Message]
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Where	Isnull(MixInfo.PlantCode, '') = '' Or
		Isnull(MixInfo.MixCode, '') = ''
Order By MixInfo.PlantCode, MixInfo.MixCode

Select  MixInfo.PlantCode As [Plant Name],
        MixInfo.MixCode As [Mix Name],
        MixInfo.MixDescription As [Mix Description],
        MixInfo.MixShortDescription As [Mix Short Description],
        MixInfo.ItemCategory As [Item Category],
        MixInfo.StrengthAge As [Strength Age],
        MixInfo.Strength As [Strength],
        MixInfo.AirContent As [Air Content],
        MixInfo.MinAirContent As [Min Air Content],
        MixInfo.MaxAirContent As [Max Air Content],
        MixInfo.Slump As [Slump],
        MixInfo.MinSlump As [Min Slump],
        MixInfo.MaxSlump As [Max Slump],
        Case
			When Plant.PLANTIDENTIFIER Is Null
			Then 'The Plant does not exist.'
			Else ''
		End As [Status Message],
        Case
			When Mix.BATCHIDENTIFIER Is Not Null
			Then 'The Mix already exists.'
			Else ''
		End As [Status Message],
        Case
			When	MixInfo.StrengthAge Is Not null And
					Round(Isnull(MixInfo.StrengthAge, -1.0), 2) <= 0.0
			Then 'The Strength Age is Zero or less.'
			Else ''
		End As [Status Message],
        Case
			When	MixInfo.Strength Is Not null And 
					Round(Isnull(MixInfo.Strength, -1.0), 2) <= 0.0
			Then 'The Strength is Zero or less.'
			Else ''
		End As [Status Message],
        Case
			When	MixInfo.AirContent Is Not null And
					(
						Isnull(MixInfo.AirContent, -1.0) < 0.0 Or
						Isnull(MixInfo.AirContent, -1.0) > 50.0
					)
			Then 'The Air Content is not in the range of 0% to 50%.'
			Else ''
		End As [Status Message],
        Case
			When	MixInfo.MinAirContent Is Not null And
					(
						Isnull(MixInfo.MinAirContent, -1.0) < 0.0 Or
						Isnull(MixInfo.MinAirContent, -1.0) > 50.0
					)
			Then 'The Minimum Air Content is not in the range of 0% to 50%.'
			Else ''
		End As [Status Message],
        Case
			When	MixInfo.MaxAirContent Is Not null And 
					(
						Isnull(MixInfo.MaxAirContent, -1.0) < 0.0 Or
						Isnull(MixInfo.MaxAirContent, -1.0) > 50.0
					)
			Then 'The Maximum Air Content is not in the range of 0% to 50%.'
			Else ''
		End As [Status Message],
        Case
			When	MixInfo.MinAirContent Is Not null And
					MixInfo.MaxAirContent Is Not null And
					Isnull(MixInfo.MinAirContent, -1.0) > Isnull(MixInfo.MaxAirContent, -1.0)
			Then 'The Minimum Air Content is greater than the Maximum Air Content.'
			Else ''
		End As [Status Message],
        Case
			When	MixInfo.AirContent Is Not null And
					MixInfo.MinAirContent Is Not null And
					Isnull(MixInfo.MinAirContent, -1.0) > Isnull(MixInfo.AirContent, -1.0)
			Then 'The Air Content is less than the Minimum Air Content.'
			Else ''
		End As [Status Message],
        Case
			When	MixInfo.AirContent Is Not null And
					MixInfo.MaxAirContent Is Not null And
					Isnull(MixInfo.MaxAirContent, -1.0) < Isnull(MixInfo.AirContent, -1.0)
			Then 'The Air Content is greater than the Maximum Air Content.'
			Else ''
		End As [Status Message],
        Case
			When	MixInfo.Slump Is Not null And
					(
						Round(Isnull(MixInfo.Slump, -1.0), 2) <= 0.0 Or
						Isnull(MixInfo.Slump, -1.0) > 50.0 * 25.4
					)
			Then 'The Slump is not a value greater than Zero up to 1270.0.'
			Else ''
		End As [Status Message],
        Case
			When	MixInfo.MinSlump Is Not null And
					(
						Isnull(MixInfo.MinSlump, -1.0) < 0.0 Or
						Isnull(MixInfo.MinSlump, -1.0) > 50.0 * 25.4
					)
			Then 'The Minimum Slump is not a value from 0.0 to 1270.0.'
			Else ''
		End As [Status Message],
        Case
			When	MixInfo.MaxSlump Is Not null And
					(
						Isnull(MixInfo.MaxSlump, -1.0) < 0.0 Or
						Isnull(MixInfo.MaxSlump, -1.0) > 50.0 * 25.4
					)
			Then 'The Maximum Slump is not a value from 0.0 to 1270.0.'
			Else ''
		End As [Status Message],
        Case
			When	MixInfo.MinSlump Is Not null And
					MixInfo.MaxSlump Is Not null And
					Isnull(MixInfo.MinSlump, -1.0) > Isnull(MixInfo.MaxSlump, -1.0)
			Then 'The Minimum Slump is greater than the Maximum Slump.'
			Else ''
		End As [Status Message],
        Case
			When	MixInfo.Slump Is Not null And
					MixInfo.MinSlump Is Not null And
					Isnull(MixInfo.MinSlump, -1.0) > Isnull(MixInfo.Slump, -1.0)
			Then 'The Slump is less than the Minimum Slump.'
			Else ''
		End As [Status Message],
        Case
			When	MixInfo.Slump Is Not null And
					MixInfo.MaxSlump Is Not null And
					Isnull(MixInfo.MaxSlump, -1.0) < Isnull(MixInfo.Slump, -1.0)
			Then 'The Slump is greater than the Maximum Slump.'
			Else ''
		End As [Status Message],
        Case
			When	MixInfo.MaxLoadSize Is Not null And
					(
						Isnull(MixInfo.MaxLoadSize, -1.0) <= 0.0 Or
						Isnull(MixInfo.MaxLoadSize, -1.0) > 1000.0
					)
			Then 'The Maximum Load Size is not a value greater than Zero up to 1000.0.'
			Else ''
		End As [Status Message],
        Case
			When	MixInfo.SackContent Is Not null And
					(
						Isnull(MixInfo.SackContent, -1.0) <= 0.0 Or
						Isnull(MixInfo.SackContent, -1.0) > 200.0
					)
			Then 'The Sack Content is not a value greater than Zero up to 50.0.'
			Else ''
		End As [Status Message],
        Case
			When	MixInfo.Price Is Not null And
					(
						Isnull(MixInfo.Price, -1.0) < 0.0 Or
						Isnull(MixInfo.Price, -1.0) > 1000.0
					)
			Then 'The Price is not in the range of 0 to 1000.'
			Else ''
		End As [Status Message],
        Case
			When	MixInfo.SortNumber Is Not null And
					(
						Isnull(MixInfo.SortNumber, -1.0) < 0.0 Or
						Isnull(MixInfo.SortNumber, -1.0) > 1000.0
					)
			Then 'The Sort Number is not in the range of 0 to 1000.'
			Else ''
		End As [Status Message]
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Inner Join #MixIDList As MixIDList
On	MixInfo.AutoID = MixIDList.MixAutoID And
	Isnull(MixInfo.PlantCode, '') <> '' And
	Isnull(MixInfo.MixCode, '') <> ''
Left Join dbo.PLANT As Plant
On MixInfo.PlantCode = Plant.PLNTNAME
Left Join dbo.Name As MixNameInfo
On MixInfo.MixCode = MixNameInfo.Name
Left Join dbo.BATCH As Mix
On	Mix.Plant_Link = Plant.PLANTIDENTIFIER And
	Mix.NameID = MixNameInfo.NameID
Where	Plant.PLANTIDENTIFIER Is Null Or --
		@CheckForMixExistence = 1 And Mix.BATCHIDENTIFIER Is Not null Or --
		MixInfo.StrengthAge Is Not null And --
		Round(Isnull(MixInfo.StrengthAge, -1.0), 2) <= 0.0 Or --
		MixInfo.Strength Is Not null And --
		Round(Isnull(MixInfo.Strength, -1.0), 2) <= 0.0 Or --
		MixInfo.AirContent Is Not null And --
		(
			Isnull(MixInfo.AirContent, -1.0) < 0.0 Or
			Isnull(MixInfo.AirContent, -1.0) > 50.0
		) Or --
		MixInfo.MinAirContent Is Not null And --
		(
			Isnull(MixInfo.MinAirContent, -1.0) < 0.0 Or
			Isnull(MixInfo.MinAirContent, -1.0) > 50.0
		) Or --
		MixInfo.MaxAirContent Is Not null And --
		(
			Isnull(MixInfo.MaxAirContent, -1.0) < 0.0 Or
			Isnull(MixInfo.MaxAirContent, -1.0) > 50.0
		) Or --
		MixInfo.MinAirContent Is Not null And --
		MixInfo.MaxAirContent Is Not null And --
		Isnull(MixInfo.MinAirContent, -1.0) > Isnull(MixInfo.MaxAirContent, -1.0) Or --
		MixInfo.AirContent Is Not null And --
		MixInfo.MinAirContent Is Not null And --
		Isnull(MixInfo.MinAirContent, -1.0) > Isnull(MixInfo.AirContent, -1.0) Or --		
		MixInfo.AirContent Is Not null And --
		MixInfo.MaxAirContent Is Not null And --
		Isnull(MixInfo.MaxAirContent, -1.0) < Isnull(MixInfo.AirContent, -1.0) Or --
		MixInfo.Slump Is Not null And
		(
			Round(Isnull(MixInfo.Slump, -1.0), 2) <= 0.0 Or
			Isnull(MixInfo.Slump, -1.0) > 50.0 * 25.4
		) Or
		MixInfo.MinSlump Is Not null And
		(
			Isnull(MixInfo.MinSlump, -1.0) < 0.0 Or
			Isnull(MixInfo.MinSlump, -1.0) > 50.0 * 25.4
		) Or
		MixInfo.MaxSlump Is Not null And
		(
			Isnull(MixInfo.MaxSlump, -1.0) < 0.0 Or
			Isnull(MixInfo.MaxSlump, -1.0) > 50.0 * 25.4
		) Or
		MixInfo.MinSlump Is Not null And
		MixInfo.MaxSlump Is Not null And
		Isnull(MixInfo.MinSlump, -1.0) > Isnull(MixInfo.MaxSlump, -1.0) Or
		MixInfo.Slump Is Not null And
		MixInfo.MinSlump Is Not null And
		Isnull(MixInfo.MinSlump, -1.0) > Isnull(MixInfo.Slump, -1.0) Or		
		MixInfo.Slump Is Not null And
		MixInfo.MaxSlump Is Not null And
		Isnull(MixInfo.MaxSlump, -1.0) < Isnull(MixInfo.Slump, -1.0) Or
		MixInfo.MaxLoadSize Is Not null And
		(
			Isnull(MixInfo.MaxLoadSize, -1.0) <= 0.0 Or
			Isnull(MixInfo.MaxLoadSize, -1.0) > 1000.0
		) Or
		MixInfo.SackContent Is Not null And
		(
			Isnull(MixInfo.SackContent, -1.0) <= 0.0 Or
			Isnull(MixInfo.SackContent, -1.0) > 200.0
		) Or
		MixInfo.Price Is Not null And
		(
			Isnull(MixInfo.Price, -1.0) < 0.0 Or
			Isnull(MixInfo.Price, -1.0) > 1000.0
		) Or
		MixInfo.SortNumber Is Not null And
		(
			Isnull(MixInfo.SortNumber, -1.0) < 0.0 Or
			Isnull(MixInfo.SortNumber, -1.0) > 1000.0
		)
Order By MixInfo.PlantCode, MixInfo.MixCode	

Select MixInfo.PlantCode As [Plant Code], MixInfo.MixCode As [Mix Code], MixInfo.MixDescription As [Mix Description], 'The Mix Item Code is used for Materials in Quadrel.' As [Status Message]
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Inner Join dbo.Name As MixItemCode
On MixInfo.MixCode = MixItemCode.Name
Where MixItemCode.NameType Not In ('Mix', 'MixItem')
Group By MixInfo.PlantCode, MixInfo.MixCode, MixInfo.MixDescription
Order By MixInfo.PlantCode, MixInfo.MixCode

Select  MixInfo.PlantCode As [Plant Name],
        MixInfo.MixCode As [Mix Name],
        MixInfo.MixDescription As [Mix Description],
        MixInfo.MaterialItemCode As [Material Item Code],
        MixInfo.MaterialItemDescription As [Material Item Description],
        MixInfo.Quantity As [Quantity],
        MixInfo.QuantityUnitName As [Quantity Unit],
        'The Material listed in the Recipe is not listed in the Material Import Spreadsheet.' As [Status Message]
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Left Join Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
On	MixInfo.PlantCode = MaterialInfo.PlantName And
	MixInfo.MaterialItemCode = MaterialInfo.ItemCode
Left Join #MaterialInfo As DBMaterialInfo
On	MixInfo.PlantCode = DBMaterialInfo.PlantCode And
	MixInfo.MaterialItemCode = DBMaterialInfo.ItemCode
Where	MaterialInfo.AutoID Is Null And
		DBMaterialInfo.AutoID Is Null
Order By MixInfo.PlantCode, MixInfo.MixCode

Select  MixInfo.PlantCode As [Plant Name],
        MixInfo.MaterialItemCode As [Material Item Code],
        MixInfo.MaterialItemDescription As [Material Item Description],
        'The Material needs to be added.' As [Status Message]
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Left Join Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
On	MixInfo.PlantCode = MaterialInfo.PlantName And
	MixInfo.MaterialItemCode = MaterialInfo.ItemCode
Left Join #MaterialInfo As DBMaterialInfo
On	MixInfo.PlantCode = DBMaterialInfo.PlantCode And
	MixInfo.MaterialItemCode = DBMaterialInfo.ItemCode
Where	MaterialInfo.AutoID Is Null And
		DBMaterialInfo.AutoID Is Null
Group By MixInfo.PlantCode, MixInfo.MaterialItemCode, MixInfo.MaterialItemDescription
Order By MixInfo.MaterialItemCode, MixInfo.PlantCode

Select  MixInfo.PlantCode As [Plant Name],
        MixInfo.MaterialItemCode As [Material Item Code],
        MixInfo.MaterialItemDescription As [Material Item Description],
        'The Material needs to be added to be the Database.' As [Status Message]
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Left Join #MaterialInfo As DBMaterialInfo
On	MixInfo.PlantCode = DBMaterialInfo.PlantCode And
	MixInfo.MaterialItemCode = DBMaterialInfo.ItemCode
Where DBMaterialInfo.AutoID Is Null
Group By MixInfo.PlantCode, MixInfo.MaterialItemCode, MixInfo.MaterialItemDescription
Order By MixInfo.MaterialItemCode, MixInfo.PlantCode

Select  MixRecipe.PlantCode As [Plant Name],
        MixRecipe.MixCode As [Mix Name],
        MixRecipe.MixDescription As [Mix Description],
        MixRecipe.MaterialItemCode As [Material Item Code],
        MixRecipe.MaterialItemDescription As [Material Item Description],
        MixRecipe.Quantity As [Quantity],
        MixRecipe.QuantityUnitName As [Quantity Unit],
        Case
			When IsNull(MixRecipe.MaterialItemCode, '') = ''
			Then 'The Material Item Code is missing.'
			Else ''
		End As [Status Message],
		Case
			When MixRecipe.Quantity Is Null
			Then 'The Mix Recipe Quantity is missing.'
			Else ''
		End As [Status Message],
		Case
			When MixRecipe.Quantity Is Not null And Isnull(MixRecipe.Quantity, -1.0) < 0.0
			Then 'The Mix Recipe Quantity is negative.'
			Else ''
		End As [Status Message],
		Case
			When Isnull(MixRecipe.QuantityUnitName, '') Not In ('lb', 'ga', 'oz', 'fl oz', 'Fluid Oz', 'L', 'LT', 'Liters', 'Litre', 'KG', 'ML','Ml-liter', 'GAL', 'GL', 'LQ OZ', 'Ounces', 'oz/cwt CM', 'Pounds', 'Gallons', 'Cubic Yards', 'Each', 'CC', 'GR')
			Then 'The Mix Recipe Quantity Units is not one of the following: lb, ga, oz, Fluid Oz, l, lt, kg, ml, GAL, LQ OZ, ounces, oz/cwt CM, pounds, gallons, Cubic Yards, Each, CC, GR, mL/100kg CM'
			Else ''
		End As [Status Message]
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixRecipe
Where	IsNull(MixRecipe.MaterialItemCode, '') = '' Or
		MixRecipe.Quantity Is Null Or
		IsNull(MixRecipe.Quantity, -1.0) < 0.0 Or 
		Isnull(MixRecipe.QuantityUnitName, '') Not In ('lb', 'ga', 'oz', 'fl oz', 'Fluid Oz', 'L', 'LT', 'Liters', 'Litre', 'KG', 'ML', 'Ml-liter', 'GAL', 'GL', 'LQ OZ', 'Ounces', 'oz/cwt CM', 'Pounds', 'Gallons', 'Cubic Yards', 'Each', 'CC', 'GR', 'mL/100kg CM')
Order By MixRecipe.PlantCode, MixRecipe.MixCode, MixRecipe.MaterialItemCode

Select	MixRecipe.PlantCode As [Plant Name], 
		MixRecipe.MixCode As [Mix Name], 
		MixRecipe.MaterialItemCode As [Material Item Code],
		'This Material Item Code is used more than once in the Mix Recipe.' As [Status Message]
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixRecipe
Group By MixRecipe.PlantCode, MixRecipe.MixCode, MixRecipe.MaterialItemCode
Having Count(*) > 1
Order By MixRecipe.PlantCode, MixRecipe.MixCode, MixRecipe.MaterialItemCode

Select	MixInfo.PlantCode As [Plant Name], 
		MixInfo.MixCode As [Mix Name],
		'The Mix has Admixtures or Fibers but does not have Cements or Minerals.' As [Status Message]
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Inner Join #MixIDList As MixIDList
On MixInfo.AutoID = MixIDList.MixAutoID
Left Join
(
	Select -1 As ID, MixInfo.PlantCode, MixInfo.MixCode
	From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
	Left Join Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
	On	MixInfo.PlantCode = MaterialInfo.PlantName And
		MixInfo.MaterialItemCode = MaterialInfo.ItemCode
	Left Join #MaterialInfo As ExistingMaterialInfo
	On	MixInfo.PlantCode = ExistingMaterialInfo.PlantCode And
		MixInfo.MaterialItemCode = ExistingMaterialInfo.ItemCode
	Where	
			Case 
				When IsNull(ExistingMaterialInfo.FamilyMaterialTypeName, '') <> '' 
				Then IsNull(ExistingMaterialInfo.FamilyMaterialTypeName, '') 
				Else Isnull(MaterialInfo.FamilyMaterialTypeName, '') 
			End In ('Cement', 'Mineral')
	Group By MixInfo.PlantCode, MixInfo.MixCode
	Having Sum(Round(IsNull(MixInfo.Quantity, 0.0), 2)) > 0
) As CementitiousInfo
On	CementitiousInfo.PlantCode = MixInfo.PlantCode And
	CementitiousInfo.MixCode = MixInfo.MixCode
Left Join
(
	Select -1 As ID, MixInfo.PlantCode, MixInfo.MixCode
	From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
	Left Join Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
	On	MixInfo.PlantCode = MaterialInfo.PlantName And
		MixInfo.MaterialItemCode = MaterialInfo.ItemCode
	Left Join #MaterialInfo As ExistingMaterialInfo
	On	MixInfo.PlantCode = ExistingMaterialInfo.PlantCode And
		MixInfo.MaterialItemCode = ExistingMaterialInfo.ItemCode
	Where	
			Case 
				When IsNull(ExistingMaterialInfo.FamilyMaterialTypeName, '') <> '' 
				Then IsNull(ExistingMaterialInfo.FamilyMaterialTypeName, '') 
				Else Isnull(MaterialInfo.FamilyMaterialTypeName, '') 
			End In ('Admixture & Fiber')
	Group By MixInfo.PlantCode, MixInfo.MixCode
) As AdmixtureInfo
On	AdmixtureInfo.PlantCode = MixInfo.PlantCode And
	AdmixtureInfo.MixCode = MixInfo.MixCode
Where	CementitiousInfo.ID Is Null And
		AdmixtureInfo.ID Is Not Null
Order By	MixInfo.PlantCode, 
			MixInfo.MixCode

If Object_id('TempDB..#MixIDList') Is Not null
Begin
	Drop table #MixIDList
End

If Object_id('TempDB..#MaterialInfo') Is Not null
Begin
	Drop table #MaterialInfo
End
