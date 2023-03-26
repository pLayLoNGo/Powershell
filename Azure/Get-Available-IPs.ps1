<#
.SYNOPSIS
Indica si la IP está libre

.DESCRIPTION 
Revisa si en un rango de red hay IPs libres.

.NOTES
File Name : Get-Available-IPs.ps1
Author    : Borja Terres
Version   : 1.1
Date      : 10-octubre-2022
Update    : 26-marzo-2023
Requires  : PowerShell 5.1 or PowerShell 7.1.x (Core)
Module    : Azure Az, Az Network
OS        : Windows
 
#>

Param (

    [Parameter(Position = 0, Mandatory = $True, HelpMessage = 'Nombre de la suscripción')]
    [String]$Subscription ,

    [Parameter(Position = 1, Mandatory = $true, HelpMessage = 'Nombre de la VNet')]
    [String]$VNetName,

    [Parameter(Position = 2, Mandatory = $true, HelpMessage = 'Nombre del RG de la VNet')]
    [String]$VNetRG

    [Parameter(Position = 3, Mandatory = $true, HelpMessage = 'Rango de red de la subnet. X ejemplo 10.162.0.')]
    [String]$SubnetRange

    [Parameter(Position = 4, Mandatory = $true, HelpMessage = 'IP de inicio de la subnet. X ejemplo de 10.162.0.1 sería 1')]
    [String]$IPStart

    [Parameter(Position = 5, Mandatory = $true, HelpMessage = 'IP final de la subnet. X ejemplo de 10.162.0.255 sería 255')]
    [String]$IPEnd
)



Set-Azcontext $Subscription
$vnet = Get-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $VNetRG

# Bucle que busca si está libre
For ($i=$IPStart; $i -lt $IPEnd; $i++)
{     $IP = $SubnetRange + $i
     $Address = Test-AzPrivateIPAddressAvailability -VirtualNetwork $vnet -IPAddress $IP
If ($Address.Available –eq $False) { Write-Host "$IP no está disponible" -ForegroundColor Red }
else { Write-Host "$IP esta disponible" -ForegroundColor Green}
}
