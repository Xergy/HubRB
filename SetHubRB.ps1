
param(
#Provide the subscription Id of the subscription where snapshot is created
[parameter(Mandatory=$true)]
[string]$subscriptionName, 

#Provide the name of your resource group where snapshot is created
[parameter(Mandatory=$true)]
[string]$resourceGroupName,

#Provide the snapshot name 
[parameter(Mandatory=$true)]
[string]$SnapshotName,

#Provide the URI
[parameter(Mandatory=$true)]
[string]$URI,

#Provide the snapshot name 
[parameter(Mandatory=$true)]
[string]$storageAccountName, 

#Provide the snapshot name 
[parameter(Mandatory=$true)]
[string]$storageAccountKey,  

#Provide the name of the VHD file to which snapshot will be copied.
[parameter(Mandatory=$true)]
[string]$destinationVHDFileName 
)
$elapsedtime = [System.Diagnostics.Stopwatch]::StartNew()
$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    "Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint `
        -EnvironmentName AzureUSGovernment
}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

#Name of the storage container where the downloaded snapshot will be stored
$storageContainerName = "images"

Select-AzureRmSubscription -Subscription $subscriptionName | out-null

#Create the context for the storage account which will be used to copy snapshot to the storage account 
$destinationContext = New-AzureStorageContext –StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey  
"Creating Destination Context"

#Copy the snapshot to the storage account 
$copy = Start-AzureStorageBlobCopy -AbsoluteUri $($URI) -DestContainer $storageContainerName -DestContext $destinationContext -DestBlob $destinationVHDFileName -Force 
"Copying image to $($storageAccountName)"

$copyStatus = $copy | Get-AzureStorageBlobCopyState
while ($copyStatus.Status -eq "Pending")
{
    $copyStatus = $copy | Get-AzureStorageBlobCopyState
    $perComplete = ($copyStatus.BytesCopied / $copyStatus.TotalBytes) * 100
    Write-Host -Activity "Copying blob ... " -Status "Percentage Complete" -PercentComplete "$perComplete"
    Start-Sleep 10
}
$elapsedtime.Stop()
"Total Runtime: $($elapsedtime.elapsed.Hours) Hours  $($elapsedtime.elapsed.Minutes) Minutes  $($elapsedtime.elapsed.Seconds) Seconds! "
