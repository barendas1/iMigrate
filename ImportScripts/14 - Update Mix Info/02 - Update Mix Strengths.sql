If  Exists (Select * From Sys.databases Where Name = 'Data_Import_RJ') 
Begin
    If Exists (Select * From Data_Import_RJ.sys.objects Where Name = 'TestImport0000_MixInfo')
    Begin
    	Declare @UnitSys Nvarchar (30) = 'US'
    	Declare @ClearLowStrengthsForUS Bit = 0
    	
    	If @UnitSys = 'US'
    	Begin
    		Declare @StrengthInfo Table (AutoID Int Identity (1, 1), Strength Nvarchar (10))
    		Declare @Index Int
    		Declare @MaxIndex Int
    		Declare @Strength Nvarchar (10)
    		
    		Insert into @StrengthInfo
    		(
    			Strength
    		)
    		Select '1000'
    		Union All
    		Select '1500'
    		Union All
    		Select '2000'
    		Union All
    		Select '2500'
    		Union All
    		Select '3000'
    		Union All
    		Select '3500'
    		Union All
    		Select '4000'
    		Union All
    		Select '4500'
    		Union All
    		Select '5000'
    		Union All
    		Select '5500'
    		Union All
    		Select '6000'
    		Union All
    		Select '6500'
    		Union All
    		Select '7000'
    		Union All
    		Select '7500'
    		Union All
    		Select '8000'
    		Union All
    		Select '8500'
    		Union All
    		Select '9000'
    		Union All
    		Select '9500'
    		
    		Set @MaxIndex = (Select Max(AutoID) From @StrengthInfo)
    		Set @Index = 1
    		
    		While @Index <= @MaxIndex
    		Begin
    			Set @Strength = ''
    			Set @Strength = Ltrim(Rtrim((Select Strength From @StrengthInfo Where AutoID = @Index)))
    			
    			If Isnull(@Strength, '') <> ''
    			Begin
    			    Update MixInfo
    			        Set MixInfo.StrengthAge = 28.0,
    			            MixInfo.Strength = Cast(@Strength As Float)
    			    From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
    			    Where   MixInfo.Strength Is Null And
    			            Charindex(@Strength, MixInfo.MixDescription) > 0 And
    			            Charindex(@Strength + '0', MixInfo.MixDescription) < 1 

    			    Update MixInfo
    			        Set MixInfo.StrengthAge = 28.0,
    			            MixInfo.Strength = Cast(@Strength As Float)
    			    From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
    			    Where   MixInfo.Strength Is Null And
    			            Charindex(@Strength, MixInfo.MixShortDescription) > 0 And
    			            Charindex(@Strength + '0', MixInfo.MixShortDescription) < 1 


    			    Update MixInfo
    			        Set MixInfo.StrengthAge = 28.0,
    			            MixInfo.Strength = Cast(@Strength As Float)
    			    From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
    			    Where   MixInfo.Strength Is Null And
    			            Charindex(@Strength, MixInfo.ItemCategory) > 0 And
    			            Charindex(@Strength + '0', MixInfo.ItemCategory) < 1 
    			End
    			
    		    Set @Index = @Index + 1
    		End
    		
            Update MixInfo
                Set MixInfo.Strength = Cast(Ltrim(Rtrim(Left(MixInfo.MixDescription, Charindex(' ', MixInfo.MixDescription) - 1))) As Float)
            From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
            Where   MixInfo.Strength Is Null And
                    Case
                        When Charindex(' ', MixInfo.MixDescription) < 1
                        Then 0
                        When    Len(Ltrim(Rtrim(Left(MixInfo.MixDescription, Charindex(' ', MixInfo.MixDescription) - 1)))) = 4 And
                                Isnumeric(Ltrim(Rtrim(Left(MixInfo.MixDescription, Charindex(' ', MixInfo.MixDescription) - 1)))) = 1
                        Then 1
                        Else 0
                    End = 1

            Update MixInfo
                Set MixInfo.Strength = Cast(Ltrim(Rtrim(Left(MixInfo.MixDescription, Charindex('psi', MixInfo.MixDescription) - 1))) As Float)
            From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
            Where   MixInfo.Strength Is Null And
                    Case
                        When Charindex('psi', MixInfo.MixDescription) < 1
                        Then 0
                        When    Len(Ltrim(Rtrim(Left(MixInfo.MixDescription, Charindex('psi', MixInfo.MixDescription) - 1)))) = 4 And
                                Isnumeric(Ltrim(Rtrim(Left(MixInfo.MixDescription, Charindex('psi', MixInfo.MixDescription) - 1)))) = 1
                        Then 1
                        Else 0
                    End = 1

            If Isnull(@ClearLowStrengthsForUS, 0) = 1
            Begin
                Update MixInfo
                    Set MixInfo.StrengthAge = Null,
                        MixInfo.Strength = Null
                From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
                Where MixInfo.Strength < 49.0
            End

            /*
            Update MixInfo
                Set MixInfo.Strength = Cast(Ltrim(Rtrim(Left(MixInfo.MixDescription, Charindex('-', MixInfo.MixDescription) - 1))) As Float)
            From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
            Where   MixInfo.Strength Is Null And
                    Case
                        When Charindex('-', MixInfo.MixDescription) < 1
                        Then 0
                        When    Len(Ltrim(Rtrim(Left(MixInfo.MixDescription, Charindex('-', MixInfo.MixDescription) - 1)))) = 4 And
                                Isnumeric(Ltrim(Rtrim(Left(MixInfo.MixDescription, Charindex('-', MixInfo.MixDescription) - 1)))) = 1
                        Then 1
                        Else 0
                    End = 1
                    
            Update MixInfo
                Set MixInfo.Strength = Cast(MixInfo.MixDescription As Float)
            From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
            Where   MixInfo.Strength Is Null And
                    Case
                        When Len(Isnull(MixInfo.MixDescription, '')) <> 4 
                        Then 0
                        When    Len(Isnull(MixInfo.MixDescription, '')) = 4 And
                                iServiceDataExchange.dbo.Validation_ValueIsNumeric(MixInfo.MixDescription) = 0
                        Then 0
                        When Cast(MixInfo.MixDescription As Float) >= 1000
                        Then 1
                        Else 0
                    End = 1
            */                    
            /*
            Update MixInfo
                Set MixInfo.Strength = Cast(Ltrim(Rtrim(Left(MixInfo.MixDescription, Charindex('N', MixInfo.MixDescription) - 1))) As Float)
            From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
            Where   MixInfo.Strength Is Null And
                    Case
                        When Charindex('N', MixInfo.MixDescription) < 1
                        Then 0
                        When    Len(Ltrim(Rtrim(Left(MixInfo.MixDescription, Charindex('N', MixInfo.MixDescription) - 1)))) = 4 And
                                Isnumeric(Ltrim(Rtrim(Left(MixInfo.MixDescription, Charindex('N', MixInfo.MixDescription) - 1)))) = 1
                        Then 1
                        Else 0
                    End = 1

            Update MixInfo
                Set MixInfo.Strength = Cast(Ltrim(Rtrim(Left(MixInfo.MixDescription, Charindex('A', MixInfo.MixDescription) - 1))) As Float)
            From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
            Where   MixInfo.Strength Is Null And
                    Case
                        When Charindex('A', MixInfo.MixDescription) < 1
                        Then 0
                        When    Len(Ltrim(Rtrim(Left(MixInfo.MixDescription, Charindex('A', MixInfo.MixDescription) - 1)))) = 4 And
                                Isnumeric(Ltrim(Rtrim(Left(MixInfo.MixDescription, Charindex('A', MixInfo.MixDescription) - 1)))) = 1
                        Then 1
                        Else 0
                    End = 1
            */

            /*
    	    Declare @FirstChar Nvarchar (1) = '"'
    	    Declare @SecondChar Nvarchar (1) = ' '
            
            Update MixInfo
                Set MixInfo.Strength = Cast(Ltrim(Rtrim(Left(Substring(MixInfo.MixDescription, Charindex(@FirstChar, MixInfo.MixDescription) + 1, Len(MixInfo.MixDescription)), Charindex(@SecondChar, Substring(MixInfo.MixDescription, Charindex(@FirstChar, MixInfo.MixDescription) + 1, Len(MixInfo.MixDescription))) - 1))) As Float)
            From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
            Where   MixInfo.Strength Is Null And
                    Case
                        When Isnull(MixInfo.MixDescription, '') = '' 
                        Then 0
                        When Charindex(@FirstChar, MixInfo.MixDescription) < 1
                        Then 0
                        When Charindex(@SecondChar, Substring(MixInfo.MixDescription, Charindex(@FirstChar, MixInfo.MixDescription) + 1, Len(MixInfo.MixDescription))) < 1
                        Then 0
                        When Len(Ltrim(Rtrim(Left(Substring(MixInfo.MixDescription, Charindex(@FirstChar, MixInfo.MixDescription) + 1, Len(MixInfo.MixDescription)), Charindex(@SecondChar, Substring(MixInfo.MixDescription, Charindex(@FirstChar, MixInfo.MixDescription) + 1, Len(MixInfo.MixDescription))) - 1)))) <> 4
                        Then 0
                        When iServiceDataExchange.dbo.Validation_ValueIsNumeric(Ltrim(Rtrim(Left(Substring(MixInfo.MixDescription, Charindex(@FirstChar, MixInfo.MixDescription) + 1, Len(MixInfo.MixDescription)), Charindex(@SecondChar, Substring(MixInfo.MixDescription, Charindex(@FirstChar, MixInfo.MixDescription) + 1, Len(MixInfo.MixDescription))) - 1)))) = 0
                        Then 0
                        When Cast(Ltrim(Rtrim(Left(Substring(MixInfo.MixDescription, Charindex(@FirstChar, MixInfo.MixDescription) + 1, Len(MixInfo.MixDescription)), Charindex(@SecondChar, Substring(MixInfo.MixDescription, Charindex(@FirstChar, MixInfo.MixDescription) + 1, Len(MixInfo.MixDescription))) - 1))) As Float) <= 0.0            
                        Then 0
                        Else 1
                    End = 1
            */
            /*
            Update MixInfo
                Set MixInfo.Strength = Cast(Ltrim(Rtrim(Left(MixInfo.MixShortDescription, Charindex(' ', MixInfo.MixShortDescription) - 1))) As Float)
            From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
            Where   MixInfo.Strength Is Null And
                    Case
                        When Charindex(' ', MixInfo.MixShortDescription) < 1
                        Then 0
                        When    Len(Ltrim(Rtrim(Left(MixInfo.MixShortDescription, Charindex(' ', MixInfo.MixShortDescription) - 1)))) = 4 And
                                Isnumeric(Ltrim(Rtrim(Left(MixInfo.MixShortDescription, Charindex(' ', MixInfo.MixShortDescription) - 1)))) = 1
                        Then 1
                        Else 0
                    End = 1

            Update MixInfo
                Set MixInfo.Strength = Cast(Ltrim(Rtrim(Left(MixInfo.MixShortDescription, Charindex(',', MixInfo.MixShortDescription) - 1))) As Float)
            From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
            Where   MixInfo.Strength Is Null And
                    Case
                        When Charindex(',', MixInfo.MixShortDescription) < 1
                        Then 0
                        When    Len(Ltrim(Rtrim(Left(MixInfo.MixShortDescription, Charindex(',', MixInfo.MixShortDescription) - 1)))) = 4 And
                                Isnumeric(Ltrim(Rtrim(Left(MixInfo.MixShortDescription, Charindex(',', MixInfo.MixShortDescription) - 1)))) = 1
                        Then 1
                        Else 0
                    End = 1

            Update MixInfo
                Set MixInfo.Strength = Cast(Ltrim(Rtrim(Left(MixInfo.MixShortDescription, Charindex('@', MixInfo.MixShortDescription) - 1))) As Float)
            From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
            Where   MixInfo.Strength Is Null And
                    Case
                        When Charindex('@', MixInfo.MixShortDescription) < 1
                        Then 0
                        When    Len(Ltrim(Rtrim(Left(MixInfo.MixShortDescription, Charindex('@', MixInfo.MixShortDescription) - 1)))) = 4 And
                                Isnumeric(Ltrim(Rtrim(Left(MixInfo.MixShortDescription, Charindex('@', MixInfo.MixShortDescription) - 1)))) = 1
                        Then 1
                        Else 0
                    End = 1

            Update MixInfo
                Set MixInfo.Strength = Cast(Ltrim(Rtrim(Left(MixInfo.MixShortDescription, Charindex('_', MixInfo.MixShortDescription) - 1))) As Float)
            From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
            Where   MixInfo.Strength Is Null And
                    Case
                        When Charindex('_', MixInfo.MixShortDescription) < 1
                        Then 0
                        When    Len(Ltrim(Rtrim(Left(MixInfo.MixShortDescription, Charindex('_', MixInfo.MixShortDescription) - 1)))) = 4 And
                                Isnumeric(Ltrim(Rtrim(Left(MixInfo.MixShortDescription, Charindex('_', MixInfo.MixShortDescription) - 1)))) = 1
                        Then 1
                        Else 0
                    End = 1

            Update MixInfo
                Set MixInfo.Strength = Cast(Ltrim(Rtrim(Left(MixInfo.MixShortDescription, Charindex('psi', MixInfo.MixShortDescription) - 1))) As Float)
            From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
            Where   MixInfo.Strength Is Null And
                    Case
                        When Charindex('psi', MixInfo.MixShortDescription) < 1
                        Then 0
                        When    Len(Ltrim(Rtrim(Left(MixInfo.MixShortDescription, Charindex('psi', MixInfo.MixShortDescription) - 1)))) = 4 And
                                Isnumeric(Ltrim(Rtrim(Left(MixInfo.MixShortDescription, Charindex('psi', MixInfo.MixShortDescription) - 1)))) = 1
                        Then 1
                        Else 0
                    End = 1
        


            Update MixInfo
                Set MixInfo.Strength = Cast(Ltrim(Rtrim(Left(MixInfo.MixDescription, Charindex(' ', MixInfo.MixDescription) - 1))) As Float)
            From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
            Where   MixInfo.Strength Is Null And
                    Case
                        When Charindex(' ', MixInfo.MixDescription) < 1
                        Then 0
                        When    Len(Ltrim(Rtrim(Left(MixInfo.MixDescription, Charindex(' ', MixInfo.MixDescription) - 1)))) = 4 And
                                Isnumeric(Ltrim(Rtrim(Left(MixInfo.MixDescription, Charindex(' ', MixInfo.MixDescription) - 1)))) = 1
                        Then 1
                        Else 0
                    End = 1

            Update MixInfo
                Set MixInfo.Strength = Cast(Ltrim(Rtrim(Left(MixInfo.MixDescription, Charindex(',', MixInfo.MixDescription) - 1))) As Float)
            From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
            Where   MixInfo.Strength Is Null And
                    Case
                        When Charindex(',', MixInfo.MixDescription) < 1
                        Then 0
                        When    Len(Ltrim(Rtrim(Left(MixInfo.MixDescription, Charindex(',', MixInfo.MixDescription) - 1)))) = 4 And
                                Isnumeric(Ltrim(Rtrim(Left(MixInfo.MixDescription, Charindex(',', MixInfo.MixDescription) - 1)))) = 1
                        Then 1
                        Else 0
                    End = 1

            Update MixInfo
                Set MixInfo.Strength = Cast(Ltrim(Rtrim(Left(Substring(MixInfo.MixDescription, Charindex(' ', MixInfo.MixDescription) + 1, Len(MixInfo.MixDescription)), Charindex(' ', Substring(MixInfo.MixDescription, Charindex(' ', MixInfo.MixDescription) + 1, Len(MixInfo.MixDescription))) - 1))) As Float)
            From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
            Where   MixInfo.Strength Is Null And
                    Case
                        When Isnull(MixInfo.MixDescription, '') = '' 
                        Then 0
                        When Charindex(' ', MixInfo.MixDescription) < 1
                        Then 0
                        When Charindex(' ', Substring(MixInfo.MixDescription, Charindex(' ', MixInfo.MixDescription) + 1, Len(MixInfo.MixDescription))) < 1
                        Then 0
                        When Len(Ltrim(Rtrim(Left(Substring(MixInfo.MixDescription, Charindex(' ', MixInfo.MixDescription) + 1, Len(MixInfo.MixDescription)), Charindex(' ', Substring(MixInfo.MixDescription, Charindex(' ', MixInfo.MixDescription) + 1, Len(MixInfo.MixDescription))) - 1)))) <> 4
                        Then 0
                        When iServiceDataExchange.dbo.Validation_ValueIsNumeric(Ltrim(Rtrim(Left(Substring(MixInfo.MixDescription, Charindex(' ', MixInfo.MixDescription) + 1, Len(MixInfo.MixDescription)), Charindex(' ', Substring(MixInfo.MixDescription, Charindex(' ', MixInfo.MixDescription) + 1, Len(MixInfo.MixDescription))) - 1)))) = 0
                        Then 0
                        When Cast(Ltrim(Rtrim(Left(Substring(MixInfo.MixDescription, Charindex(' ', MixInfo.MixDescription) + 1, Len(MixInfo.MixDescription)), Charindex(' ', Substring(MixInfo.MixDescription, Charindex(' ', MixInfo.MixDescription) + 1, Len(MixInfo.MixDescription))) - 1))) As Float) <= 0.0            
                        Then 0
                        Else 1
                    End = 1
            */
            /*        
            Update MixInfo
                Set MixInfo.Strength =
                    Case
                        When Cast(Left(Substring(MixInfo.MixDescription, 5, Len(MixInfo.MixDescription)), Charindex(' ', Substring(MixInfo.MixDescription, 5, Len(MixInfo.MixDescription)))) As Float) >= 0.1
                        Then Cast(Left(Substring(MixInfo.MixDescription, 5, Len(MixInfo.MixDescription)), Charindex(' ', Substring(MixInfo.MixDescription, 5, Len(MixInfo.MixDescription)))) As Float)
                        Else Null
                    End
            From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
            Where   MixInfo.Strength Is Null And
                    MixInfo.MixDescription Like 'FOB %' And
                    dbo.Validation_ValueIsNumeric(Left(Substring(MixInfo.MixDescription, 5, Len(MixInfo.MixDescription)), Charindex(' ', SubString(MixInfo.MixDescription, 5, Len(MixInfo.MixDescription))))) = 1 And
                    Len(Ltrim(Rtrim(Left(SubString(MixInfo.MixDescription, 5, Len(MixInfo.MixDescription)), Charindex(' ', SubString(MixInfo.MixDescription, 5, Len(MixInfo.MixDescription))))))) = 4 And
                    Charindex('.', Left(SubString(MixInfo.MixDescription, 5, Len(MixInfo.MixDescription)), Charindex(' ', SubString(MixInfo.MixDescription, 5, Len(MixInfo.MixDescription))))) < 1
            */
    	End
    	Else
    	Begin
            Update MixInfo
                Set MixInfo.Strength = Cast(Ltrim(Rtrim(Left(MixInfo.MixShortDescription, Charindex('mpa', MixInfo.MixShortDescription) - 1))) As Float)
            --Select MixInfo.Strength , Cast(Ltrim(Rtrim(Left(MixInfo.MixShortDescription, Charindex('mpa', MixInfo.MixShortDescription) - 1))) As Float), *
            From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
            Where   MixInfo.Strength Is Null And
                    Case
                        When Charindex('mpa', MixInfo.MixShortDescription) < 1
                        Then 0
                        When    Len(Ltrim(Rtrim(Left(MixInfo.MixShortDescription, Charindex('mpa', MixInfo.MixShortDescription) - 1)))) = 2 And
                                Isnumeric(Ltrim(Rtrim(Left(MixInfo.MixShortDescription, Charindex('mpa', MixInfo.MixShortDescription) - 1)))) = 1
                        Then 1
                        Else 0
                    End = 1
    	    
            Update MixInfo
                Set MixInfo.Strength = Cast(Ltrim(Rtrim(Left(MixInfo.MixDescription, Charindex('mpa', MixInfo.MixDescription) - 1))) As Float)
            From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
            Where   MixInfo.Strength Is Null And
                    Case
                        When Charindex('mpa', MixInfo.MixDescription) < 1
                        Then 0
                        When    Len(Ltrim(Rtrim(Left(MixInfo.MixDescription, Charindex('mpa', MixInfo.MixDescription) - 1)))) = 2 And
                                Isnumeric(Ltrim(Rtrim(Left(MixInfo.MixDescription, Charindex('mpa', MixInfo.MixDescription) - 1)))) = 1
                        Then 1
                        Else 0
                    End = 1

            Update MixInfo
                Set MixInfo.Strength = Cast(Substring(MixInfo.MixDescription, Charindex('mpa', MixInfo.MixDescription) - 2, 2) As Float)
            From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
            Where   MixInfo.Strength Is Null And
                    Case
                        When Charindex('mpa', MixInfo.MixDescription) < 1
                        Then 0
                        When Charindex('mpa', MixInfo.MixDescription) - 3 < 2
                        Then 0
                        When Substring(MixInfo.MixDescription, Charindex('mpa', MixInfo.MixDescription) - 3, 1) <> ' '
                        Then 0
                        When dbo.Validation_ValueIsNumeric(Substring(MixInfo.MixDescription, Charindex('mpa', MixInfo.MixDescription) - 2, 2)) = 0
                        Then 0
                        When Cast(Substring(MixInfo.MixDescription, Charindex('mpa', MixInfo.MixDescription) - 2, 2) As Float) <= 0.0
                        Then 0
                        Else 1
                    End = 1
    	End

        Update MixInfo
            Set MixInfo.StrengthAge = Null
        From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
        Where MixInfo.Strength Is Null
    	
        Update MixInfo
            Set MixInfo.StrengthAge = 28.0
        From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
        Where MixInfo.StrengthAge Is Null And MixInfo.Strength Is Not Null

    End
End
Go
