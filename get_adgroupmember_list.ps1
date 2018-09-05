Param (
    [Parameter(Mandatory=$True)][string]$searchbase
)

$groups = Get-ADGroup -Properties Name -Filter * -SearchBase $searchbase |Select Name |Sort-Object -Property Name
Foreach ($group in $groups) {
    $members = Get-ADGroupMember $group.Name |Where objectClass -eq "user" |Get-ADUser |Select Name, SamAccountName, Enabled |Sort-Object -Property Name
    Write-Host "`r`n"
    Write-Host $group.Name
    Write-Host "-------------"
    foreach ($member in $members) {
        Write-Host $member.Name, $member.SamAccountName, $member.Enabled
    }
}

