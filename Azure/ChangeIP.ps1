#Set the variables 
$SubscriptionName= "SusbcriptionName"
$ResourceGroup = "RGVnet"
$NetInter="NICName"
$VNET = "VNetName"
$subnet= "SubnetName"
$PrivateIP = "10.162.3.139"
$ResourceGroupVM = "RGVM"


Set-Azcontext $SubscriptionName

#Check whether the new IP address is available in the virtual network.
Get-AzVirtualNetwork -Name $VNET -ResourceGroupName $ResourceGroup | Test-AzPrivateIPAddressAvailability -IPAddress $PrivateIP

#Add/Change static IP. This process will change MAC address
$vnet = Get-AzVirtualNetwork -Name $VNET -ResourceGroupName $ResourceGroup

$subnet = Get-AzVirtualNetworkSubnetConfig -Name $subnet -VirtualNetwork $vnet

$nic = Get-AzNetworkInterface -Name  $NetInter -ResourceGroupName  $ResourceGroupVM

#Remove the PublicIpAddress parameter if the VM does not have a public IP.
$nic | Set-AzNetworkInterfaceIpConfig -Name ipconfig1 -PrivateIpAddress $PrivateIP -Subnet $subnet -Primary

$nic | Set-AzNetworkInterface
