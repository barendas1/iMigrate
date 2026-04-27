If dbo.Validation_FunctionExists('GetFamilyMaterialTypeInfo') = 1
Begin
    Drop function dbo.GetFamilyMaterialTypeInfo
End
Go

Set Ansi_nulls On
Go

Set Quoted_identifier On
Go
Create Function [dbo].[GetFamilyMaterialTypeInfo]
(
)
Returns @FamilyMaterialTypeInfo Table
(
	MaterialTypeID Int Not null Primary Key,
	FamilyMaterialTypeID Int Null
)
As
Begin
	Declare @MaterialTypeInfo Table
	(
		MaterialTypeID Int Not null Primary Key,
		FamilyMaterialTypeID Int Null
	) 
	
	Insert into @MaterialTypeInfo (MaterialTypeID, FamilyMaterialTypeID)
		Select MaterialType.MaterialTypeID, MaterialType.MaterialTypeID
		From dbo.MaterialType As MaterialType
	
	While Exists
	(
		Select * 
		From @MaterialTypeInfo As MaterialTypeInfo
		Where	MaterialTypeInfo.FamilyMaterialTypeID Not In (1, 2, 3, 4, 5) And
				MaterialTypeInfo.FamilyMaterialTypeID Is Not null
	)
	Begin
		Update MaterialTypeInfo
			Set MaterialTypeInfo.FamilyMaterialTypeID = MaterialType.ParentID
		From @MaterialTypeInfo As MaterialTypeInfo
		Inner Join dbo.MaterialType As MaterialType
		On MaterialTypeInfo.FamilyMaterialTypeID = MaterialType.MaterialTypeID
		Where	MaterialTypeInfo.FamilyMaterialTypeID Not In (1, 2, 3, 4, 5) And
				MaterialTypeInfo.FamilyMaterialTypeID Is Not Null
	End
	
	Insert into @FamilyMaterialTypeInfo (MaterialTypeID, FamilyMaterialTypeID)
		Select	MaterialTypeInfo.MaterialTypeID,
				MaterialTypeInfo.FamilyMaterialTypeID
		From @MaterialTypeInfo As MaterialTypeInfo
	
	Return
End
Go

If dbo.Validation_FunctionExists('GetReportMaterialTypeInfo') = 1
Begin
    Drop function dbo.GetReportMaterialTypeInfo
End
Go

Set Ansi_nulls On
Go

Set Quoted_identifier On
Go
Create Function [dbo].[GetReportMaterialTypeInfo]
(
)
Returns @ReportMaterialTypeInfo Table
(
	MaterialTypeID Int Not null Primary Key,
	ReportMaterialTypeID Int Null
)
As
Begin
	Declare @MaterialTypeInfo Table
	(
		MaterialTypeID Int Not null Primary Key,
		ReportMaterialTypeID Int Null,
		Retrieved Bit
	) 
	
	Insert into @MaterialTypeInfo 
	(
		MaterialTypeID, 
		ReportMaterialTypeID, 
		Retrieved
	)
	Select	MaterialType.MaterialTypeID, 
			MaterialType.MaterialTypeID, 
			Case
				When	MaterialType.ParentID Is Null Or 
						MaterialType.MaterialTypeID In (1, 2, 3, 4, 5, 141, 142, 143, 149, 150, 181, 272, 274, 280) Or
						IsNull(MaterialType.ParentID, -1) In (1, 2, 3, 4, 5, 141, 142, 143, 149, 150, 181, 272, 274, 280)
				Then 1
				Else 0
			End
	From dbo.MaterialType As MaterialType
	
	While Exists
	(
		Select * 
		From @MaterialTypeInfo As MaterialTypeInfo
		Where	MaterialTypeInfo.Retrieved = 0
	)
	Begin
		Update MaterialTypeInfo
			Set MaterialTypeInfo.ReportMaterialTypeID = 
					Case
						When	MaterialType.ParentID Is Null Or 
								MaterialType.MaterialTypeID In (1, 2, 3, 4, 5, 141, 142, 143, 149, 150, 181, 272, 274, 280) Or
								IsNull(MaterialType.ParentID, -1) In (1, 2, 3, 4, 5, 141, 142, 143, 149, 150, 181, 272, 274, 280)
						Then MaterialType.MaterialTypeID
						Else MaterialType.ParentID
					End,
				MaterialTypeInfo.Retrieved =
					Case
						When	MaterialType.ParentID Is Null Or 
								MaterialType.MaterialTypeID In (1, 2, 3, 4, 5, 141, 142, 143, 149, 150, 181, 272, 274, 280) Or
								IsNull(MaterialType.ParentID, -1) In (1, 2, 3, 4, 5, 141, 142, 143, 149, 150, 181, 272, 274, 280)
						Then 1
						Else 0
					End
		From @MaterialTypeInfo As MaterialTypeInfo
		Inner Join dbo.MaterialType As MaterialType
		On MaterialTypeInfo.ReportMaterialTypeID = MaterialType.MaterialTypeID
		Where MaterialTypeInfo.Retrieved = 0
	End
	
	Insert into @ReportMaterialTypeInfo (MaterialTypeID, ReportMaterialTypeID)
		Select	MaterialTypeInfo.MaterialTypeID,
				MaterialTypeInfo.ReportMaterialTypeID
		From @MaterialTypeInfo As MaterialTypeInfo
	
	Return
End
Go
