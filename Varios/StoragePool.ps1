<#
.SYNOPSIS Script para la creación de storage pools
.DESCRIPTION Crea un storage pool, un disco virtual, inicializa, crea partición y formatea para SQL.

.NOTES File Name : StoragePool.ps1
Author   : Borja Terres
Version  : 1.0
Date     : 10-julio-2023
Update   : 
Requires : PowerShell 5.1 or PowerShell 7.1.x (Core)
Module   : 
OS       : Windows

Añadir previamente solamente los discos que queremos incluir en el storage pool.
Si existen otros discos que no queremos añadir, debemos de seleccionar los que queramos mediante una condición. En este caso mediante un where-object.

Si el almacenamiento se añade en un failover cluster y el cluster se lo queda, antes de añadir los discos haría lo siguiente:
    
    Get-StorageSubSystem 

Apuntamos el nombre del subsistema de almacenamiento del cluster. En este caso >> Clustered Windows Storage on SQLP2K1910
Forzamos que los próximos discos que no se añadan al almacenamiento del cluster:

    Set-StorageSubSystem -AutomaticClusteringEnabled $false -FriendlyName "Clustered Windows Storage on SQLP2K1910"

#>



#Variables
$FriendlyName = 'aoshpirm_Data'
$DriveLetter = 'J'

#Si están en un failovercluster hay que usar "Clustered Windows Storage*" en vez de "Windows Storage*". 
$PhysicalDisks = Get-StorageSubSystem -FriendlyName "Windows Storage*" | Get-PhysicalDisk -CanPool $True  # | where-object {$_.Size -eq "1099511627776"}

New-StoragePool -FriendlyName $FriendlyName -StorageSubsystemFriendlyName "Windows Storage*" -PhysicalDisks $PhysicalDisks | New-VirtualDisk -FriendlyName $FriendlyName -UseMaximumSize -ProvisioningType Fixed | Initialize-Disk -PassThru | New-Partition -AssignDriveLetter -UseMaximumSize -DriveLetter $DriveLetter  | Format-Volume -FileSystemLabel $FriendlyName -AllocationUnitSize '64K'
