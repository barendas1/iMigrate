Select *
From Data_Import_RJ.dbo.TestImport0000_MainMaterialInfo As MaterialInfo
Where   MaterialInfo.Name In
        (
            'SP BACKFILL',
            'test123',
            'TEST bmh',
            '20002000'       	
        )

Select *
From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
Where   MaterialInfo.ItemCode In
        (
            'SP BACKFILL',
            'test123',
            'TEST bmh',
            '20002000'       	
        )
 
/*      
Delete MaterialInfo
From Data_Import_RJ.dbo.TestImport0000_MainMaterialInfo As MaterialInfo
Where   MaterialInfo.Name In
        (
            'SP BACKFILL',
            'test123',
            'TEST bmh',
            '20002000'       	
        )

Delete MaterialInfo
From Data_Import_RJ.dbo.TestImport0000_MaterialInfo As MaterialInfo
Where   MaterialInfo.ItemCode In
        (
            'SP BACKFILL',
            'test123',
            'TEST bmh',
            '20002000'       	
        )
*/