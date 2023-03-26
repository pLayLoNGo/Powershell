#Mejorar

Set-Azcontext SUBSCRIPTION1
$vnet = Get-AzureRmVirtualNetwork -Name 'VNET-NAME' -ResourceGroupName 'RG-VNET'

$networkID = "10.162.0."
For ($i=96; $i -lt 127; $i++)
{     $IP = $networkID + $i
     $Address = Test-AzureRmPrivateIPAddressAvailability -VirtualNetwork $vnet -IPAddress $IP
If ($Address.Available –eq $False) { Write-Host "$IP no está disponible" -ForegroundColor Red }
else { Write-Host "$IP esta disponible" -ForegroundColor Green}
}
