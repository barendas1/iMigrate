If dbo.Validation_FunctionExists('GetFormattedStringDateFromDateAsMMDDYYYY') = 1
Begin
    Drop function dbo.GetFormattedStringDateFromDateAsMMDDYYYY
End
Go

If dbo.Validation_FunctionExists('GetFormattedStringDateFromDateAsDDMMYYYY') = 1
Begin
    Drop function dbo.GetFormattedStringDateFromDateAsDDMMYYYY
End
Go

If dbo.Validation_StoredProcedureExists('MaterialImport_ImportItemCategories') = 1
Begin
	Drop Procedure dbo.MaterialImport_ImportItemCategories
End
Go

If dbo.Validation_StoredProcedureExists('Utility_Print') = 1
Begin
	Drop Procedure dbo.Utility_Print
End
Go

If dbo.Validation_StoredProcedureExists('MaterialImport_ImportMaterials') = 1
Begin
	Drop Procedure dbo.MaterialImport_ImportMaterials
End
Go
