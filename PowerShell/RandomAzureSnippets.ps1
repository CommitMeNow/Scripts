#Return all azure ARM based CPU SKUs in all regions
Get-AzComputeResourceSku | Where-Object{ ($_.Name -like "*pls*") -or ($_.Name -like "*pld*")} | Sort-Object Locations, Name


#Determine Hybrid Benefit use for Virtual Machines andV irtual Machine Scale Sets:
#VM
Get-AzVM | Where-Object {$_.LicenseType -like "Windows_Server"} | Select-Object ResourceGroupName, Name, LicenseType
#VMSS
Get-AzVmss | Select-Object * -ExpandProperty VirtualMachineProfile | Where-Object {$_.LicenseType -like "Windows_Server"} | Select-Object ResourceGroupName, Name, LicenseType