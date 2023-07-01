#Use this script to stop and start an Azure firewall to save money. 
#NOTE: When the firewall resource is stopped, routing will not work properly between resources connect to it. 
#
#
#Andrew Schwalbe 6/13/22

#Declare variables
$FWName = "FIREWALL NAME"
$RGName = "RESOURCE GROUP NAME"
$PubIPName1 = "TEST-FW-PIP"
#$PubIPName2 = "TEST-FW-PIP2"  ##if using more than one PiP
$VNetName = "FW Vnet Name"

######Stop the Firewall
$azfw = Get-AzFirewall -Name $FWName -ResourceGroupName $RGName
$azfw.Deallocate()
Set-AzFirewall -AzureFirewall $azfw

#######Start the Firewall
$azfw = Get-AzFirewall -Name $FWName -ResourceGroupName $RGName
$vnet = Get-AzVirtualNetwork -ResourceGroupName $RGName -Name $VNetName
$publicip1 = Get-AzPublicIpAddress -Name $PubIPName1 -ResourceGroupName $RGName 
#$publicip2 = Get-AzPublicIpAddress -Name $PubIPName2 -ResourceGroupName $RGName 
$azfw.Allocate($vnet,@($publicip1))
#$azfw.Allocate($vnet,@($publicip1,$publicip2)) ##If using more than one PiP

Set-AzFirewall -AzureFirewall $azfw