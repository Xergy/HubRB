# HubRB
Azure Runbook to bulk set Windows Licensing Hybrid Use Benefit


Starter Script should gather basic info to hand off to set script
Gather Subs
RGs to Exclude
VMs to Exclude

Pass above to set script

Loop through subs
    Loop through All RGs, skip excluded
        Loop through RG VMs, skip excluded, server with value in Hub
            Set Value for Hub


Exclude VM Logic
If Exclude VM is not Null
    excludeVMFlag = $False
    foreach Exclude VM
        if Exclude VM Name = VM name
            ExcludeVMFlag = $true

    If Exclude VM flag = False
        Write "VM Exdlues
        Else 
        Write "VM Not Excluded





