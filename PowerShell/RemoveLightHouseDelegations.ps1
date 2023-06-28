###############################################################
#You may use this script to easily list the resource groups per subscription, and programmatically remove the delegation based on user input. 
#
#Notes on using the script: 
#
#The script will accept a list of subscription ids as input at the command line (separated by commas), OR, a text file with a list of subscription IDs within it. 
#For each subscription, it reads the delegations and outputs on the screen, then asks if you want to remove them.
#As written, the code will remove BOTH resource group and subscription-level assignments. Adjust the code as needed to ignore subscription-level assignments. 
#This code is provided AS IS and as an example only. 
#
# Published at: https://techcommunity.microsoft.com/t5/azure-tools-blog/use-powershell-to-remove-lighthouse-delegations-based-on/ba-p/3741542
###############################################################
Param (
    [Parameter()]
    [String[]] 
    $subIdsFromParams,

    [Parameter()]
    [String]
    $inputFile = "InputSubscriptionIds.txt"
)
[String[]] $subscrpitionIDs
try {
    if($null -ne $subIdsFromParams){
        $subscrpitionIDs = $subIdsFromParams
    }elseif ($null -ne $inputFile) {
        $subscrpitionIDs = Get-Content -Path "$inputFile"
    } 
}
catch {
    Write-Host "Error Reading in Subscription IDs from parameters or file." -ForegroundColor Red
    Exit
}
if ($null -ne $subscrpitionIDs){
    foreach ($subId in $subscrpitionIDs)
    {
        try {
            $managedServicesAssignments =  Get-AzManagedServicesAssignment -Scope "/subscriptions/$subId/"
            Write-Host
            Write-Host "The following" $managedServicesAssignments.count.tostring() "resource group and subscription assignments were found for subscription ${subId}:" -ForegroundColor Yellow
            foreach ($assignment in $managedServicesAssignments){
                if ($null -ne $assignment.ResourceGroupName){
                    Write-Host $assignment.ResourceGroupName -ForegroundColor Green
                }else{
                    Write-Host "$subId - Subscription Level Assignment" -ForegroundColor Green
                }
            }
            Write-Host "----------------------------------------------------------------------------------------"
            $delete = Read-Host "Do you wish to remove these delegations?  ***This action is not reversable!***  Y/N"
            Write-Host "----------------------------------------------------------------------------------------"
            if ($delete -eq "Y"){
                foreach ($assignment in $managedServicesAssignments){
                    if ($null -ne $assignment.ResourceGroupName){
                        $rgName = $assignment.ResourceGroupName
                        Write-Host "Removing Resource Group Delegate" $assignment.Id -ForegroundColor Yellow
                        Remove-AzManagedServicesAssignment -Name $assignment.Name -Scope "/subscriptions/${subId}/resourceGroups/${rgName}"
                    }else {
                        Write-Host "Removing Subscription Delegate" $assignment.Id -ForegroundColor Yellow
                        Remove-AzManagedServicesAssignment -Name $assignment.Name -Scope "/subscriptions/${subId}"
                    }
                }
                Write-Host "Completed" -ForegroundColor Blue
            }
        }
        catch {
            Write-Host "Error reading in subscription ID" $subId
        }#end try/catch
    }#end foreach subscriptionID
}else{
    Write-Host "Input subscriptionIds array was null" -ForegroundColor Red
}