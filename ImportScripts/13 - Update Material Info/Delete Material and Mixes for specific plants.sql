delete from dbo.TestImport0000_MaterialInfo
where PlantName not in 
(
'4',
'6',
'8',
'9',
'10',
'12',
'14',
'16'
)

delete from dbo.TestImport0000_MixInfo
where PlantCode not in
(
'4',
'6',
'8',
'9',
'10',
'12',
'14',
'16'
)