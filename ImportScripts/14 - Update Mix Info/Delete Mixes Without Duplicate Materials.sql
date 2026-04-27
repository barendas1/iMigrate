Delete MixInfo
From dbo.TestImport0000_MixInfo As MixInfo
Left Join 
(
	Select -1 As ID, MixInfo.PlantCode, MixInfo.MixCode
	From
	(
	    Select MixInfo.PlantCode, MixInfo.MixCode
	    From dbo.TestImport0000_MixInfo As MixInfo
	    Group By MixInfo.PlantCode, MixInfo.MixCode, MixInfo.MaterialItemCode
	    Having Count(*) > 1
	) As MixInfo
	Group By MixInfo.PlantCode, MixInfo.MixCode
) As MultiMixInfo
On  MixInfo.PlantCode = MultiMixInfo.PlantCode And MixInfo.MixCode = MultiMixInfo.MixCode
Where MultiMixInfo.ID Is Null
