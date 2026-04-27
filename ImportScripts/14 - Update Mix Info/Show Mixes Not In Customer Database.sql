Declare @PlantInfo Table (PlantName Nvarchar (100))

Insert into @PlantInfo (PlantName)
Select dbo.GetTrimmedValue(PlantInfo.PlantName) As PlantName
From
(
	Select '409' As PlantName
	Union All
	Select '420' As PlantName
	Union All
	Select '453' As PlantName
	Union All
	Select '455' As PlantName
	Union All
	Select '' As PlantName
	Union All
	Select '' As PlantName
) As PlantInfo
Where dbo.GetTrimmedValue(PlantInfo.PlantName) <> ''
Group By dbo.GetTrimmedValue(PlantInfo.PlantName)
Order By dbo.GetTrimmedValue(PlantInfo.PlantName)

If Exists (Select * From @PlantInfo)
Begin
    Select  Isnull(MixInfo.PlantCode, '') As PlantCode,
            Isnull(MixInfo.MixCode, '') As MixCode,
            Isnull(MixInfo.MixDescription, '') As MixDescription,
            Isnull(MixInfo.MixShortDescription, '') As MixShortDescription,
            Isnull(MixInfo.ItemCategory, '') As ItemCategory,
            Isnull(Cast(Cast(MixInfo.StrengthAge As Numeric (15, 2)) As Nvarchar), '') As StrengthAge,
            Isnull(Cast(Cast(MixInfo.Strength As Numeric (15, 0)) As Nvarchar), '') As Strength,
            Isnull(Cast(Cast(MixInfo.AirContent As Numeric (15, 2)) As Nvarchar), '') As AirContent,
            Isnull(Cast(Cast(MixInfo.MinAirContent As Numeric (15, 2)) As Nvarchar), '') As MinAirContent,
            Isnull(Cast(Cast(MixInfo.MaxAirContent As Numeric (15, 2)) As Nvarchar), '') As MaxAirContent,
            Isnull(Cast(Cast(MixInfo.Slump As Numeric (15, 2)) As Nvarchar), '') As Slump,
            Isnull(Cast(Cast(MixInfo.MinSlump As Numeric (15, 2)) As Nvarchar), '') As MinSlump,
            Isnull(Cast(Cast(MixInfo.MaxSlump As Numeric (15, 2)) As Nvarchar), '') As MaxSlump,
            Isnull(Cast(Cast(MixInfo.MaxLoadSize As Numeric (15, 2)) As Nvarchar), '') As MaxLoadSize,
            Isnull(Cast(Cast(MixInfo.MaximumWater As Numeric (15, 2)) As Nvarchar), '') As MaxWater,
            Isnull(Cast(Cast(MixInfo.MaxWCMRatio As Numeric (15, 2)) As Nvarchar), '') As MaxWCMRatio,
            Isnull(Cast(Cast(MixInfo.MaxWCRatio As Numeric (15, 2)) As Nvarchar), '') As MaxWCRatio,
            Isnull(MixInfo.MixClassNames, '') As MixClassNames,
            Isnull(MixInfo.MixUsage, '') As MixUsage,
            Isnull(MixInfo.Padding1, '') As Padding,
            Isnull(MixInfo.MaterialItemCode, '') As MaterialItemCode,
            Isnull(MixInfo.MaterialItemDescription, '') As MaterialItemDescription,
            Isnull(Cast(Cast(MixInfo.Quantity As Numeric (15, 2)) As Nvarchar), '') As Quantity,
            Isnull(MixInfo.QuantityUnitName, '') As QuantityUnitName
        From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
        Inner Join @PlantInfo As PlantInfo
        On MixInfo.PlantCode = PlantInfo.PlantName
        Left Join
        (
    	    Select -1 As ID, Plant.Name As PlantCode, MixName.Name As MixCode
    	    From dbo.Plants As Plant
    	    Inner Join dbo.BATCH As Mix
    	    On Mix.Plant_Link = Plant.PlantId
    	    Inner Join dbo.Name As MixName
    	    On MixName.NameID = Mix.NameID
    	    Group By Plant.Name, MixName.Name
        ) As ExistingMixes
        On MixInfo.PlantCode = ExistingMixes.PlantCode And MixInfo.MixCode = ExistingMixes.MixCode
        Where ExistingMixes.ID Is Null
        Order By
                MixInfo.PlantCode,
                MixInfo.MixCode,
                MixInfo.MaterialItemCode
