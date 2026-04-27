If Exists (Select * From Sys.databases Where Name = 'Data_Import_RJ')
Begin
    If Exists (Select * From Data_Import_RJ.sys.objects Where Name = 'TestImport0000_MixInfo')
    Begin
    	Declare @UpdateMixAirContentRanges Bit = 1
    	Declare @UpdateMixSlumpRanges Bit = 1
    	Declare @UnitSys Nvarchar (10) = 'US'
    	Declare @AirContentModifier Float = 1.5
    	Declare @SlumpModifier Float = Case when @UnitSys = 'US' Then 2.0 Else 30.0 End
    	Declare @MaxSlump Float = Case when @UnitSys = 'US' Then 12.0 Else 305 End

    	
		Update MixInfo
		    Set MixInfo.AirContent = 
		            Case 
		                When Isnull(MixInfo.AirContent, -1.0) < 0.0 Or Isnull(MixInfo.AirContent, -1.0) > 90.0 
		                Then Null 
		                Else MixInfo.AirContent 
		            End,
		        MixInfo.MinAirContent =
		            Case 
		                When Isnull(MixInfo.MinAirContent, -1.0) < 0.0 Or Isnull(MixInfo.MinAirContent, -1.0) > 100.0 
		                Then Null 
		                Else MixInfo.MinAirContent
		            End,
		        MixInfo.MaxAirContent =
		            Case 
		                When Isnull(MixInfo.MaxAirContent, -1.0) < 0.0 Or Isnull(MixInfo.MaxAirContent, -1.0) > 100.0 
		                Then Null 
		                Else MixInfo.MaxAirContent
		            End,
		        MixInfo.Slump = 
		            Case 
		                When Isnull(MixInfo.Slump, -1.0) < 0.0  
		                Then Null 
		                Else MixInfo.Slump 
		            End,
		        MixInfo.MinSlump =
		            Case 
		                When Isnull(MixInfo.MinSlump, -1.0) < 0.0  
		                Then Null 
		                Else MixInfo.MinSlump
		            End,
		        MixInfo.MaxSlump =
		            Case 
		                When Isnull(MixInfo.MaxSlump, -1.0) < 0.0  
		                Then Null 
		                Else MixInfo.MaxSlump
		            End
		From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo

		Update MixInfo
		    Set MixInfo.MinSlump = Null,
		        MixInfo.MaxSlump = Null
		From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
		Where Isnull(MixInfo.MinSlump, -1.0) = 0.0 And Isnull(MixInfo.MaxSlump, -1.0) = 0.0

        Update MixInfo
		    Set MixInfo.MinAirContent = Null,
		        MixInfo.MaxAirContent = Null
		From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
		Where Isnull(MixInfo.MinAirContent, -1.0) = 0.0 And Isnull(MixInfo.MaxAirContent, -1.0) = 0.0

        If Isnull(@UpdateMixAirContentRanges, 0) = 1
        Begin
        	Raiserror('Update Mix Air Content Ranges', 0, 0) With Nowait
        	
		    Update MixInfo
		        Set MixInfo.MinAirContent =
		                Case 
		                    When MixInfo.AirContent - @AirContentModifier <= 0.01 
		                    Then 0.0
		                    Else MixInfo.AirContent - @AirContentModifier
		                End,
		            MixInfo.MaxAirContent =
		                Case 
		                    When MixInfo.AirContent + @AirContentModifier >= 99.9 
		                    Then 100.0
		                    Else MixInfo.AirContent + @AirContentModifier
		                End
		    From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
		    Where   Isnull(MixInfo.AirContent, -1.0) >= 0.0 And
		            Isnull(MixInfo.MinAirContent, -1.0) < 0.0 And
		            Isnull(MixInfo.MaxAirContent, -1.0) < 0.0 
        End
        
        If IsNull(@UpdateMixSlumpRanges, 0) = 1
        Begin
        	Raiserror('Update Mix Slump Ranges', 0, 0) With Nowait
        	
		    Update MixInfo
		        Set MixInfo.MinSlump =
		                Case 
		                    When MixInfo.Slump - @SlumpModifier <= 0.01 
		                    Then 0.0
		                    Else MixInfo.Slump - @SlumpModifier
		                End,
		            MixInfo.MaxSlump =
		                Case 
		                    When MixInfo.Slump + @SlumpModifier >= @MaxSlump - 0.1 And MixInfo.Slump <= @MaxSlump 
		                    Then @MaxSlump
		                    Else MixInfo.Slump + @SlumpModifier
		                End
		    From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
		    Where   Isnull(MixInfo.Slump, -1.0) >= 0.0 And
		            Isnull(MixInfo.MinSlump, -1.0) < 0.0 And
		            Isnull(MixInfo.MaxSlump, -1.0) < 0.0 
        End
    End
End
Go
