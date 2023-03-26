<#
Renombra el OSDisk de una VM en Azure.
Si quieres borrar el disco anterior, hay que quitar el lock en el resource group.
El tamaño del disco tiene que ser igual o superior, no inferior
Realiza un snapshot del disco para estar más seguro

.Ejemplo
.\Rename-AzOSDisk.ps1 -resourceGroup [NombreResourceGroup] -VMName [NombreVM] -osdiskName [NombreDiscoSistema] -sizeosdisk [TamañoDiscoenGB] -Verbose

#>

[CmdletBinding()]
Param (
    [Parameter(Position = 0, Mandatory = $true, HelpMessage = 'Resource Group de la VM')]
    [Alias('rg')]
    [String]$resourceGroup,

    [Parameter(Position = 1, Mandatory = $True, HelpMessage = 'Nombre de la VM')]
    [Alias('VM')]
    [String]$VMName,

    [Parameter(Position = 2, Mandatory = $true, HelpMessage = 'Nombre del nuevo disco sistema')]
    [Alias('DiskName')]
    [String]$osdiskName,
    
    [Parameter(Position = 3, Mandatory = $true, HelpMessage = 'Tamaño del nuevo disco de sistema')]
    [Alias('SizeDisk')]
    [String]$sizeosdisk

)


#! Detalles de la VM
Write-Verbose "Obteniendo detalles de la VM: $VMName"
$VM = Get-AzVM -Name $VMName -ResourceGroupName $resourceGroup

#! Información del disco de sistema
Write-Verbose "Obtenidendo información del disco de sistema: $($VM.StorageProfile.OsDisk.Name)"
$sourceOSDisk = Get-AzDisk -ResourceGroupName $resourceGroup -DiskName $VM.StorageProfile.OsDisk.Name

#! Crea un nuevo disco con el nombre nuevo y del tamaño que queramos
Write-Verbose "Creando la configuración del nuevo disco"
$diskConfig = New-AzDiskConfig -SkuName $sourceOSDisk.Sku.Name -Location $VM.Location `
    -DiskSizeGB $SizeOSDisk -SourceResourceId $sourceOSDisk.Id -CreateOption Copy

#! Creando el nuevo disco de sistema
Write-Verbose "Creando el nuevo disco de sistema"
$newOSDisk = New-AzDisk -Disk $diskConfig -DiskName $osdiskName -ResourceGroupName $resourceGroup

#! Hace el swap del disco
Write-Verbose "Cambiando el disco de sistema a: $osdiskName"
Set-AzVMOSDisk -VM $VM -ManagedDiskId $newOSDisk.Id -Name $osdiskName | Out-Null
Write-Verbose "La VM está reiniciando"
Update-AzVM -ResourceGroupName $resourceGroup -VM $VM

#Elimina el lock en el Resource Group
$AlertLock = Get-AzResourceLock -ResourceGroupName $resourceGroup -LockName "NoDelete" -ErrorAction SilentlyContinue
# If there is NO lock on the Resource Group
if ($null -eq $AlertLock) {
        # Write to console
        Write-Output "$VMName : No hay Lock en el Resource Group: $resourceGroup"
    }else {
        # Write to console
        Write-Output "$VMName : Eliminado el Lock en el Resource Group: $resourceGroup"
        # Remove the Resource Lock on the Resource Group the VM is located in
        Remove-AzResourceLock -LockName "NoDelete" -ResourceGroupName $resourceGroup -Force
    }

#! Elimina el disco antiguo
$delete = Read-Host "¿Quieres eliminar el antiguo disco de sistema [s/n]?"
If ($delete -eq "s" -or $delete -eq "S") {
    Write-Warning "Eliminando el antiguo disco de sistema: $($sourceOSDisk.Name)"
    Remove-AzDisk -ResourceGroupName $resourceGroup -DiskName $sourceOSDisk.Name -Force -Confirm:$false
}
