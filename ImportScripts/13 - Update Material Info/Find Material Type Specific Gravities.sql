Select * From dbo.Static_MaterialType As MaterialType Order By MaterialType.RecipeOrder

Select MaterialType.Name As MaterialTypeName, Material.SPECGR As SpecificGravity, Count(*) As MaterialCount
From dbo.Material As Material
Inner Join dbo.Static_MaterialType As MaterialType
On Material.MaterialTypeLink = MaterialType.Static_MaterialTypeID
Where MaterialType.Name In ('Silica Fume')
Group By MaterialType.Name, Material.SPECGR
Order By MaterialType.Name, Material.SPECGR
