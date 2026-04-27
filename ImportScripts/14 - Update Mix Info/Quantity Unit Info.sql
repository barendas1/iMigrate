Select Distinct MixInfo.QuantityUnitName
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo

Select  MixInfo.PlantCode As [Plant Name], 
        MixInfo.MixCode As [Mix Name], 
        MixInfo.MaterialItemCode As [Material Item Code],
        Isnull(MixInfo.MaterialItemDescription, '') As [Material Item Description],
        MixInfo.Quantity As [Quantity], 
        MixInfo.QuantityUnitName As [Quantity Unit Name],
        'Units of Each may have been imported as Units of Lbs.' As [Status Message]
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Where MixInfo.QuantityUnitName In ('EA')
Order By MixInfo.PlantCode, MixInfo.MixCode, MixInfo.MaterialItemCode,
      MixInfo.Quantity, MixInfo.QuantityUnitName
      