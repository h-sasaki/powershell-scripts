Param (
    [Parameter(Mandatory=$True)][string]$vcenter,
    [Parameter(Mandatory=$True)][string]$domain,
    [Parameter(Mandatory=$True)][string]$domain_user,
    [Parameter(Mandatory=$True)][SecureString]$domain_password
)

Try {
    Import-Module VMware.PowerCLI
    Connect-VIServer -Server $vcenter
} Catch {
    Write-Host "Error found during preparation : `n$_"
    Break
}

Get-VMHost | Get-VMHostAuthentication | Set-VMHostAuthentication -Domain $domain -JoinDomain -Username $domain_user -Password $domain_password -Confirm:$false

Disconnect-VIServer -Server $vcenter -Confirm:$False