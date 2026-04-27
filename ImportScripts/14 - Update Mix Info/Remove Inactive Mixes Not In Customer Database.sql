Delete MixInfo
From Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
Left Join
(
	Select -1 As ID, Plant.Name As PlantCode, MixName.Name As MixCode
	From dbo.Plants As Plant
	Inner Join dbo.Batch As Mix
	On Mix.Plant_Link = Plant.PlantId
	Inner Join dbo.Name As MixName
	On MixName.NameID = Mix.NameID	
) As ExistingMix
On MixInfo.PlantCode = ExistingMix.PlantCode And MixInfo.MixCode = ExistingMix.MixCode
Where dbo.Validation_StringValueIsTrue(MixInfo.MixInactive) = 1 And ExistingMix.ID Is Null
