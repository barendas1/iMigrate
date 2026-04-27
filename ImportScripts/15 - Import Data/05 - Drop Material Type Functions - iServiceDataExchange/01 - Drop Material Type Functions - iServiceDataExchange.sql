If dbo.Validation_FunctionExists('GetFamilyMaterialTypeInfo') = 1
Begin
    Drop function dbo.GetFamilyMaterialTypeInfo
End
Go

If dbo.Validation_FunctionExists('GetReportMaterialTypeInfo') = 1
Begin
    Drop function dbo.GetReportMaterialTypeInfo
End
Go
