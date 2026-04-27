If dbo.Validation_StoredProcedureExists('PlantImport_ImportPlants') = 1
Begin
	Drop Procedure dbo.PlantImport_ImportPlants
End
Go
