If ObjectProperty(Object_ID(N'[dbo].[ACIBatchViewDetails]'), N'IsUserTable') = 1
Begin
	Declare @ErrorMessage Nvarchar (Max)
	Declare @ErrorSeverity Int
	
	Begin Try
		Begin Transaction
		
		If dbo.Validation_StoredProcedureExists('MixImport_ImportItemCategories') = 1
		Begin
			Raiserror('', 0, 0) With Nowait
			Raiserror('Import Item Categories', 0, 0) With Nowait
			
			Exec dbo.MixImport_ImportItemCategories
		End
		/*
		If dbo.Validation_StoredProcedureExists('MixImport_ImportPlants') = 1
		Begin
			Raiserror('', 0, 0) With Nowait
			Raiserror('Import Plants', 0, 0) With Nowait
			
			Exec dbo.MixImport_ImportPlants
		End
		
		If dbo.Validation_StoredProcedureExists('MixImport_ImportMaterials') = 1
		Begin
			Raiserror('', 0, 0) With Nowait
			Raiserror('Import Materials', 0, 0) With Nowait
			
			Exec dbo.MixImport_ImportMaterials
		End
		*/
		If dbo.Validation_StoredProcedureExists('MixImport_ImportMixes') = 1
		Begin
			Raiserror('', 0, 0) With Nowait
			Raiserror('Import Mixes', 0, 0) With Nowait
			
			Exec dbo.MixImport_ImportMixes
				@AllowedToOverwriteMixes = 1,
				@UpdateExistingProdItems = 1,
				@RemoveExistingMixClasses = 0,
				@AllowedToAddInactiveMaterials = 1,
				@DeactivateNewMixes = 0,
				@DeactivateExistingMixes = 0,
				@UpdateMixReportFields = 0
		End
		
		Commit Transaction
	    
		Raiserror('', 0, 0) With Nowait
		Raiserror('The Item Categories, Plants, Materials, and Mixes may have been imported.', 0, 0) With Nowait
	End Try
	Begin catch
		If @@TRANCOUNT > 0
		Begin
			Rollback Transaction
		End

		Select	@ErrorMessage = Error_message(),
				@ErrorSeverity = Error_severity()

		Print ''
		Print 'The Item Categories, Plants, Materials, and/or Mixes could not be imported.  The Import was rolled back.'
		Print 'Error Message - ' + @ErrorMessage
		Print 'Error Severity - ' + Cast(@ErrorSeverity As Nvarchar)
	End Catch
End
