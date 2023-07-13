<#
.SYNOPSIS
    Script para la migración de VMs entre suscripciones de Azure.

.DESCRIPTION
    
* Desencripta los discos
* Apaga la VM
* Crea y mueve snapshots
* Clona la VM
* Añade discos
* Monitorización
* Tags
* BK
* Desencriptación dual en destino.
* Encriptación de discos.



.EXAMPLE
    PS C:\> Move-VM-DEV.ps1 -virtualMachineName SHD2K1201

.INPUTS
    -virtualMachineName: Nombre de la VM
    -targetSubscriptionName: Nombre de la suscripción
    -sourceResourceGroupName: RG de origen.
    -targetResourceGroupName: RG de destino.
    -privateIP: IP en destino
    -Domain: Dominio
    -targetsubnetName: Subnet de la VM
    -AvailabilitySet: La VM va a estar en un availabilty set s/n



.NOTES
    File Name: Move-VM-DEV.ps1
    Author   : Borja Terres
    Version  : 1.7
    Date     : 30-septiembre-2022
    Update   : 07-julio-2023
    Requires : PowerShell 5.1 or PowerShell 7.1.x (Core)
    Module   : Az
    OS       : Windows
 

#>


Param (
    [Parameter(Position = 0, Mandatory = $True, HelpMessage = 'Nombre de la VM')]
    [String]$virtualMachineName ,

    [Parameter(Position = 1, Mandatory = $true, HelpMessage = 'Suscripción de destino de la VM')]
    [ValidateSet("ESNN-DTA-01","ESNN-PROD-01")]
    [String]$targetSubscriptionName,

    [Parameter(Position = 2, Mandatory = $true, HelpMessage = 'Resource Group Origen de la VM')]
    [String]$sourceResourceGroupName,

    [Parameter(Position = 3, Mandatory = $true, HelpMessage = 'Resource Group Destino de la VM')]
    [String]$targetResourceGroupName,
    
    [Parameter(Position = 4, Mandatory = $true, HelpMessage = 'IP Privada de la VM')]
    [String]$privateIP,

    [Parameter(Position = 5, Mandatory = $true, HelpMessage = 'Dominio de la VM')]
    [ValidateSet("ldap.pro","insim.biz","ldapt.nne.es","nne.es")]
    [String]$Domain,
        
    [Parameter(Position = 6, Mandatory = $true, HelpMessage = 'Subnet nueva de la VM')]
    [String]$targetsubnetName,

    [Parameter(Position = 7, Mandatory = $true, HelpMessage = 'El servidor va a estar en un availabilty set s/n')]
    [ValidateSet("s","n")]
    [String]$AvailabilitySet
)

$block = @"
                         _             _
 _ __   _ __  __      __(_) _ __    __| |  ___  __      __ ___