End                
Else
Begin
    Select  Isnull(MixInfo.PlantCode, '') As PlantCode,
            Isnull(MixInfo.MixCode, '') As MixCode,
            Isnull(MixInfo.MixDescription, '') As MixDescription,
            Isnull(MixInfo.MixShortDescription, '') As MixShortDescription,
            Isnull(MixInfo.ItemCategory, '') As ItemCategory,
            Isnull(Cast(Cast(MixInfo.StrengthAge As Numeric (15, 2)) As Nvarchar), '') As StrengthAge,
            Isnull(Cast(Cast(MixInfo.Strength As Numeric (15, 0)) As Nvarchar), '') As Strength,
            Isnull(Cast(Cast(MixInfo.AirContent As Numeric (15, 2)) As Nvarchar), '') As AirContent,
            Isnull(Cast(Cast(MixInfo.MinAirContent As Numeric (15, 2)) As Nvarchar), '') As MinAirContent,
            Isnull(Cast(Cast(MixInfo.MaxAirContent As Numeric (15, 2)) As Nvarchar), '') As MaxAirContent,
            Isnull(Cast(Cast(MixInfo.Slump As Numeric (15, 2)) As Nvarchar), '') As Slump,
            Isnull(Cast(Cast(MixInfo.MinSlump As Numeric (15, 2)) As Nvarchar), '') As MinSlump,
            Isnull(Cast(Cast(MixInfo.MaxSlump As Numeric (15, 2)) As Nvarchar), '') As MaxSlump,
            Isnull(Cast(Cast(MixInfo.MaxLoadSize As Numeric (15, 2)) As Nvarchar), '') As MaxLoadSize,
            Isnull(Cast(Cast(MixInfo.MaximumWater As Numeric (15, 2)) As Nvarchar), '') As MaxWater,
            Isnull(Cast(Cast(MixInfo.MaxWCMRatio As Numeric (15, 2)) As Nvarchar), '') As MaxWCMRatio,
            Isnull(Cast(Cast(MixInfo.MaxWCRatio As Numeric (15, 2)) As Nvarchar), '') As MaxWCRatio,
            Isnull(MixInfo.MixClassNames, '') As MixClassNames,
            Isnull(MixInfo.MixUsage, '') As MixUsage,
            Isnull(MixInfo.Padding1, '') As Padding,
            Isnull(MixInfo.MaterialItemCode, '') As MaterialItemCode,
            Isnull(MixInfo.MaterialItemDescription, '') As MaterialItemDescription,
            Isnull(Cast(Cast(MixInfo.Quantity As Numeric (15, 2)) As Nvarchar), '') As Quantity,
            Isnull(MixInfo.QuantityUnitName, '') As QuantityUnitName
        From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
        Left Join
        (
    	    Select -1 As ID, Plant.Name As PlantCode, MixName.Name As MixCode
    	    From dbo.Plants As Plant
    	    Inner Join dbo.BATCH As Mix
    	    On Mix.Plant_Link = Plant.PlantId
    	    Inner Join dbo.Name As MixName
    	    On MixName.NameID = Mix.NameID
    	    Group By Plant.Name, MixName.Name
        ) As ExistingMixes
        On MixInfo.PlantCode = ExistingMixes.PlantCode And MixInfo.MixCode = ExistingMixes.MixCode
        Where ExistingMixes.ID Is Null
        Order By
                MixInfo.PlantCode,
                MixInfo.MixCode,
                MixInfo.MaterialItemCode    
End	