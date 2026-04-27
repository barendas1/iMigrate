Update Material
	Set Material.NameID = ItemName.NameID
--Select *
From dbo.Material As Material
Inner Join
(
    Select Material.PlantID, Material.NameID, Min(Material.MATERIALIDENTIFIER) As MATERIALIDENTIFIER
    From dbo.MATERIAL As Material
    Where Material.ItemMasterID Is Not Null
    Group By Material.PlantID, Material.NameID
    Having Count(Distinct Material.ItemMasterID) > 1
) As MaterialInfo
On Material.PlantID = MaterialInfo.PlantID And Material.NameID = MaterialInfo.NameID
Inner Join dbo.ItemMaster As ItemMaster
On Material.ItemMasterID = ItemMaster.ItemMasterID
Inner Join dbo.Name As ItemName
On ItemMaster.NameID = ItemName.NameID
Where Material.MATERIALIDENTIFIER <> MaterialInfo.MATERIALIDENTIFIER
Update Material
	Set Material.NameID = ItemName.NameID
--Select *
From dbo.Material As Material
Inner Join
(
    Select Material.PlantID, Material.NameID, Max(Material.MATERIALIDENTIFIER) As MATERIALIDENTIFIER
    From dbo.MATERIAL As Material
    Where Material.ItemMasterID Is Not Null
    Group By Material.PlantID, Material.NameID
    Having Count(Distinct Material.ItemMasterID) > 1
) As MaterialInfo
On Material.PlantID = MaterialInfo.PlantID And Material.NameID = MaterialInfo.NameID
Inner Join dbo.ItemMaster As ItemMaster
On Material.ItemMasterID = ItemMaster.ItemMasterID
Inner Join dbo.Name As ItemName
On ItemMaster.NameID = ItemName.NameID
Where Material.MATERIALIDENTIFIER <> MaterialInfo.MATERIALIDENTIFIER