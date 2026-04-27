If Exists (Select * From Sys.databases Where Name = 'Data_Import_RJ')
Begin
    If Exists (Select * From Data_Import_RJ.sys.objects Where Name = 'TestImport0000_MixInfo')
    Begin
    	Declare @MixInfo Table (CurAutoID Int, MinAutoID Int, MixCode Nvarchar (100))
    	
    	Insert into @MixInfo (CurAutoID, MinAutoID, MixCode)
    	Select MixInfo.AutoID, Null, MixInfo.MixCode
    	From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
    	Order By MixInfo.AutoID
    	
    	Update MixInfo
    	    Set MixInfo.MinAutoID = 
    	            (
    	                Select Max(MixInfo2.AutoID)
    	                From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo2
    	                Where   Isnull(MixInfo2.MixCode, '') <> '' And
    	                        MixInfo.CurAutoID > MixInfo2.AutoID	
    	            )
    	From @MixInfo As MixInfo
    	Where Isnull(MixInfo.MixCode, '') = ''
    	
    	Select *
    	From @MixInfo As MixInfo
    	Order By MixInfo.CurAutoID
    	
    	Update MixData1
    	    Set MixData1.PlantCode = MixData2.PlantCode,
                MixData1.MixCode = MixData2.MixCode,
                MixData1.MixDescription = MixData2.MixDescription,
                MixData1.MixShortDescription = MixData2.MixShortDescription,
                MixData1.ItemCategory = MixData2.ItemCategory,
                MixData1.StrengthAge = MixData2.StrengthAge,
                MixData1.Strength = MixData2.Strength,
                MixData1.AirContent = MixData2.AirContent,
                MixData1.MinAirContent = MixData2.MinAirContent,
                MixData1.MaxAirContent = MixData2.MaxAirContent,
                MixData1.Slump = MixData2.Slump,
                MixData1.MinSlump = MixData2.MinSlump,
                MixData1.MaxSlump = MixData2.MaxSlump,
                MixData1.DispatchSlumpRange = MixData2.DispatchSlumpRange,
                MixData1.AggregateSize = MixData2.AggregateSize,
                MixData1.MinAggregateSize = MixData2.MinAggregateSize,
                MixData1.MaxAggregateSize = MixData2.MaxAggregateSize,
                MixData1.UnitWeight = MixData2.UnitWeight,
                MixData1.MinUnitWeight = MixData2.MinUnitWeight,
                MixData1.MaxUnitWeight = MixData2.MaxUnitWeight,
                MixData1.MaxLoadSize = MixData2.MaxLoadSize,
                MixData1.MaximumWater = MixData2.MaximumWater,
                MixData1.SackContent = MixData2.SackContent,
                MixData1.Price = MixData2.Price,
                MixData1.PriceUnitName = MixData2.PriceUnitName,
                MixData1.MixInactive = MixData2.MixInactive,
                MixData1.MinWCRatio = MixData2.MinWCRatio,
                MixData1.MaxWCRatio = MixData2.MaxWCRatio,
                MixData1.MinWCMRatio = MixData2.MinWCMRatio,
                MixData1.MaxWCMRatio = MixData2.MaxWCMRatio,
                MixData1.MixClassNames = MixData2.MixClassNames,
                MixData1.MixUsage = MixData2.MixUsage,
                MixData1.AttachmentFileNames = MixData2.AttachmentFileNames
    	From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixData1
    	Inner Join @MixInfo As MixInfo
    	On  MixData1.AutoID = MixInfo.CurAutoID And
    	    Isnull(MixInfo.MixCode, '') = ''
    	Inner Join Data_Import_RJ.dbo.TestImport0000_MixInfo As MixData2
    	On MixInfo.MinAutoID = MixData2.AutoID
    	
    	Select *
    	From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
    	Order By MixInfo.AutoID
    End
End
Go
