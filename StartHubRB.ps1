#if not logged in to Azure, start login
if ((Get-AzureRmContext).Account -eq $Null) {
    Login-AzureRmAccount -Environment AzureUSGovernment}

<#
$SubConfig = @(
    @{
        SubscriptionID = "ed347077-d367-4401-af11-a87b73bbae0e"
        #ExcludeRG = "Prod-RG"
        #ExcludeVM = "TargetVM","RP-AD"
    }
    @{
        SubscriptionID = "dd1f0073-4e57-4d48-b9ce-0a9ec4782de8"
        #ExcludeRG = "Prod-RG"
        # ExcludeVM = "MoveTest2-RG"
    }
)
#>

$SubConfig = @(
    @{
        SubscriptionID = "ed347077-d367-4401-af11-a87b73bbae0e"
        #ExcludeRG = "Prod-RG"
        #ExcludeVM = "F5Jumpbox","RP-AD","TargetVM"
    }
)


Get-Job | Remove-Job

foreach ($SubConfigItem in $SubConfig) {
    Write-Output "Subscription: $($SubconfigItem.SubscriptionID)"
    $Null = Set-AzureRmContext -SubscriptionID $SubConfigItem.SubscriptionID
    
    $SubRGsAll = Get-AzureRmResourceGroup

    #Exclude SubRG Logic
    $SubRG = @()
    $Results = @()

    Foreach ($SubRG in $SubRGsAll){
        $ExcludeSubRGFlag = $False
        
        If ($Null -ne $SubConfigItem.ExcludeRG) {
            Foreach ($ExcludeRG in $SubConfigItem.ExcludeRG) {
                If ($ExcludeRG -eq $SubRG.ResourceGroupName) {
                    $ExcludeSubRGFlag = $True
                }
            }
        }

        If ($ExcludeSubRGFlag) {
            Write-Output "SubRG: $($SubRG.ResourceGroupName) EXCLUDED"
            $SubRG = $SubRG | 
                Add-Member -MemberType "NoteProperty" -Name "HubExcluded" -Value ($True) -PassThru

        }
        Elseif (!$ExcludeSubRGFlag) {
            Write-Output "SubRG: $($SubRG.ResourceGroupName) Not Excluded"
            $SubRG = $SubRG | 
                Add-Member -MemberType "NoteProperty" -Name "HubExcluded" -Value ($False) -PassThru
        }
        
        $Results += $SubRG

    }

    $SubRGs = $Results | Select-Object -Property ResourceGroupName,HubExcluded

    Foreach ($SubRG in ($SubRGs | where-object {!$_.HubExcluded})) {
        Write-Output "SubRG: $($SubRG.ResourceGroupName)"

        $RGVMs = Get-AzureRmVM -ResourceGroupName $SubRG.ResourceGroupName | where-object {$_.StorageProfile.OsDisk.OsType -eq "Windows"}
        
        $Results = @()

        Foreach ($RGVM in $RGVMs) {
            Write-Output "RGVM: $($RGVM.Name)"

            #Exclude VM Logic
            $ExcludeVMFlag = $False
         

            If ($Null -ne $SubConfigItem.ExcludeVM) {
                Foreach ($ExcludeVM in $SubConfigItem.ExcludeVM) {
                    If ($ExcludeVM -eq $RGVM.Name) {
                        $ExcludeVMFlag = $True
                    }
                }
            }

            If ($ExcludeVMFlag) {
                Write-Output "VM: $($RGVM.Name) EXCLUDED"
                $RGVM = $RGVM | Add-Member -MemberType "NoteProperty" -Name "HubExcluded" -Value ($True) -PassThru                
                      
            }
            Elseif (!$ExcludeVMFlag) {
                Write-Output "VM: $($RGVM.Name) Not Excluded"
                $RGVM = $RGVM | Add-Member -MemberType "NoteProperty" -Name "HubExcluded" -Value ($False) -PassThru
            }
            
            $Results += $RGVM            

        } # RGVM

        $RGVMs = $Results
        
        #$RGVMs | Where-Object { !$_.HubExcluded } | 
        $RGVMs | Where-Object { !$_.HubExcluded -and $_.LicenseType -eq $Null } | 

            ForEach-Object {
                    Write-Host "Setting Hub for $($_.Name)..." 
                    
                    $TargetVM = Get-AzureRmVM -ResourceGroupName $SubRG.ResourceGroupName -Name $_.Name
                    $TargetVM.LicenseType = "Windows_Server"
                    Update-AzureRmVM -ResourceGroupName $SubRG.ResourceGroupName -VM $TargetVM -WhatIf
            } 

        Write-Output "Waiting for this $($SubRG.ResourceGroupName)'s jobs to complete..."
        get-job | Wait-Job
        Write-Output "Done with this RGs VMs!"
        Get-Job | Remove-Job

    } # SubRG
} # Subconfig