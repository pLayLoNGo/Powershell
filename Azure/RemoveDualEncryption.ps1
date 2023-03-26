Param (

    [Parameter(Position = 0, Mandatory = $True, HelpMessage = 'Nombre de la VM')]
    [String]$virtualMachineName ,

    [Parameter(Position = 1, Mandatory = $true, HelpMessage = 'Suscripción de destino de la VM')]
    [ValidateSet("SUBS1","SUBS2")]
    [String]$targetSubscriptionName,

    [Parameter(Position = 2, Mandatory = $true, HelpMessage = 'Resource Group Destino de la VM')]
    [String]$RG
)

$block = @"
                         _             _
 _ __   _ __  __      __(_) _ __    __| |  ___  __      __ ___
| '_ \ | '_ \ \ \ /\ / /| || '_ \  / _  | / _ \ \ \ /\ / // __|
| | | || | | | \ V  V / | || | | || (_| || (_) | \ V  V / \__ \
|_| |_||_| |_|  \_/\_/  |_||_| |_| \__,_| \___/   \_/\_/  |___/





"@

cls
#SUSTITUIR POR SWITCH
if ($targetSubscriptionName -eq "SUBS1") {
    $targetSubscriptionId = ''
    
     }
else {
    $targetSubscriptionId = ''
}

Write-Host $block -ForegroundColor Red
Select-AzSubscription -SubscriptionId $targetSubscriptionId 

#Apaga la máquina y elimina las configuraciones de encriptación doble
Write-Host "Apagando vm: $virtualMachineName" -Foreground Yellow
Stop-AzVM -ResourceGroupName $RG -Name $virtualMachineName -Force
$vm = Get-AzVM -ResourceGroupName $RG -VMName $virtualMachineName
$vm.StorageProfile.OsDisk.EncryptionSettings = $null
Write-Host "Actualizando configuración encriptado vm: $virtualMachineName" -Foreground Yellow
#Actualiza la VM con la configuración
$vm | Update-AzVM
#Muestra la configuración si es correcta. Si no saldría en blanco
$vm.StorageProfile.OsDisk.EncryptionSettings
$vm.StorageProfile.OsDisk
     
#Arranca la VM
Write-Host "Iniciando la vm: $virtualMachineName" -Foreground Yellow
Start-AzVM -ResourceGroupName $RG -Name $virtualMachineName
    
#Elimina la extensión AzureDiskEncryption
Write-Host "Eliminando la extensión AzureDiskEncryption" -Foreground Yellow
Remove-AzVMExtension -ResourceGroupName $RG -VMName $virtualMachineName -Name AzureDiskEncryption -Confirm
