If Exists (Select * From Sys.databases Where Name = 'Data_Import_RJ')
Begin
    If Exists (Select * From Data_Import_RJ.sys.objects Where Name = 'TestImport0000_MixInfo')
    Begin
    	Update MixInfo
    	    Set MixInfo.DispatchSlumpRange = 
    	            Cast(Round(MixInfo.Slump, 0) As Nvarchar) + '+-' +
    	            Cast(Round(MixInfo.Slump - MixInfo.MinSlump, 0) As Nvarchar)
    	From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
    	Where   Isnull(MixInfo.DispatchSlumpRange, '') = '' And
    	        Isnull(MixInfo.Slump, -1.0) >= 0.1 And
    	        Isnull(MixInfo.MinSlump, -1.0) >= 0.1 And
    	        Isnull(MixInfo.Slump, -1.0) >= Isnull(MixInfo.MinSlump, -1.0)

    	Update MixInfo
    	    Set MixInfo.DispatchSlumpRange = 
    	            Cast(Round(MixInfo.Slump, 0) As Nvarchar) + '+-' +
    	            Cast(Round(MixInfo.MaxSlump - MixInfo.Slump, 0) As Nvarchar)
    	From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
    	Where   Isnull(MixInfo.DispatchSlumpRange, '') = '' And
    	        Isnull(MixInfo.Slump, -1.0) >= 0.1 And
    	        Isnull(MixInfo.MaxSlump, -1.0) >= 0.1 And
    	        Isnull(MixInfo.Slump, -1.0) <= Isnull(MixInfo.MaxSlump, -1.0)
    End
End
Go
