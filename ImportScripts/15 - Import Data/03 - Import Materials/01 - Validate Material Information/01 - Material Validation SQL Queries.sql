Declare @CheckForMaterialExistence Bit = 1

Select	MaterialInfo.PlantName As [Plant Name],
		MaterialInfo.FamilyMaterialTypeName As [Family Material Type],
		MaterialInfo.TradeName As [Trade Name],
		MaterialInfo.MaterialDate As [Material Date],
		MaterialInfo.SpecificGravity As [Specific Gravity],
		MaterialInfo.MaterialTypeName As [Material Type Name],
		MaterialInfo.Cost As [Cost],
		MaterialInfo.CostUnitName As [Cost Unit Name],
		Case
			When IsNull(MaterialInfo.PlantName, '') = ''
			Then 'The Plant Name is blank.'
			Else ''
		End As [Status Message],
		Case
			When IsNull(MaterialInfo.PlantName, '') <> '' And Plant.PLANTIDENTIFIER Is Null
			Then 'The Plant does not exist.'
			Else ''
		End As [Status Message],
		Case
			When Isnull(MaterialInfo.FamilyMaterialTypeName, '') = ''
			Then 'The Family Material Type Name is blank.'
			Else ''
		End As [Status Message],
		Case
			When	Isnull(MaterialInfo.FamilyMaterialTypeName, '') <> '' And 
					Isnull(FamilyMaterialType.MaterialTypeID, -1) Not In (1, 2, 3, 4, 5)
			Then 'The Family Material Type is incorrect.'
			Else ''
		End As [Status Message],
		Case
			When Isnull(MaterialInfo.MaterialTypeName, '') = ''
			Then 'The Material Type Name is blank.'
			Else ''
		End As [Status Message],
		Case
			When	Isnull(MaterialInfo.MaterialTypeName, '') <> '' And 
					Isnull(MaterialTypeInfo.MaterialTypeID, -1) = -1
			Then 'The Material Type does not exist.'
			Else ''
		End As [Status Message],
		Case
			When Isnull(FamilyMaterialType.MaterialTypeID, -1) <> IsNull(FamilyMaterialTypeInfo.Family_Static_MaterialTypeID, -1)
			Then 'The selected Material Type does not appear under the specified Family Material Type.'
			Else ''
		End As [Status Message],
		Case
			When Isnull(MaterialInfo.TradeName, '') = ''
			Then 'The Trade Name is blank.'
			Else ''
		End As [Status Message],
		Case
			When Isnull(MaterialInfo.MaterialDate, '') <> '' And Isdate(MaterialInfo.MaterialDate) = 0
			Then 'The Date is not a valid Date.'
			Else ''
		End As [Status Message],			
		Case
			When	Isnull(MaterialInfo.SpecificGravity, -1.0) < 0.4 Or
					Isnull(MaterialInfo.SpecificGravity, -1.0) >= 10.0 
			Then 'The Specific Gravity should be 0.4 up to 10.0.'
			Else ''
		End As [Status Message],
		Case
			When MaterialInfo.Cost Is Not null And Isnull(MaterialInfo.Cost, -1.0) < 0.0 
			Then 'The Cost must be 0.0 or greater.'
			Else ''
		End As [Status Message],
		Case
			When	Isnull(MaterialInfo.Cost, -1.0) >= 0.0 And
					Isnull(MaterialInfo.CostUnitName, '') Not In ('$/LB', 'Pounds', 'Fluid Oz', 'Gallons', 'Ounces', 'm3', '$/CY', 'CY', '$//YD^3', 'GA', '$/GL', 'GL', '$/gal', 'OZ', '$/oz', '$/TN', 'TN', '$/Ton', 'LB', '$/lb', 'TON', 'Tons', 'Ml-liter', 'ml', 'Liter', 'Liters', 'Litres', '$/liter', 'LT', 'L', 'LL', 'KG', '$/Kg', 'TM', 'MT', '$/Metric Ton', '$/MTon')
			Then 'The Cost Units must be $/gal, $/lb, or $/Ton.'
			Else ''
		End As [Status Message],
		Case
			When	IsNull(MaterialInfo.BatchingOrderNumber, '') <> '' And 
					dbo.Validation_ValueIsNumeric(MaterialInfo.BatchingOrderNumber) = 0
			Then 'The Batching Order Number must be a Number.'
			Else ''
		End As [Status Message],
		Case
			When	Material1.MATERIALIDENTIFIER Is Not null Or
					Material2.MATERIALIDENTIFIER Is Not null
			Then 'The Material already exists.'
			Else ''
		End As [Status Message]
