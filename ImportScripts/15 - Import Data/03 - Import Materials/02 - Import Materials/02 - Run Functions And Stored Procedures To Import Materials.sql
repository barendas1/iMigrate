If ObjectProperty(Object_ID(N'[dbo].[ACIBatchViewDetails]'), N'IsUserTable') = 1
Begin
	Declare @ErrorMessage Nvarchar (Max)
	Declare @ErrorSeverity Int
	
	/*
	Delete From Aggregate
	Delete From Material Where FamilyMaterialTypeID In (1,2,3,4,5) And MATERIALIDENTIFIER Not In (Select MaterialID From MaterialRecipe)
	*/

	Begin Try
		Begin Transaction

		Raiserror('', 0, 0) With Nowait
		Raiserror('Remove Unlinked Production Items', 0, 0) With Nowait

		Delete ItemMaster
		From dbo.ItemMaster As ItemMaster
		Left Join dbo.BATCH As Mix
		On Mix.ItemMasterID = ItemMaster.ItemMasterID
		Left Join dbo.MATERIAL As Material
		On Material.ItemMasterID = ItemMaster.ItemMasterID
		Where	Mix.BATCHIDENTIFIER Is Null And
				Material.MATERIALIDENTIFIER Is Null
		/*
		Raiserror('', 0, 0) With Nowait
		Raiserror('Remove Unlinked Material Production Item Categories', 0, 0) With Nowait
		
		Delete CategoryInfo
		From dbo.ProductionItemCategory As CategoryInfo
		Left Join dbo.ItemMaster As ItemMaster1
		On ItemMaster1.ProdItemCatID = CategoryInfo.ProdItemCatID
		Left Join dbo.ItemMaster As ItemMaster2
		On ItemMaster2.ProdItemCompTypeID = CategoryInfo.ProdItemCatID
		Where	CategoryInfo.ProdItemCatType In ('Mtrl', 'MtrlCompType') And
				ItemMaster1.ItemMasterID Is Null And
				ItemMaster2.ItemMasterID Is Null
		*/
		If dbo.Validation_StoredProcedureExists('MaterialImport_ImportItemCategories') = 1
		Begin
			Raiserror('', 0, 0) With Nowait
			Raiserror('Import Item Categories', 0, 0) With Nowait
			
			Exec dbo.MaterialImport_ImportItemCategories
		End
		
		If dbo.Validation_StoredProcedureExists('MaterialImport_ImportMaterials') = 1
		Begin
			Raiserror('', 0, 0) With Nowait
			Raiserror('Import Materials', 0, 0) With Nowait
			
			Exec dbo.MaterialImport_ImportMaterials
				@UpdateExistingProductionItems = 1,
				@UserID = 5,
				@DeactivateMaterials = 0
		End
		
		Commit Transaction
	    
		Raiserror('', 0, 0) With Nowait
		Raiserror('One or more Materials may have been imported.', 0, 0) With Nowait
	End Try
	Begin catch
		If @@TRANCOUNT > 0
		Begin
			Rollback Transaction
		End

		Select	@ErrorMessage = Error_message(),
				@ErrorSeverity = Error_severity()

		Raiserror('', 0, 0) With Nowait
		Raiserror('The Materials could not be imported.  The Import was rolled back.', 0, 0) With Nowait
		Print 'Error Severity - ' + Cast(@ErrorSeverity As Nvarchar) + '.  Error Message: ' + @ErrorMessage
	End Catch
End
