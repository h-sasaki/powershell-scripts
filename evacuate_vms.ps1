Param (
    [Parameter(Mandatory=$True)][string]$vcenter,
    [Parameter(Mandatory=$True)][string]$cluster,
    [Parameter(Mandatory=$True)][string]$esxi,
    [Parameter(Mandatory=$True)][string]$user,
    [Parameter(Mandatory=$True)][SecureString]$domain_password,
    [Parameter(Mandatory=$True)][int]$parallel_num = 2
)

Start-Transcript

Try {
    Import-Module VMware.PowerCLI
    Connect-VIServer -Server $vcenter -User $user -Password $password 
} Catch {
    Write-Host "Error found during preparation : `n$_"
    Break
}

$vmlist = Get-VMHost $esxi | Get-VM

foreach ($vm in $vmlist) {
    # Determine destination ESXi host
    $dest_esxi = Get-Cluster $cluster |Get-VMHost -State Connected |Sort-Object -Property MemoryUsageGB -Descending:$false |Select-Object -First 1
    if ($dest_esxi.Name -eq $esxi) {
        $dest_esxi = Get-Cluster $cluster |Get-VMHost -State Connected |Sort-Object -Property MemoryUsageGB -Descending:$false |Select-Object -First 2 |Select-Object -Last 1
    }
    # Get current running tasks for Relocatin VM and check if the count is lower than $parallel_num
    # I am checking for currently running tasks and with Perecentage over 0%, sometimes there are tasks that are just waiting    
    if ((Get-Task | Where-Object {$_.name -eq "RelocateVM_Task" -and $_.state -eq "Running" -and $_.PercentComplete -ne "0"}).count -lt $parallel_num) {
        Write-Host "Migrating VM:" $vm.Name "from" "$esxi to" $dest_esxi.Name
        Get-VM -Name $vm.Name |Move-VM -destination $dest_esxi -RunAsync

    } else {
        # If more that $parallel_num relocation tasks are running then wait for them to finish
        sleep 5
        Write-Host "Waiting for current vMotions to finish..."
        Write-Host "Current number of vMotions:" (Get-Task | Where-Object {$_.name -eq "RelocateVM_Task" -and $_.state -eq "Running" -and $_.PercentComplete -ne "0"}).count

        do {
            # Wait 60 seconds and recheck again                    
            sleep 60
        } while ((Get-Task | Where-Object {$_.name -eq "RelocateVM_Task" -and $_.state -eq "Running"-and $_.PercentComplete -ne "0"}).count -ge $parallel_num)

        # Repeate the above process when vMotion tasks go lower than $parallel_num
        if ((Get-Task | Where-Object {$_.name -eq "RelocateVM_Task" -and $_.state -eq "Running" -and $_.PercentComplete -ne "0"}).count -lt $parallel_num) {

            Write-Host "Less than $parallel_num vMotions Migrations are going"         

            # If the count is lower than $parallel_num 
            if ((Get-Task | Where-Object {$_.name -eq "RelocateVM_Task" -and $_.state -eq "Running" -and $_.PercentComplete -ne "0"}).count -lt $parallel_num) {
                Write-Host "Migrating VM:" $vm.Name "from" "$esxi to" $dest_esxi.Name
                Get-VM -Name $vm.Name |Move-VM -destination $dest_esxi -RunAsync
            }
        }
    }
}

Disconnect-VIServer -Server $vcenter -Confirm:$False

Stop-Transcript
