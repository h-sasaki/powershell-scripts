Param (
    [Parameter(Mandatory=$True)][string]$vcenter,
    [Parameter(Mandatory=$True)][string]$user,
    [Parameter(Mandatory=$True)][SecureString]$domain_password,
    [Parameter(Mandatory=$True)][int]$days = 30
)

Try {
    Import-Module VMware.PowerCLI
    Connect-VIServer -Server $vcenter -User $user -Password $password 
} Catch {
    Write-Host "Error found during preparation : `n$_"
    Break

$Date = Get-Date
Write-Host "Checking Events..."
$result = Get-VIEvent -maxsamples 100000 -Start ($Date).AddDays(-$days) -type warning | Where {$_.FullFormattedMessage -match "restarted"} |select CreatedTime,FullFormattedMessage |sort CreatedTime -Descending
if ($result -eq $Null){
    Write-Host "No events found."
} else {
    $result |Format-List
}

Disconnect-VIServer -Server $vcenter -Confirm:$False

Write-Host "Completed."
