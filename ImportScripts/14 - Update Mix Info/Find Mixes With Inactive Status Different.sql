Select Plants.Name, MixName.Name, Mix.MixInactive, MixInfo.MixInactive, MixInfo.*
From Plants
Inner Join Batch As Mix
On Plants.PlantId = Mix.Plant_Link
Inner Join Name As MixName
On Mix.NameID = MixName.NameID
Inner Join Data_Import_RJ.dbo.TestImport0000_MixInfo As MixInfo
On Plants.Name = MixInfo.PlantCode And MixName.Name = MixInfo.MixCode
Where dbo.Validation_StringValueIsFalse(MixInfo.MixInactive) = IsNull(Mix.MixInactive, 0)