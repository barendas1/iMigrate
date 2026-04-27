Update MixInfo
    Set MixDescription = Null,
        MixShortDescription = Null,
        ItemCategory = Null,
        BatchPanelCode = Null,
        StrengthAge = Null,
        Strength = Null,
        AirContent = Null,
        MinAirContent = Null,
        MaxAirContent = Null,
        Slump = Null,
        MinSlump = Null,
        MaxSlump = Null,
        DispatchSlumpRange = Null,
        AggregateSize = Null,
        MinAggregateSize = Null,
        MaxAggregateSize = Null,
        UnitWeight = Null,
        MinUnitWeight = Null,
        MaxUnitWeight = Null,
        MaxLoadSize = Null,
        MaximumWater = Null,
        SackContent = Null,
        Price = Null,
        PriceUnitName = Null,
        MinWCRatio = Null,
        MaxWCRatio = Null,
        MinWCMRatio = Null,
        MaxWCMRatio = Null,
        MixClassNames = Null,
        MixClassDescription = Null,
        MixUsage = Null,
        AttachmentFileNames = Null,
        DosageQuantity = Null,
        SortNumber = Null
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Inner Join dbo.Plants As Plant
On MixInfo.PlantCode = Plant.Name
Inner Join dbo.Name As MixName
On MixInfo.MixCode = MixName.Name
Inner Join dbo.BATCH As Mix
On  Mix.Plant_Link = Plant.PlantId And 
    Mix.NameID = MixName.NameID
    