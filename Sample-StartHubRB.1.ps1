$AzureAutomationAccount = "Privileged-Automation-Account"
$AzureAutomationAccountRG = "CORE-INT-EAST-PRIVILEGED-RG"
$AzureAutomationAccountSub = "CORE-GOV-INTERNAL"
$RBName = "
$Params = @{"resourceGroupName"=$($resourceGroupName); "URI"=$($URI); "SubscriptionName"=$($subscriptionName); "destinationVHDFileName"=$destinationVHDFileName; "SnapshotName"=$SnapshotName;"StorageAccountName"=$StorageAccountName;"StorageAccountKey"=$StorageAccountKey}
    
    $Params
    $RBJob = start-azurermautomationrunbook  -AutomationAccountName $AzureAutomationAccount -name $RBname -resourceGroupName $AzureAutomationAccountRG -parameters $params
