If ObjectProperty(Object_ID(N'[dbo].[ACIBatchViewDetails]'), N'IsUserTable') = 1
Begin
	Declare @ErrorMessage Nvarchar (Max)
	Declare @ErrorSeverity Int
	
	Begin Try
		Begin Transaction
		
		If dbo.Validation_StoredProcedureExists('PlantImport_ImportPlants') = 1
		Begin
			Raiserror('', 0, 0) With Nowait
			Raiserror('Import Plants', 0, 0) With Nowait
			
			Exec dbo.PlantImport_ImportPlants
		End
		
		Commit Transaction
	    
		Raiserror('', 0, 0) With Nowait
		Raiserror('The Plants may have been imported.', 0, 0) With Nowait
	End Try
	Begin catch
		If @@TRANCOUNT > 0
		Begin
			Rollback Transaction
		End

		Select	@ErrorMessage = Error_message(),
				@ErrorSeverity = Error_severity()

		Print ''
		Print 'The Plants could not be imported.  The Import was rolled back.'
		Print 'Error Message - ' + @ErrorMessage
		Print 'Error Severity - ' + Cast(@ErrorSeverity As Nvarchar)
	End Catch
End