From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
Left Join dbo.Plant As Plant
On	MaterialInfo.PlantName = Plant.PLNTNAME
Left Join dbo.PLANT As Yard
On Plant.PlantIDForYard = Yard.PLANTIDENTIFIER
Left Join dbo.MaterialType As FamilyMaterialType
On	MaterialInfo.FamilyMaterialTypeName = FamilyMaterialType.MaterialType And
	FamilyMaterialType.MaterialTypeID In (1, 2, 3, 4, 5)
Left Join dbo.MaterialType As MaterialTypeInfo
On MaterialInfo.MaterialTypeName = MaterialTypeInfo.MaterialType
Left Join dbo.GetFamilyMaterialTypeInformation() As FamilyMaterialTypeInfo
On MaterialTypeInfo.MaterialTypeID = FamilyMaterialTypeInfo.Static_MaterialTypeID
Left Join dbo.Name As TradeNameInfo
On MaterialInfo.TradeName = TradeNameInfo.Name
Left Join dbo.MATERIAL As Material1
On	Plant.PLANTIDENTIFIER = Material1.PlantID And
	FamilyMaterialType.MaterialTypeID = Material1.FamilyMaterialTypeID And
	TradeNameInfo.NameID = Material1.NameID
Left Join dbo.MATERIAL As Material2
On	Yard.PLANTIDENTIFIER = Material2.PlantID And
	FamilyMaterialType.MaterialTypeID = Material2.FamilyMaterialTypeID And
	TradeNameInfo.NameID = Material2.NameID
Where	Isnull(MaterialInfo.PlantName, '') = '' Or
		Plant.PLANTIDENTIFIER Is Null Or
		Isnull(FamilyMaterialType.MaterialTypeID, -1) Not In (1, 2, 3, 4, 5) Or
		Isnull(MaterialInfo.TradeName, '') = '' Or
		IsNull(MaterialInfo.MaterialDate, '') <> '' And Isdate(MaterialInfo.MaterialDate) = 0 Or
		Isnull(MaterialInfo.SpecificGravity, -1.0) < 0.4 Or
		Isnull(MaterialInfo.SpecificGravity, -1.0) >= 10.0 Or
		MaterialTypeInfo.MaterialTypeID Is Null Or
		Isnull(FamilyMaterialType.MaterialTypeID, -1) <> Isnull(FamilyMaterialTypeInfo.Family_Static_MaterialTypeID, -1) Or
		MaterialInfo.Cost Is Not null And Isnull(MaterialInfo.Cost, -1.0) < 0.0 Or
		Isnull(MaterialInfo.Cost, -1.0) >= 0.0 And 
		Isnull(MaterialInfo.CostUnitName, '') Not In ('$/LB', 'Pounds', 'Fluid Oz', 'Gallons', 'Ounces','m3', '$/CY', 'CY', '$//YD^3', 'GA', 'GL', '$/GL', '$/gal', 'OZ', '$/OZ', '$/TN', 'TN', '$/Ton', 'Tons', 'LB', '$/lb', 'TON', 'Ml-liter', 'ml', 'Liter', 'Liters', 'Litres', '$/Liter', 'LT', 'L', 'LL', 'KG', '$/Kg', 'TM', 'MT', '$/Metric Ton', '$/MTon', 'Pounds', 'Fluid Oz', 'Gallons') Or
		IsNull(MaterialInfo.BatchingOrderNumber, '') <> '' And dbo.Validation_ValueIsNumeric(MaterialInfo.BatchingOrderNumber) = 0 Or
		@CheckForMaterialExistence = 1 And Material1.MATERIALIDENTIFIER Is Not null Or
		@CheckForMaterialExistence = 1 And Material2.MATERIALIDENTIFIER Is Not Null 

Select	MaterialInfo1.FamilyMaterialTypeName As [Family Material Type],
		MaterialInfo1.PlantName As [Plant Name],
		MaterialInfo1.TradeName As [Trade Name],
		'This Material is listed more than once in the Spreadsheet.' As [Status Message]
From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo1
Left Join Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo2
On	MaterialInfo2.PlantName = MaterialInfo1.PlantName And
	MaterialInfo2.FamilyMaterialTypeName = MaterialInfo1.FamilyMaterialTypeName And
	MaterialInfo2.TradeName = MaterialInfo1.TradeName And
	MaterialInfo1.AutoID <> MaterialInfo2.AutoID
