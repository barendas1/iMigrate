If dbo.Validation_FunctionExists('Validation_IsValidBase26Number') = 1
Begin
	Drop function [dbo].[Validation_IsValidBase26Number]
End
Go
	
If dbo.Validation_FunctionExists('GetBase10NumberFromBase26Number') = 1
Begin
	Drop function [dbo].[GetBase10NumberFromBase26Number]
End
Go
	
If dbo.Validation_FunctionExists('GetBase26NumberFromBase10Number') = 1
Begin
	Drop function [dbo].[GetBase26NumberFromBase10Number]
End
Go
	
If dbo.Validation_FunctionExists('GetMixNameCodeList') = 1
Begin
	Drop function [dbo].[GetMixNameCodeList]
End
Go

If dbo.Validation_StoredProcedureExists('Utility_Print') = 1
Begin
	Drop Procedure dbo.Utility_Print
End
Go

If dbo.Validation_StoredProcedureExists('MixImport_ImportItemCategories') = 1
Begin
	Drop Procedure dbo.MixImport_ImportItemCategories
End
Go
	
If dbo.Validation_StoredProcedureExists('MixImport_ImportPlants') = 1
Begin
	Drop Procedure dbo.MixImport_ImportPlants
End
Go

If dbo.Validation_StoredProcedureExists('MixImport_ImportMaterials') = 1
Begin
	Drop Procedure dbo.MixImport_ImportMaterials
End
Go

If dbo.Validation_StoredProcedureExists('MixImport_ImportMixes') = 1
Begin
	Drop Procedure dbo.MixImport_ImportMixes
End
Go
