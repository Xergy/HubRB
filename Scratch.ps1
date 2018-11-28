if ($Null -eq (Get-AzureRmContext).Account) {
    $AzureEnv = Get-AzureRmEnvironment | Select-Object -Property Name  | 
    Out-GridView -Title "Choose your Azure environment.  NOTE: For Azure Commercial choose AzureCloud" -OutputMode Single
    Connect-AzureRmAccount -Environment $AzureEnv.Name }

    $MyVM = Get-AzureRmVM -ResourceGroupName Prod-RG -Name Haven
    

    $MyVM.LicenseType

    $MyVM | Select-Object -Property name, LicenseType

    $MyVM | fl *

    $MyVM.LicenseType = "Windows_Server"
    Update-AzureRmVM -ResourceGroupName Prod-TX-RG -VM $Myvm

$MyVM = $Null