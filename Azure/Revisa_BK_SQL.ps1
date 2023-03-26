<#
.SYNOPSIS 
Obtiene los elementos de copia de seguridad de un Server SQL.

.DESCRIPTION 
Busca en las copias de seguridad, tanto en las instancias como los elementos de backup de los SQL

.NOTES 
File Name     : Revisa_BK_SQL.ps1
Author        : Borja Terres
Version       : 1.0
Date          : 04-agosto-2022
Update        : 
Requires      : PowerShell 5.1 or PowerShell 7.1.x (Core)
Module        : Azure Az, Az.RecoveryServices
OS            : Windows
 
#>

[CmdletBinding()]
Param (
    [Parameter(Position = 0, Mandatory = $true, HelpMessage = 'Escribe el FQDN del servidor. Ej. servidor.ldap.pro')]
    
    [String]$Servidor
)


$vaultName = "BackupVMs"
$Subscription = "ES03"



$targetVault = Get-AzRecoveryServicesVault -Name $vaultName
$protectableItems = @(Get-AzRecoveryServicesBackupProtectableItem -workloadType MSSQL -VaultId $targetVault.ID | sort ServerName)
$ProtectableSQLInstances = $protectableItems | where {($_.ProtectableItemType -eq 'SQLInstance') -and ($_.ServerName -like $servidor)}
$bkpItems = @(Get-AzRecoveryServicesBackupItem -BackupManagementType AzureWorkload -WorkloadType MSSQL -VaultId $targetVault.ID) 
$StdAlnDBbkpNAMEDItems = $bkpItems | where {($_.ProtectionState -eq 'Protected')  -and ($_.ServerName -eq $servidor)} -debug

cls

Write-Output $ProtectableSQLInstances | Select-Object Name, ParentName, serverName, IsAutoprotected | Format-Table -AutoSize
Write-Output $StdAlnDBbkpNAMEDItems | Select-Object Name, WorkloadType,ProtectionStatus,lastbackupTime | Format-Table -AutoSize
