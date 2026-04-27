If ObjectProperty(Object_ID(N'[dbo].[ACIBatchViewDetails]'), N'IsUserTable') = 1
Begin
	If Db_name() In ('EK_Pennys_Concrete', 'Pennys_Concrete', '', '')
	Begin
		Declare @MixInfo Table 
		(
			MixID Int, 
			MixSpecID Int, 
			PlantName Nvarchar (100),
			MixName Nvarchar (100),
			Strength Float, 
			MinSlump Float, 
			MaxSlump Float, 
			MinAirContent Float, 
			MaxAirContent Float,
			MixStrength Float, 
			MixMinSlump Float, 
			MixMaxSlump Float, 
			MixMinAirContent Float, 
			MixMaxAirContent Float
		)
		Declare @NewLine Nvarchar (10)
	
		Declare @ErrorNumber Int
		Declare @ErrorMessage Nvarchar (Max)
		Declare @ErrorSeverity Int
		Declare @ErrorState Int
		
		Set @NewLine = dbo.GetNewLine()
	
		--Set Statistics Time On
		
		Begin Try
			Begin Transaction

			Raiserror('', 0, 0) With NoWait
			Raiserror('Update the Mix Report Strengths, Specified Slump Ranges, and Specified Air Content Ranges.', 0, 0) With NoWait

			Raiserror('', 0, 0) With NoWait
			Raiserror('Retrieve Mixes.', 0, 0) With NoWait

            Insert into @MixInfo 
            (
            	MixID, 
            	MixSpecID, 
            	PlantName, 
            	MixName, 
            	Strength, 
            	MinSlump, 
            	MaxSlump, 
            	MinAirContent, 
            	MaxAirContent,
            	MixStrength, 
            	MixMinSlump, 
            	MixMaxSlump, 
            	MixMinAirContent, 
            	MixMaxAirContent
            )
            Select  Mix.BATCHIDENTIFIER, 
                    Mix.MixSpecID,
                    Plants.Name,
                    MixName.Name,
                    Case 
                        When StrengthSpec.StrengthMinValue Is Null Or StrengthSpec.MixSpecID Is Null Or Isnull(StrengthSpec.StrengthUnitID, -1) Not In (5, 6)
                        Then Null
                        When StrengthSpec.StrengthUnitID In (6) -- psi
                        Then StrengthSpec.StrengthMinValue * 0.006894757
                        Else StrengthSpec.StrengthMinValue
                    End,
                    Case 
                        When SlumpSpec.MinSlump Is Null Or SlumpSpec.MixSpecID Is Null Or Isnull(SlumpSpec.SlumpUnitsID, -1) Not In (8, 9)
                        Then Null
                        When SlumpSpec.SlumpUnitsID In (9) -- inches
                        Then SlumpSpec.MinSlump * 25.4
                        Else SlumpSpec.MinSlump
                    End,
                    Case 
                        When SlumpSpec.MaxSlump Is Null Or SlumpSpec.MixSpecID Is Null Or Isnull(SlumpSpec.SlumpUnitsID, -1) Not In (8, 9)
                        Then Null
                        When SlumpSpec.SlumpUnitsID In (9) -- inches
                        Then SlumpSpec.MaxSlump * 25.4
                        Else SlumpSpec.MaxSlump
                    End,
                    AirSpec.MinAirContent,
                    AirSpec.MaxAirContent,
                    StrengthSpec.StrengthMinValue,
                    SlumpSpec.MinSlump, 
                    SlumpSpec.MaxSlump,
                    AirSpec.MinAirContent, 
                    AirSpec.MaxAirContent
            From dbo.Batch As Mix
            Inner Join dbo.Plants As Plants
            On Plants.PlantId = Mix.Plant_Link
            Inner Join dbo.Name As MixName
            On MixName.NameID = Mix.NameID
            Left Join dbo.RptMixSpec28DayComprStrengths As StrengthSpec
            On StrengthSpec.MixSpecID = Mix.MixSpecID
            Left Join dbo.RptMixSpecAirContent As AirSpec
            On AirSpec.MixSpecID = Mix.MixSpecID
            Left Join dbo.RptMixSpecSlump As SlumpSpec
            On SlumpSpec.MixSpecID = Mix.MixSpecID
            Where   Mix.NameID Is Not null And
                    (
                    	StrengthSpec.MixSpecID Is Not null Or
                    	SlumpSpec.MixSpecID Is Not null Or
                    	AirSpec.MixSpecID Is Not Null
                    )
            Order By Plants.Name, MixName.Name

			Raiserror('', 0, 0) With NoWait
			Raiserror('Show updated Mix Report Strengths, Slump Ranges, and Air Content Ranges.', 0, 0) With NoWait

            Select  MixInfo.*,
                    MixInfo.Strength / 0.006894757 As NewStrength,
                    MixInfo.MinSlump / 25.4 As NewMinSlump,
                    MixInfo.MaxSlump / 25.4 As NewMaxSlump, 
                    Mix.FPC, 
                    Mix.SPECAIR, 
                    Mix.SPECSLUMP,
                    Case
                        When Isnull(MixInfo.Strength, -1.0) <= 0.0
                        Then Null
                        Else Ltrim(Rtrim(Cast(Cast(MixInfo.Strength As Decimal (30, 15)) As Nvarchar))) 
                    End As ReportStrength,
                    Case
                        When Isnull(MixInfo.MinAirContent, -1.0) < 0.0 And Isnull(MixInfo.MaxAirContent, -1.0) < 0.0
                        Then Null
                        When Isnull(MixInfo.MaxAirContent, -1.0) < 0.0
                        Then Ltrim(Rtrim(Cast(Cast(MixInfo.MinAirContent As Decimal(15, 2)) As Nvarchar))) 
                        When Isnull(MixInfo.MinAirContent, -1.0) < 0.0
                        Then Ltrim(Rtrim(Cast(Cast(MixInfo.MaxAirContent As Decimal(15, 2)) As Nvarchar))) 
                        Else    Ltrim(Rtrim(Cast(Cast(MixInfo.MinAirContent As Decimal (15, 2)) As Nvarchar))) + 
                                ' To ' + 
                                Ltrim(Rtrim(Cast(Cast(MixInfo.MaxAirContent As Decimal (15, 2)) As Nvarchar)))
                    End As AirContentRange,
                    Case
                        When Isnull(MixInfo.MinSlump, -1.0) < 0.0 And Isnull(MixInfo.MaxSlump, -1.0) < 0.0
                        Then Null
                        When Isnull(MixInfo.MaxSlump, -1.0) < 0.0
                        Then Ltrim(Rtrim(Cast(Cast(MixInfo.MinSlump As Decimal(15, 2)) As Nvarchar))) 
                        When Isnull(MixInfo.MinSlump, -1.0) < 0.0
                        Then Ltrim(Rtrim(Cast(Cast(MixInfo.MaxSlump As Decimal(15, 2)) As Nvarchar))) 
                        Else    Ltrim(Rtrim(Cast(Cast(MixInfo.MinSlump As Decimal (15, 2)) As Nvarchar))) + 
                                ' To ' + 
                                Ltrim(Rtrim(Cast(Cast(MixInfo.MaxSlump As Decimal (15, 2)) As Nvarchar)))
                    End As SlumpRange
            From dbo.BATCH As Mix
            Inner Join @MixInfo As MixInfo
            On Mix.BATCHIDENTIFIER = MixInfo.MixID
            Order By MixInfo.PlantName, MixInfo.MixName
                    
			Raiserror('', 0, 0) With NoWait
			Raiserror('Update Mix Report Strengths, Air Content Ranges, and Slump Ranges.', 0, 0) With NoWait

            Update Mix
                Set Mix.FPC =
                        Case
                            When Isnull(MixInfo.Strength, -1.0) <= 0.0
                            Then Null
                            Else Ltrim(Rtrim(Cast(Cast(MixInfo.Strength As Decimal (30,15)) As Nvarchar))) 
                        End,
                    Mix.SPECAIR =
                        Case
                            When Isnull(MixInfo.MinAirContent, -1.0) < 0.0 And Isnull(MixInfo.MaxAirContent, -1.0) < 0.0
                            Then Null
                            When Isnull(MixInfo.MaxAirContent, -1.0) < 0.0
                            Then Ltrim(Rtrim(Cast(Cast(MixInfo.MinAirContent As Decimal(15, 2)) As Nvarchar))) 
                            When Isnull(MixInfo.MinAirContent, -1.0) < 0.0
                            Then Ltrim(Rtrim(Cast(Cast(MixInfo.MaxAirContent As Decimal(15, 2)) As Nvarchar))) 
                            Else    Ltrim(Rtrim(Cast(Cast(MixInfo.MinAirContent As Decimal (15, 2)) As Nvarchar))) + 
                                    ' To ' + 
                                    Ltrim(Rtrim(Cast(Cast(MixInfo.MaxAirContent As Decimal (15, 2)) As Nvarchar)))
                        End,
                    Mix.SPECSLUMP = 
                        Case
                            When Isnull(MixInfo.MinSlump, -1.0) < 0.0 And Isnull(MixInfo.MaxSlump, -1.0) < 0.0
                            Then Null
                            When Isnull(MixInfo.MaxSlump, -1.0) < 0.0
                            Then Ltrim(Rtrim(Cast(Cast(MixInfo.MinSlump As Decimal(15, 2)) As Nvarchar))) 
                            When Isnull(MixInfo.MinSlump, -1.0) < 0.0
                            Then Ltrim(Rtrim(Cast(Cast(MixInfo.MaxSlump As Decimal(15, 2)) As Nvarchar))) 
                            Else    Ltrim(Rtrim(Cast(Cast(MixInfo.MinSlump As Decimal (15, 2)) As Nvarchar))) + 
                                    ' To ' + 
                                    Ltrim(Rtrim(Cast(Cast(MixInfo.MaxSlump As Decimal (15, 2)) As Nvarchar)))
                        End
            From dbo.BATCH As Mix
            Inner Join @MixInfo As MixInfo
            On Mix.BATCHIDENTIFIER = MixInfo.MixID
			
			Raiserror('', 0, 0) With Nowait
			--Raiserror('Test Error To Stop Transaction.', 18, 1) With Nowait
			
			Commit Transaction
				
			Raiserror('', 0, 0) With NoWait 
			Raiserror('The Mix Report Strengths, Specified Slump Ranges, and Specified Air Content Ranges may have been updated.', 0, 0) With NoWait 
		End Try
		Begin Catch
			If @@TRANCOUNT > 0
			Begin
				Rollback Transaction

			    Raiserror('', 0, 0) With NoWait 
			    Raiserror('The Transaction was rolled back.', 0, 0) With NoWait
			End
	    
			Select  @ErrorNumber  = Error_number(),
					@ErrorSeverity = Error_severity(),
					@ErrorState = Error_state(),
					@ErrorMessage  = Error_message()

			Set @ErrorMessage = --@NewLine +
				'   Error Number: ' + Cast(Isnull(@ErrorNumber, -1) As Nvarchar) + '.  ' + @NewLine +
				'   Error Severity: ' + Cast(Isnull(@ErrorSeverity, -1) As Nvarchar) + '.  ' + @NewLine +
				'   Error State: ' + Cast(Isnull(@ErrorState, -1) As Nvarchar) + '.  ' + @NewLine +
				'   Error Message: ' + Isnull(@ErrorMessage, '') + @NewLine
	    
			Raiserror('', 0, 0) With NoWait 
			Raiserror('The Mix Report Strengths, Specified Slump Ranges, and Specified Air Content Ranges could not be updated.  Transaction Rolled Back.', 0, 0) With NoWait
			Print @ErrorMessage

		End Catch

		--Set Statistics Time Off
	End
End
Go
