Param (
    [Parameter(Mandatory=$True)][string]$vcenter,
    [Parameter(Mandatory=$True)][string]$user,
    [Parameter(Mandatory=$True)][SecureString]$password,
    [Parameter(Mandatory=$True)][string]$export_path = "C:\Temp\Performance_Report\"
)

$STARTDATE = (Get-Date).AddMonths(-1)
$DATE = Get-Date -Format yyyyMMdd

Try {
    Import-Module VMware.PowerCLI
    Connect-VIServer -Server $vcenter -User $user -Password $password 
} Catch {
    Write-Host "Error found during preparation : `n$_"
    Break
}

$clusters = Get-Cluster
Foreach ($cluster in $clusters){
	Get-Cluster $cluster |Get-Stat -Stat 'cpu.usage.average' -Start $STARTDATE |Select Timestamp, Value |Export-Csv ($export_path + $DATE + "_" + $cluster.Name + "_cpu.usage.average.csv")
	Get-Cluster $cluster |Get-Stat -Stat 'mem.usage.average' -Start $STARTDATE |Select Timestamp, Value |Export-Csv ($export_path + $DATE + "_" + $cluster.Name + "_mem.usage.average.csv")
	Get-Cluster $cluster |Get-Stat -Stat 'mem.vmmemctl.average' -Start $STARTDATE |Select Timestamp, Value |Export-Csv ($export_path + $DATE + "_" + $cluster.Name + "_mem.vmmmemctl.average.csv")
	Get-Cluster $cluster |Get-Datastore  |Select Name, FreeSpaceGB, CapacityGB |Export-Csv ($export_path + $DATE + "_" + $cluster + "_datastore.csv")
}