Where MaterialInfo2.AutoID Is Not null 
Group By	MaterialInfo1.PlantName, 
			MaterialInfo1.FamilyMaterialTypeName,
			MaterialInfo1.TradeName
Order By	MaterialInfo1.FamilyMaterialTypeName,
			MaterialInfo1.PlantName,
			MaterialInfo1.TradeName
			
Select	MaterialInfo.PlantName As [Plant Name], 
		MaterialInfo.ItemCode As [Item Code], 
		'This Material Item Code is linked to multiple Trade Names.' As [Status Message]
From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
Where Isnull(MaterialInfo.ItemCode, '') <> ''
Group By MaterialInfo.PlantName, MaterialInfo.ItemCode
Having Count(Distinct MaterialInfo.TradeName) > 1
Order By MaterialInfo.PlantName, MaterialInfo.ItemCode

Select	MaterialInfo.PlantName As [Plant Name], 
		MaterialInfo.TradeName As [Trade Name], 
		'This Material Trade Name is linked to multiple Item Codes.' As [Status Message]
From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
Where Isnull(MaterialInfo.TradeName, '') <> ''
Group By MaterialInfo.PlantName, MaterialInfo.TradeName
Having Count(Distinct MaterialInfo.ItemCode) > 1
Order By MaterialInfo.PlantName, MaterialInfo.TradeName

Select	MaterialInfo.PlantName As [Plant Name],
      	MaterialInfo.TradeName As [Trade Name], 
      	MaterialInfo.FamilyMaterialTypeName As [Family Material Type], 
      	MaterialInfo.MaterialDate As [Material Date],
      	MaterialInfo.ItemCode As [Item Code],
      	'The Item Code is currently a Mix Item Code.' As [Status Message]
From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
Inner Join dbo.Name As ItemCodeInfo
On MaterialInfo.ItemCode = ItemCodeInfo.Name
Where ItemCodeInfo.NameType In ('Mix', 'MixItem')
Order By MaterialInfo.PlantName, MaterialInfo.TradeName, MaterialInfo.ItemCode

Select	MaterialInfo.PlantName As [Plant Name],
      	MaterialInfo.TradeName As [Trade Name],
      	MaterialInfo.FamilyMaterialTypeName As [Family Material Type],
      	MaterialInfo.MaterialDate As [Material Date],
      	MaterialInfo.ItemCode As [Item Code],
      	'The Trade Name is currently a Mix Item Code.' As [Status Message]
From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
Inner Join dbo.Name As TradeNameInfo
On MaterialInfo.TradeName = TradeNameInfo.Name
Where TradeNameInfo.NameType In ('Mix', 'MixItem')
Order By MaterialInfo.PlantName, MaterialInfo.TradeName, MaterialInfo.ItemCode

Select	MaterialInfo.PlantName As [Plant Name],
      	MaterialInfo.TradeName As [Trade Name], 
      	MaterialInfo.FamilyMaterialTypeName As [Family Material Type], 
      	MaterialInfo.MaterialTypeName As [Material Type],
      	'This Material Type is hidden.' As [Status Message]
From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
Inner Join dbo.MaterialType As MaterialTypeInfo
On MaterialInfo.MaterialTypeName = MaterialTypeInfo.MaterialType
Inner Join dbo.Static_Standard As Standard
On Standard.Static_StandardID = MaterialTypeInfo.StandardLink
Inner Join dbo.StandardInfo As StandardInfo
On StandardInfo.StandardID = Standard.Static_StandardID
Where Isnull(StandardInfo.IsActive, 0) = 0
Order By MaterialInfo.PlantName, MaterialInfo.TradeName

Select	MaterialInfo.PlantName As [Plant Name],
		MaterialInfo.TradeName As [Trade Name],
		'The Trade Name has more than 70 characters.' As [Status Message]
From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
Where Len(MaterialInfo.TradeName) > 70
Order By MaterialInfo.PlantName, MaterialInfo.TradeName

Select	MaterialInfo.PlantName As [Plant Name],
		MaterialInfo.TradeName As [Trade Name],
		MaterialInfo.ManufacturerSourceName As [Manufacturer Source Name],
		'The Manufacturer Source Name has more than 50 characters.' As [Status Message]
From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
Where Len(MaterialInfo.ManufacturerSourceName) > 50
Order By MaterialInfo.PlantName, MaterialInfo.TradeName