| '_ \ | '_ \ \ \ /\ / /| || '_ \  / _  | / _ \ \ \ /\ / // __|
| | | || | | | \ V  V / | || | | || (_| || (_) | \ V  V / \__ \
|_| |_||_| |_|  \_/\_/  |_||_| |_| \__,_| \___/   \_/\_/  |___/





"@

Clear-Host
Write-Host $block -ForegroundColor Red 


###########
#VARIABLES#
###########

$location = 'WestEurope'
$SourceSubscriptionName = 'ES03'

#Provide the subscription Id of the subscription where snapshot exists
$sourceSubscriptionId = '71634049-5857-4e06-b846-f5c835ebe4d7'
if ($targetSubscriptionName -eq "ESNN-DTA-01") {
    $targetSubscriptionId = '7344430c-4d3f-4d2a-865d-664f842b68c0'
    $virtualNetworkName = 'NNANPSpoke-ESNN-DTA-01'
    $KeyVaultName =  'nnsp-encryptdtann-kv'
    $keyName = 'VirtualMachine2022'
    }
else {
    $targetSubscriptionId = 'd1345562-ef63-477c-93f1-f75ee71d487f'
    $virtualNetworkName = 'NNANPSpoke-ESNN-PROD-01'
    $KeyVaultName =  'nnsp-encrypt-pro-kv'
    $keyName = 'VirtualMachines'
}


#Provide the RG of the Virtual Network
$ResourceGroupVNet= 'AzureVnet'

#Monitoring
$WorkspaceId = 'd1be8bd5-a9f4-43e0-aabf-93ef8eb1db9f'
$WorkspaceKey = 'z5LrKgLgCMzuP7e2ikE8GO64cjldgbnl+kufDrI8SDswE8gL3dm4GWJmVYlLt85Q+irdsmp+tfZlsJGNNbsBeg=='

#$zone = Get-Random -Maximum 3 -Minimum 1
$zone='1'


####################################
#### DONT MODIFY FROM THIS LINE ####
####################################

#Provide the name of the snapshot
$snapshotNameOS = $virtualMachineName + '_mig_OS'

#Provide the name of the OS disk that will be created using the snapshot
$osDiskName = $virtualMachineName + '-OSDisk'


#Set the context to the subscription Id where snapshot exists
Select-AzSubscription -SubscriptionId $sourceSubscriptionId 

# Collect Data
$virtualMachineSize = (Get-AzVM -Name $virtualMachineName).HardwareProfile.VmSize
$dataDisk = (Get-AzVM -ResourceGroupName $sourceResourceGroupName -Name $virtualMachineName).StorageProfile.DataDisks 
$tags = (Get-AzResource -ResourceGroupName $sourceResourceGroupName -Name $virtualMachineName).Tags
$jsonBase = @{}
$jsonBase.Add("VM", $virtualMachineName)
$jsonBase.Add("Size", $virtualMachineSize)
$jsonBase.Add("Disks", $dataDisk)
$jsonBase.Add("Tags", $Tags)
$jsonBase | ConvertTo-Json -Depth 10 | Out-File ".\$virtualMachineName.json"

function Show-Menu {
    param (
        [string]$Title = 'Menu Migrate VMs'
    )
    #Clear-Host
    Write-Host "$virtualMachineName" -ForegroundColor White -BackgroundColor Red
    Write-Host "================ $Title ================"
    
    Write-Host " 1: Presiona  '1' para Desencriptar Discos"
    Write-Host " 2: Presiona  '2' para Apagar VM"
    Write-Host " 3: Presiona  '3' para Crear un Snapshot"
    Write-Host " 4: Presiona  '4' para Crear una VM"
    Write-Host " 5: Presiona  '5' para Añadir discos de datos en la VM"
    Write-Host " 6: Presiona  '6' para Actualizar IP Privada"
    Write-Host " 7: Presiona  '7' para Eliminar la encriptación Dual y Convertir discos en SSD"
    Write-Host " 8: Presiona  '8' para Configurar Monitorización "
    Write-Host " 9: Presiona  '9' para Configurar Antimalware y eliminar BGInfo"
    Write-Host "10: Presiona '10' para Copiar Tags"
    Write-Host "11: Presiona '11' para Elimina el Snapshot del SO"
    Write-Host "12: Presiona '12' para Encriptar Discos"
    Write-Host "13: Presiona '13' para Configurar Backup"
    Write-Host " Q: Presiona  'Q' para salir."
}





function Set-Decrypt {
    #Set the context to the subscription Id where snapshot exists
    Select-AzSubscription -SubscriptionId $sourceSubscriptionId
    ## Desencripta los Discos
    $diskstatus = Get-AzVMDiskEncryptionStatus -ResourceGroupName $sourceResourceGroupName -VMName $virtualMachineName
    if (($diskstatus.OsVolumeEncrypted -ne 'NotEncrypted') -or ($diskstatus.DataVolumesEncrypted -ne 'NotEncrypted')) {
        Start-AzVM -ResourceGroupName $sourceResourceGroupName -Name $virtualMachineName
        Write-Host "Desencriptando discos de la VM: $virtualMachineName" -ForegroundColor Black -BackgroundColor Yellow
        Disable-AzVMDiskEncryption -ResourceGroupName $sourceResourceGroupName -VMName $virtualMachineName -Force

    }
    else {
        Write-Host "Discos desencriptados $virtualMachineName" -ForegroundColor Black -BackgroundColor Green
    }
    
}

function Remove-Dual-Encryption {
    

    $VMState = Read-Host 'Premigración o Migración(p/m)'
    if (($VMState -eq 'p') -or ($VMState -eq 'm')) {
        if ($VMState -eq 'p') {
            $RG = $sourceResourceGroupName
            Select-AzSubscription -SubscriptionId $sourceSubscriptionId     
        }
        else {
            $RG = $targetResourceGroupName
            Select-AzSubscription -SubscriptionId $targetSubscriptionId 
        }
    }
    else {
        exit
    }
    #Apaga la máquina y elimina las configuraciones de encriptación doble
    Stop-AzVM -ResourceGroupName $RG -Name $virtualMachineName -Force
    # Llama a la función para convertir los discos en SSD
    Convert-Managed-Disk

    # Cambia el tipo de encriptación de la VM
    $vm = Get-AzVM -ResourceGroupName $RG -VMName $virtualMachineName
    $vm.StorageProfile.OsDisk.EncryptionSettings = $null

    #Actualiza la VM con la configuración
    $vm | Update-AzVM
    #Muestra la configuración si es correcta. Si no saldría en blanco
    $vm.StorageProfile.OsDisk.EncryptionSettings
    $vm.StorageProfile.OsDisk
     
    #Arranca la VM
    Write-Host "Iniciando la vm: $virtualMachineName" -Foreground Black -BackgroundColor Yellow
    Start-AzVM -ResourceGroupName $RG -Name $virtualMachineName
    
    #Elimina la extensión AzureDiskEncryption
    Write-Host "Eliminando la extensión AzureDiskEncryption" -Foreground Black -BackgroundColor Yellow
    Remove-AzVMExtension -ResourceGroupName $RG -VMName $virtualMachineName -Name AzureDiskEncryption -Confirm

    

}

function Set-ShutDown-VM {
    #Set the context to the subscription Id where snapshot exists
    Select-AzSubscription -SubscriptionId $sourceSubscriptionId
    ############################## SHUTDOWN VM ##############################
    Write-Host "Shutdown " $virtualMachineName -ForegroundColor Black -BackgroundColor Yellow
    Stop-AzVM -ResourceGroupName $sourceResourceGroupName -Name $virtualMachineName -Force
    while ((Get-AzVM -Name $virtualMachineName -ResourceGroupName $sourceresourceGroupName -Status).Statuses[1].DisplayStatus -ne 'VM deallocated') { start-sleep -s 5 }
}

function Add-SnapShot {
    
    Select-AzSubscription -SubscriptionId $sourceSubscriptionId
    ############################## CREATE SNAPSHOT ##############################
    #Obtenemos los datos de la VM
    $vm = Get-AzVM -ResourceGroupName $sourceResourceGroupName -Name $virtualMachineName
    # Y del disco
    $disk = Get-AzDisk -ResourceGroupName $sourceResourceGroupName | Where-Object {$_.Name -like "$virtualMachineName*" -and $_.Name -like "*OS*"}
    

    # Creamos una configuración para el Snapshot del OS
    $snapshot = New-AzSnapshotConfig `
        -SourceUri $vm.StorageProfile.OsDisk.ManagedDisk.Id `
        -Location $location `
        -CreateOption copy `

     
    Write-Host "Haciendo el snapshot de $virtualMachineName" -ForegroundColor Black -BackgroundColor yellow

    # Creamos el snapshot del OS
    New-AzSnapshot `
        -Snapshot $snapshot `
        -SnapshotName $snapshotNameOS `
        -ResourceGroupName $sourceResourceGroupName

    # Obtenemos la información del Snapshot de OS creado.    
    $sourceSnapshotOS= Get-AzSnapshot -ResourceGroupName $sourceResourceGroupName -SnapshotName $snapshotNameOS
    $snapshotOSConfig = New-AzSnapshotConfig -Location $location -CreateOption Copy -SourceResourceId $SourceSnapshotOS.Id

    # Cambiamos de suscripción
    Set-AZContext $targetSubscriptionName
    # Creamos una copia del snapshot en la suscripción de destino.
    New-AzSnapshot -ResourceGroupName $targetResourceGroupName -SnapshotName $snapshotNameOS -Snapshot $snapshotOSConfig



    $jsonBase = @{}
    $jsonBase.Add("SnapShot_OS", "Yes")

    # Ahora a por los discos de datos
    # Volvemos a la suscripción de origen
    Select-AzSubscription -SubscriptionId $sourceSubscriptionId
    # Obtenemos información 
    $sourceSnapshotDisk = $vm.StorageProfile 
    $dataDisks = ($sourceSnapshotDisk.DataDisks).name

    foreach ($datadisk in $datadisks) {
        #Cremos la configuración del snapshot del disco
        Select-AzSubscription -SubscriptionId $sourceSubscriptionId
        $dataDisk = Get-AzDisk -ResourceGroupName $vm.ResourceGroupName -DiskName $datadisk

        Write-Host "Haciendo snapshot de VM $($vm.name) disco de datos $($datadisk.Name)" -ForegroundColor Black -BackgroundColor Yellow
        
        $DataDiskSnapshotConfig = New-AzSnapshotConfig -SourceUri $dataDisk.Id -CreateOption Copy -Location $location
        $snapshotNameData = "$($datadisk.name)_snapshot"
             
        # Creamos el snapshot en origen
        New-AzSnapshot -ResourceGroupName $sourceResourceGroupName -SnapshotName $snapshotNameData -Snapshot $DataDiskSnapshotConfig -ErrorAction Stop 

        # Obtenemos información sobre el snapshot creado
        $sourceSnapshotDataDisk = Get-AzSnapshot -ResourceGroupName $sourceResourceGroupName -SnapshotName $snapshotNameData
        $snapshotDataConfig = New-AzSnapshotConfig -Location $location -CreateOption Copy -SourceResourceId $SourceSnapshotDataDisk.Id
        
        Set-AZContext $targetSubscriptionName
        New-AzSnapshot -ResourceGroupName $targetResourceGroupName -SnapshotName $snapshotNameData -Snapshot $snapshotDataConfig
        Write-host "Finalizado el snapshot de VM $($vm.name) data Disk $($datadisk.Name)" -ForegroundColor Black -BackgroundColor Green
    }

    $jsonBase = @{}
    $jsonBase.Add("SnapShot_Data", "Yes")
    $jsonBase | ConvertTo-Json -Depth 10 | Out-File ".\$virtualMachineName.json" -Append
    Write-Output "VM $($vm.name) Data Disk Snapshots End"
}

#Start-Sleep -Seconds 45
function Move-Snapshot {
    ############################## MOVE SNAPSHOT ##############################
    #Set the context to the subscription Id where snapshot exists
    Select-AzSubscription -SubscriptionId $sourceSubscriptionId
    #Get the source snapshot
    $snapshots = Get-AzSnapshot -ResourceGroupName $sourceResourceGroupName  | Where-Object {$_.Name -like "$virtualMachineName*"}

    $SHId = New-Object System.Collections.Generic.List[System.Object]
    # Recogemos el ID del Snapshot
    foreach ($snap in $snapshots) {
        #Comprueba que el nombre del snaphot contenga el nombre de máquina
        if ($snap.Name -like "$virtualMachineName*")
        {
            #Lista el snapshot
            $snap.Name
            #Añade el ID del Snapshot
            $SHId += (Get-AzResource -ResourceGroupName $sourceResourceGroupName -ResourceName $snap.name).Id
        }
    }

    #Set the context to the subscription Id where snapshot will be copied to
    #If snapshot is copied to the same subscription then you can skip this step
    Select-AzSubscription -SubscriptionId $targetSubscriptionId
    Write-Host "Moving Snapshots to Managed"-ForegroundColor Black -BackgroundColor Green
    foreach ($SH in $SHId) {
        write-host "start the movement of $SH" -ForegroundColor Black -BackgroundColor Yellow
        Move-AzResource -DestinationResourceGroupName $targetResourceGroupName -ResourceId $SH -force 
        write-host "End the movement of $SH" -ForegroundColor Black -BackgroundColor Green
    }

    $jsonBase = @{}
    $jsonBase.Add("SnapShots_Move", "Yes")
    $jsonBase.Add("SnapShots", $snapshots)
    $jsonBase | ConvertTo-Json -Depth 10 | Out-File ".\$virtualMachineName.json" -Append
}

function New-VM-Create {
    ############################## CREATE VM TARGET SUSCRIPTION ##############################
    
    #Obtenemos datos de la VM de Origen
    Select-AzSubscription -SubscriptionId $sourceSubscriptionId
    #Tamaño
    $virtualMachineSize = (Get-AzVM -Name $virtualMachineName -ResourceGroupName $sourceResourceGroupName).HardwareProfile.VmSize
    #Tags y añadimos ES_Alert
    $tags = (Get-AzResource -ResourceGroupName $sourceResourceGroupName -Name $virtualMachineName).Tags
    $tags += @{"ES_Alert" = "CPU,RAM,DISK"}

    #Set the context to the subscription Id where Managed Disk will be created
    Select-AzSubscription -SubscriptionId $targetSubscriptionId

    #Obtiene las propiedades del snapshot
    $snapshot = Get-AzSnapshot -ResourceGroupName $targetResourceGroupName -SnapshotName $snapshotNameOS
    

#    $disk = New-AzDisk -Disk $diskConfig -ResourceGroupName $targetResourceGroupName -DiskName $osDiskName -- REVISAR SI BORRAR

    

    #Chequea si le vamos a pasar un availability set
    if ($AvailabilitySet -eq "s") {
        #Pide el nombre del Availability Set
        $AvailabilitySetName = Read-Host 'Indica el nombre del Availability Set'

        #Lo transforma en un ID para pasarselo como parametro a la creación de la VM
        $AvailabilitySetID = Get-AzAvailabilitySet -name $AvailabilitySetName

        #Obtiene la configuración del disco de SO desde el snapshot
        $diskConfig = New-AzDiskConfig -Location $location -SourceResourceId $snapshot.Id -CreateOption Copy -SkuName $snapshot.Sku.Name
        $disk = New-AzDisk -Disk $diskConfig -ResourceGroupName $targetResourceGroupName -DiskName $osDiskName

        #Initialize virtual machine configuration
        $VirtualMachine = New-AzVMConfig -VMName $virtualMachineName -VMSize $virtualMachineSize -AvailabilitySetId $AvailabilitySetID.ID
        }
    else {
        #Obtiene la configuración del disco de SO desde el snapshot
        $diskConfig = New-AzDiskConfig -Location $location -SourceResourceId $snapshot.Id -CreateOption Copy -Zone $zone -SkuName $snapshot.Sku.Name
        $disk = New-AzDisk -Disk $diskConfig -ResourceGroupName $targetResourceGroupName -DiskName $osDiskName

        #Initialize virtual machine configuration
        $VirtualMachine = New-AzVMConfig -VMName $virtualMachineName -VMSize $virtualMachineSize -Zone $zone
             
    }
    



    #Use the Managed Disk Resource Id to attach it to the virtual machine. Please change the OS type to linux if OS disk has linux OS
    $VirtualMachine = Set-AzVMOSDisk -VM $VirtualMachine -ManagedDiskId $disk.Id -CreateOption Attach -Windows

    #Get the subnet where virtual machine will be hosted
    $vsubnetName = (Get-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName 'AzureVnet').Subnets

    foreach ($subnet in $vsubnetName) {
        if ($subnet.name -eq $targetsubnetName) {
            $subnetId = $subnet.Id
            Write-Host $subnetId -ForegroundColor Black -BackgroundColor DarkCyan
        }
    }

    #Selecciona el DNS Server según el dominio
    switch ($Domain) {
            insim.biz    {$DNSServer = "10.206.133.71"}
            ldap.pro     {$DNSServer = "10.162.2.253"}
            ldapt.nne.es {$DNSServer = "10.162.205.246"}
            nne.es       {$DNSServer = "10.162.2.244"}
        }

    # Create NIC in the first subnet of the virtual network
    $nic = New-AzNetworkInterface -Name ($VirtualMachineName.ToLower() + '_nic') -ResourceGroupName $targetResourceGroupName -Location $location -SubnetId $subnetId -DnsServer $DNSServer



    $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $nic.Id

    #Create the virtual machine with Managed Disk
    Write-Host "Creando la VM: $virtualMachineName" -ForegroundColor Black -BackgroundColor Yellow
    New-AzVM -VM $VirtualMachine -ResourceGroupName $targetResourceGroupName -Location $location

    #Añade los tags
    Set-AzResource -ResourceGroupName $targetResourceGroupName -Name $virtualMachineName -ResourceType "Microsoft.Compute/VirtualMachines" -Tag $tags -Force

    $jsonBase = @{}
    $jsonBase.Add("CreateVM", "Yes")
    $jsonBase | ConvertTo-Json -Depth 10 | Out-File ".\$virtualMachineName.json" -Append

    Update-PrivateIP

    
}

function New-VM-From-Image {
    #### DEPRECADO ####
    #Crea la VM con un disco desde el marketplace de Azure. Posteriormente hay que hacer swap y eliminar el disco creado.
    #Credenciales de la VM
    $Username = "secmaster"
    $Password = 'N4t10n4l320!)' | ConvertTo-SecureString -Force -AsPlainText
    $Credential = New-Object -TypeName PSCredential -ArgumentList ($Username, $Password)

    #Obtenemos datos de la VM de Origen
    Select-AzSubscription -SubscriptionId $sourceSubscriptionId
    #Tamaño
    $virtualMachineSize = (Get-AzVM -Name $virtualMachineName -ResourceGroupName $sourceResourceGroupName).HardwareProfile.VmSize
    #Tags y añadimos ES_Alerts
    $tags = (Get-AzResource -ResourceGroupName $sourceResourceGroupName -Name $virtualMachineName).Tags
    $tags += @{"ES_Alerts" = "CPU,RAM,DISK"}

    #Vamos a la suscripción de destino
    Select-AzSubscription -SubscriptionId $targetSubscriptionId
    
    #Revisamos si hemos pasado el parametro del avalilability set
    if ($AvailabilitySet -eq "s") {
        #Pide el nombre del Availability Set
        $AvailabilitySetName = Read-Host 'Indica el nombre del Availability Set'

        #Lo transforma en un ID para pasarselo como parametro a la creación de la VM
        $AvailabilitySetID = Get-AzAvailabilitySet -name $AvailabilitySetName

        #Creamos configuración de la máquina virtual con el nombre, el tamaño y con el parametro del availability set
        $VirtualMachine = New-AzVMConfig -VMName $virtualMachineName -VMSize $virtualMachineSize -AvailabilitySetId $AvailabilitySetID.ID
        }
    else {
        #Creamos configuración de la máquina virtual con el nombre, el tamaño y con el parametro de la zona
        $VirtualMachine = New-AzVMConfig -VMName $virtualMachineName -VMSize $virtualMachineSize -Zone $zone
             
    }
    
    #El SO, el nombre, el agente, credenciales
    $VirtualMachine = Set-AzVMOperatingSystem  -VM $virtualMachine -Windows -ComputerName $virtualMachineName -ProvisionVMAgent -EnableAutoUpdate -Credential $Credential
    #Configuramos la imagen de la máquina
    $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2022-datacenter' -Version latest
    #Configuramos el nombre del disco del SO
    $VirtualMachine = Set-AzVMOSDisk -VM $VirtualMachine -Name ($virtualMachineName.TOLower() + '-OSImage') -CreateOption "FromImage" -Windows


    #Get the subnet where virtual machine will be hosted
    $vsubnetName = (Get-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName 'AzureVnet').Subnets

    foreach ($subnet in $vsubnetName) {
        if ($subnet.name -eq $targetsubnetName) {
            $subnetId = $subnet.Id
            Write-Host $subnetId -ForegroundColor DarkCyan
        }
    }

    # Create NIC in the first subnet of the virtual network
    $nic = New-AzNetworkInterface -Name ($VirtualMachineName.ToLower() + '_nic') -ResourceGroupName $targetResourceGroupName -Location $location -SubnetId $subnetId -DnsServer $DNSServer


    #Añadimos a la configuración la NIC
    $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $nic.Id

    #Creamos la VM con toda la configuración que hemos cargado
    Write-Host "Creando la VM: $virtualMachineName" -ForegroundColor Black -BackgroundColor Yellow
    New-AzVM -VM $VirtualMachine -ResourceGroupName $targetResourceGroupName -Location $location -DisableBginfoExtension
    
    #Añadimos las Tags a la máquina
    Set-AzResource -ResourceGroupName $targetResourceGroupName -Name $virtualMachineName -ResourceType "Microsoft.Compute/VirtualMachines" -Tag $tags -Force
    Write-Host "Creada la VM: $virtualMachineName" -ForegroundColor Black -BackgroundColor Green

        
}

function Swap-OSDisk {
    #Hace un disco del snapshot orginal de la máquina origen y posteriomente lo swapea en la máquina
    #Set the context to the subscription Id where Managed Disk will be created
    Select-AzSubscription -SubscriptionId $targetSubscriptionId

    #Obtiene las propiedades del snapshot
    $snapshot = Get-AzSnapshot -ResourceGroupName $targetResourceGroupName -SnapshotName $snapshotNameOS
    $diskConfig = New-AzDiskConfig -Location $location -SourceResourceId $snapshot.Id -CreateOption Copy -Zone $zone

    #Creamos el disco de SO
    $disk = New-AzDisk -Disk $diskConfig -ResourceGroupName $targetResourceGroupName -DiskName $osDiskName
    
    #Seleccionamos el disco creado
    $OSDisk= Get-AzDisk -ResourceGroupName $targetResourceGroupName -DiskName $osDiskName
    Write-Host "Cambiando el disco de sistema a: $osdiskName" -ForegroundColor Black -BackgroundColor Yellow

    #Seleccionamos la VM
    $vm = Get-AzVM -ResourceGroupName $targetResourceGroupName -Name $virtualMachineName
    Write-Host "Parando la VM: $virtualMachineName" -BackgroundColor RED -ForegroundColor BLACK

    #Paramos la VM
    Stop-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Force

    #Cambiamos el disco
    Set-AzVMOSDisk -VM $vm -ManagedDiskId $OSDisk.Id -Name $OSDisk.Name
    Update-AzVM -ResourceGroupName $targetResourceGroupName -VM $vm
    Write-Host "Cambiado el disco de sistema a: $osdiskName" -ForegroundColor Black -BackgroundColor Green

    #Arrancamos la máquina
    Start-AzVM -Name $vm.name -ResourceGroupName $vm.ResourceGroupName -NoWait
    Write-Host "Arrancando la VM: $virtualMachineName" -BackgroundColor Green -ForegroundColor Black
    

}

function Set-Attach-Data-Disk {
    #Set the context to the subscription Id where Managed Disk will be created
    Select-AzSubscription -SubscriptionId $targetSubscriptionId
    $lun = 0
    #Obtiene los snapshots que se llamen nombredela máquina_snapshot
    $Datasnapshots = Get-AzSnapshot -ResourceGroupName $targetResourceGroupName| Where-Object {$_.Name -like "$virtualMachineName*" -and $_.Name -like "*snapshot"}
    foreach ($datasnap in $Datasnapshots) {
        $dataname = $datasnap.Name -replace "_snapshot"
        #comprueba si usa availability set
        if ($AvailabilitySet -eq "s") {
            $diskConfig = New-AzDiskConfig -Location $location -SourceResourceId $datasnap.Id -CreateOption "Copy"
        }
        else {
            #si no usa availability sets, lo crea en una zona.
            $diskConfig = New-AzDiskConfig -Location $location -SourceResourceId $datasnap.Id -CreateOption "Copy" -Zone $zone
        }
        $disk = New-AzDisk -Disk $diskConfig -ResourceGroupName $targetResourceGroupName -DiskName $dataname
        $vm = Get-AzVM -Name $virtualMachineName -ResourceGroupName $targetResourceGroupName
        $vm = Add-AzVMDataDisk -VM $vm -Name $disk.Name -CreateOption Attach -ManagedDiskId $disk.Id -Lun $lun
        Write-Host "Agregando disco de datos: $dataname" -BackgroundColor Yellow -ForegroundColor Black
        Update-AzVM -VM $vm -ResourceGroupName $targetResourceGroupName
        $lun++
        $checkdisk = Get-AzDisk -ResourceGroupName $targetResourceGroupName -DiskName $dataname 
        if ($checkdisk.Name -eq $dataname) {
            Remove-AzSnapshot -ResourceGroupName $targetResourceGroupName -SnapshotName $datasnap.Name -Force
            Write-Host "Agregado disco de datos: $dataname" -BackgroundColor Green -ForegroundColor Black

        }
        
    }

}

function Set-EncrypDisk {
    #Set the context to the subscription Id where Managed Disk will be created
    Select-AzSubscription -SubscriptionId $targetSubscriptionId


    #Obtenemos el keyvault
    $KeyVault = Get-AzKeyVault -VaultName $KeyVaultName -ResourceGroupName COMMON-INFRA-RG

    Set-AzVMDiskEncryptionExtension -ResourceGroupName $targetResourceGroupName -VMName $virtualMachineName -DiskEncryptionKeyVaultUrl $KeyVault.VaultUri -DiskEncryptionKeyVaultId $KeyVault.ResourceId -force

<#    $KeyVaultResourceId = $KeyVault.ResourceId
    $KeyVaultVaultUrl = $KeyVault.VaultUri
    $KeyEncryptionKeyUrl = (Get-AzKeyVaultKey -VaultName $KeyVaultName -Name $KeyName).Key.Kid
    Set-AzVMDiskEncryptionExtension -ResourceGroupName $targetResourceGroupName `
                                    -VMName $virtualMachineName `
                                    -DiskEncryptionKeyVaultUrl $KeyVaultVaultUrl `
                                    -DiskEncryptionKeyVaultId $KeyVaultResourceId `
                                    -KeyEncryptionKeyUrl $keyEncryptionKeyUrl `
                                    -KeyEncryptionKeyVaultId $KeyVaultResourceId
                                   
#>
    Get-AzVmDiskEncryptionStatus -VMName $virtualMachineName -ResourceGroupName $targetResourceGroupName
}

function Set-Backup {
    #Set the context to the subscription Id where Managed Disk will be created
    set-Azcontext -Subscription $targetSubscriptionName
    if ($targetSubscriptionName -eq 'ESNN-DTA-01') {
        $BackUpVaultID = '/subscriptions/7344430c-4d3f-4d2a-865d-664f842b68c0/resourceGroups/COMMON-INFRA-RG/providers/Microsoft.RecoveryServices/vaults/BackupVMs-DTA'
        
        Show-Menu-BK-DTA
        $switchmenu = Read-Host "Please make a selection"
        switch ($switchmenu) {
            '1' {
                $BackupPolicyName = "Non-Production"
            }
            '2' {
                $BackupPolicyName = "Non-Production-GestionIT"
            }
            '3' {
                $BackupPolicyName = "Production-GestionIT"
            }
        }
     Clear-Host
     }
    else {
        Show-Menu-BK-PRO
        $vaultName = 'Backup-PRO'
        $BackUpVaultID = '/subscriptions/d1345562-ef63-477c-93f1-f75ee71d487f/resourceGroups/COMMON-INFRA-RG/providers/Microsoft.RecoveryServices/vaults/BackupVMs-ZR-PRO' 
        $switchmenu = Read-Host "Please make a selection"
        switch ($switchmenu) {
            '1' {
                $BackupPolicyName = "VM-Backup-VM-SQL-Non-Weekend"
            }
            '2' {
                $BackupPolicyName = "AllwaysON"
            }
            '3' {
                $BackupPolicyName = "VM-DailyPolicy"
            }
            '4' {
                $BackupPolicyName = "VM-Non-Production-GestionIT"
            }
            '5' {
                $BackupPolicyName = "VM-Production-FileServer-VM"
            }
            '6' {
                $BackupPolicyName = "VM-Production-GestionIT"
            }
            '7' {
                $BackupPolicyName = "VM-Production-Web-App"
            }
            '8' {
                $BackupPolicyName = "VM-SQL-PRO-Weekend"
            }
        }
    }
    
    $targetVault = Get-AzRecoveryServicesVault -ResourceGroupName "COMMON-INFRA-RG" -Name $vaultName
    $BKPol = Get-AzRecoveryServicesBackupProtectionPolicy -Name $BackupPolicyName -VaultId $BackUpVaultID
    Write-Host "Configurando la copia de seguridad de $virtualmachineName" -ForegroundColor Black -BackgroundColor Yellow
    Enable-AzRecoveryServicesBackupProtection -Policy $BKPol -Name $virtualMachineName -ResourceGroupName $targetResourceGroupName -VaultId $BackUpVaultID
    Write-Host "Configurada la copia de seguridad de $virtualmachineName" -ForegroundColor Black -BackgroundColor Green
    
}

function Set-Monitoring {
    #Set the context to the subscription Id where Managed Disk will be created
    Select-AzSubscription -SubscriptionId $targetSubscriptionId
    # Global
    $Location = 'westeurope'
    $AutomaticUpdate = $false
    # Windows
    $WindowsExtensionName = 'MicrosoftMonitoringAgent'
    $WindowsPublisher = 'Microsoft.EnterpriseCloud.Monitoring'
    $WindowsExtensionType = 'MicrosoftMonitoringAgent'
    $WindowsTypeHandlerVersion = '1.0'
    # Log Analytics
    $PublicSettings = @{"workspaceId" = $WorkspaceID }
    $ProtectedSettings = @{"workspaceKey" = $WorkspaceKey }
    Set-AzVMExtension `
        -Name $WindowsExtensionName `
        -VMName $virtualMachineName `
        -ResourceGroupName $targetResourceGroupName `
        -Location $Location `
        -Publisher $WindowsPublisher `
        -ExtensionType $WindowsExtensionType `
        -TypeHandlerVersion $WindowsTypeHandlerVersion `
        -Settings $PublicSettings `
        -ProtectedSettings $ProtectedSettings `
        -EnableAutomaticUpgrade $AutomaticUpdate
    
    # Dependency Agent
    Set-AzVMExtension `
        -Name 'DependencyAgentWindows' `
        -VMName $virtualMachineName `
        -ResourceGroupName $targetResourceGroupName `
        -Location $Location `
        -Publisher 'Microsoft.Azure.Monitoring.DependencyAgent' `
        -ExtensionType 'DependencyAgentWindows' `
        -TypeHandlerVersion '9.10' `
        -EnableAutomaticUpgrade $true
}

function Set-AntiMalware {
    Select-AzSubscription -SubscriptionId $targetSubscriptionId
    # Enable Antimalware with default policies
    $settingString = '{"AntimalwareEnabled": true}';
    # Enable Antimalware with custom policies
    # $settingString = '{
    # "AntimalwareEnabled": true,
    # "RealtimeProtectionEnabled": true,
    # "ScheduledScanSettings": {
    #                             "isEnabled": true,
    #                             "day": 0,
    #                             "time": 120,
    #                             "scanType": "Quick"
    #                             },
    # "Exclusions": {
    #            "Extensions": ".ext1,.ext2",
    #                  "Paths":"",
    #                  "Processes":"sampl1e1.exe, sample2.exe"
    #             },
    # "SignatureUpdates": {
    #                               "FileSharesSources": "",
    #                               "FallbackOrder": "",
    #                               "ScheduleDay": 0,
    #                               "UpdateInterval": 0,
    #                       },
    # "CloudProtection": true         
    #
    # }';

    # retrieve the most recent version number of the extension
    $allVersions = (Get-AzureRmVMExtensionImage -Location $location -PublisherName "Microsoft.Azure.Security" -Type "IaaSAntimalware").Version
    $versionString = $allVersions[($allVersions.count) - 1].Split(".")[0] + "." + $allVersions[($allVersions.count) - 1].Split(".")[1]
    Set-AzVMExtension `
        -ResourceGroupName $targetResourceGroupName `
        -Location $location `
        -VMName $virtualMachineName `
        -Name "IaaSAntimalware" `
        -Publisher "Microsoft.Azure.Security" `
        -ExtensionType "IaaSAntimalware" `
        -TypeHandlerVersion $versionString `
        -SettingString $settingString

    Set-AzVMExtension `
        -Publisher 'Microsoft.GuestConfiguration' `
        -Type 'ConfigurationforWindows' `
        -Name 'AzurePolicyforWindows' `
        -TypeHandlerVersion 1.0 `
        -ResourceGroupName $targetResourceGroupName `
        -Location $location `
        -VMName $virtualMachineName `
        -EnableAutomaticUpgrade $true

    #Elimina la extensión BGInfo
    Write-Host "Eliminando la extensión BGInfo" -Foreground Black -BackgroundColor Yellow
    Remove-AzVMExtension -ResourceGroupName $targetResourceGroupName -VMName $virtualMachineName -Name BGInfo -Force

}

function Update-PrivateIP {
    
    #Set the variables 
    $NetInter=$virtualMachineName + '_nic'
    #$PrivateIP = "10.162.204.71"
    Select-AzSubscription -SubscriptionId $targetSubscriptionId

    #Check whether the new IP address is available in the virtual network.
    Get-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $ResourceGroupVNet | Test-AzPrivateIPAddressAvailability -IPAddress $PrivateIP

    #Add/Change static IP. This process will change MAC address
    $virtualNetworkName = Get-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $ResourceGroupVNet

    $targetsubnetName = Get-AzVirtualNetworkSubnetConfig -Name $targetsubnetName -VirtualNetwork $virtualNetworkName

    $nic = Get-AzNetworkInterface -Name  $NetInter -ResourceGroupName  $targetResourceGroupName

    $nic | Set-AzNetworkInterfaceIpConfig -Name ipconfig1 -PrivateIpAddress $PrivateIP -Subnet $targetsubnetName -Primary

    $nic | Set-AzNetworkInterface

    Write-Host "Fijada la IP de $virtualMachineName" -BackgroundColor Green -ForegroundColor Black

    #Añade los DNS a la nic
    Write-Host "Actualizando servidores DNS" -BackgroundColor Yellow -ForegroundColor Black
    switch ($Domain) {
        "insim.biz" {
            $nic.dnsSettings.DNSServers.Add("10.160.51.5")
            $nic.dnsSettings.DNSServers.Add("10.160.51.6")
            $nic | Set-AzNetworkInterface
            }
        "ldap.pro" {
            $nic.dnsSettings.DNSServers.Add("10.162.2.252")
            $nic | Set-AzNetworkInterface
            }
        "ldapt.nne.es" {
            $nic.dnsSettings.DNSServers.Add("10.162.205.245")
            $nic | Set-AzNetworkInterface
            }
        }
    $nic.DnsSettings
    Write-Host "Añadidos los DNS a la NIC. Reinicia la vm para que se apliquen" -BackgroundColor Green -ForegroundColor Black




}

function Copy-Tags {
#Obtiene los tags
Select-AzSubscription -SubscriptionId $SourceSubscriptionId
$tags=(get-azvm -ResourceGroupName $sourceResourceGroupName  -Name $virtualMachineName).tags

#Los copia a la vm de destino
Select-AzSubscription -SubscriptionId $targetSubscriptionId
$vm = Get-azvm -ResourceGroupName $targetResourceGroupName -Name $virtualMachineName
Update-AzTag -ResourceId $vm.Id -Tag $tags -Operation Merge
(Get-AzResource -ResourceGroupName $targetResourceGroupName -Name $virtualMachineName).Tags


}

function Show-Menu-BK-DTA{
param (
        [string]$Title = 'Backup Policies for ESNN-DTA-01'
    )
    #Clear-Host
    Write-Host "================ $Title ================"
    
    Write-Host "1: Press '1' for Non-Production"
    Write-Host "2: Press '2' for Non-Production-GestionIT"
    Write-Host "3: Press '3' for Production-GestionIT"
    Write-Host "Q: Press 'Q' to quit."
   
}

function Show-Menu-BK-PRO{
    param (
            [string]$Title = 'Backup Policies for ESNN-PROD-01'
        )
        #Clear-Host
        Write-Host "================ $Title ================"
        
        Write-Host " 1: Press  '1' for VM-Backup-VM-SQL-Non-Weekend"
        Write-Host " 2: Press  '2' for AllwaysON"
        Write-Host " 3: Press  '3' for VM-DailyPolicy"
        Write-Host " 4: Press  '4' for VM-Non-Production-GestionIT"
        Write-Host " 5: Press  '5' for VM-Production-FileServer-VM"
        Write-Host " 6: Press  '6' for VM-Production-GestionIT"
        Write-Host " 7: Press  '7' for VM-Production-Web-App"
        Write-Host " 8: Press  '8' for VM-SQL-PRO-Weekend"
        Write-Host "Q: Press 'Q' to quit."
       
    }

function Get-LettersDisk {

    $diskDrives = Get-CimInstance -Class Win32_DiskDrive  | Sort-Object -Property DeviceID
    $diskDriveToDiskPartitionMappings = Get-CimInstance -Class Win32_DiskDriveToDiskPartition 
    $diskPartitions = Get-CimInstance -Class Win32_DiskPartition 
    $logicalDiskToPartitionMappings = Get-CimInstance -Class Win32_LogicalDiskToPartition 
    $logicalDisks = Get-CimInstance -Class Win32_LogicalDisk
}

function Remove-Snapshot {
    Select-AzSubscription -SubscriptionId $targetSubscriptionId
    #Eliminamos la imagen creada al crear la máquina
    <#Se creo para las pruebas del DSC
    $OsDiskNAme = get-azdisk -ResourceGroupName $targetresourcegroupname -DiskName ($virtualMachineName.TOLower() + '-OSImage') -Verbose
    Write-Host "Eliminando Disco de SO $OsDiskName" -ForegroundColor Black -BackgroundColor Yellow
    Remove-AzDisk -ResourceGroupName $targetResourceGroupName -DiskName ($virtualMachineName.TOLower() + '-OSImage')
    Write-Host "Eliminado Disco de SO $OsDiskName" -ForegroundColor Black -BackgroundColor Green
    #>
    
    #Eliminamos el Snapshot del SO en destino
    Write-Host "Eliminando Snapshot $snapshotNameOS" -ForegroundColor Black -BackgroundColor Yellow
    Remove-AzSnapshot -ResourceGroupName $targetResourceGroupName -SnapshotName $snapshotNameOS -Force
    Write-Host "Eliminado Snapshot $snapshotNameOS" -ForegroundColor Black -BackgroundColor Green

    # Llamamos a la función de eliminar locks en los RG
    Remove-Lock-RG

    # Vamos al origen y revisamos si existe algún snapshot con el nombre de la VM. Si es así los elimina.
    Set-AzContext $SourceSubscriptionName
    $SourceSnapshots = Get-AzSnapshot -ResourceGroupName $sourceResourceGroupName | Where-Object {$_.Name -like "$virtualMachineName*"}
    foreach ($snap in $SourceSnapshots){
        Write-Host "Eliminando Snapshot $($snap.Name)" -ForegroundColor Black -BackgroundColor Yellow
        Remove-AzSnapshot -ResourceGroupName $sourceResourceGroupName -SnapshotName $snap.Name -Force
        Write-Host "Eliminado Snapshot $($snap.Name)" -ForegroundColor Black -BackgroundColor Green
    }



}

function Remove-Lock-RG {

    # Get the Resource Group Lock for Alerts
    Set-AzContext $SourceSubscriptionName
    $RGLock = Get-AzResourceLock -ResourceGroupName $sourceResourceGroupName -LockName "NoDelete" -ErrorAction SilentlyContinue
    # If there is NO lock on the Resource Group
    if ($null -eq $RGLock) {
        # Write to console
        Write-Output "No hay locks en el RG: $sourceResourceGroupName"
    }else {
        # Write to console
        Write-Output "Eliminando el lock en el RG: $sourceResourceGroupName"
        # Remove the Resource Lock on the Resource Group the VM is located in
        Remove-AzResourceLock -LockName "NoDelete" -ResourceGroupName $sourceResourceGroupName -Force
    }
}

function Convert-Managed-Disk {

    Write-Host "Cambiando todos los discos a SSD" -ForegroundColor Black -BackgroundColor Yellow
    # Fijo el tipo de disco a Standard SSD
    $storageType= 'StandardSSD_LRS'

    # Cambio de suscripción
    Set-AzContext $targetSubscriptionName

    # Obtenemos todos los discos que hay en el RG de destino y los filtramos
    $vm = Get-azvm -ResourceGroupName $targetResourceGroupName -Name $virtualMachineName
    $vmDisks = Get-AzDisk -ResourceGroupName $targetResourceGroupName | Where-Object {$_.Name -like "$virtualMachineName*"}

    # Cambiamos el tamaño de todos los discos y nos aseguramos de que el disco pertenece a la VM
    foreach ($disk in $vmDisks) {
        if ($disk.ManagedBy -eq $vm.Id)
        {
            $disk.Sku = [Microsoft.Azure.Management.Compute.Models.DiskSku]::new($storageType)
            $disk | Update-AzDisk
        }
    }
    Write-Host "Actualizados todos los discos" -ForegroundColor Black -BackgroundColor Green
    
}

do {
    Show-Menu
    $selection = Read-Host "Please make a selection"
    switch ($selection) {
         '1' {
            Set-Decrypt
        } '2' {
            Set-ShutDown-VM
        } '3' {
            Add-SnapShot
        } '4' {
            New-VM-Create
        } '5' {
            Set-Attach-Data-Disk
        } '6' {
            Update-PrivateIP
        } '7' {
            Remove-Dual-Encryption
        } '8' {
            Set-Monitoring
        } '9' {
            Set-AntiMalware
        }'10' {
            Copy-Tags
        }'11' {
            Remove-Snapshot
        }'12' {
            Set-EncrypDisk
        }'13' {
            Set-Backup
        } 
            

    }

}
until ($selection -eq 'q')

