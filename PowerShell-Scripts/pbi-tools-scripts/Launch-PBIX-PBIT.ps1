
$pbixType = Read-Host -Prompt ">>> type 'PBIT' to launch template, leave blank for PBIX... --> "
$pbixPartName = Read-Host -Prompt ">>> Input Part of the PBI File that you want to launch... --> " #if Proj has >1  pbix. UPD: one Proj == 1 pbix File

if ($pbixType -eq "") {
    $trgFile = Get-ChildItem *$pbixPartName*.pbix -Recurse
}
elseif ($pbixType -eq "PBIT") {
    $trgFile = Get-ChildItem *.pbit -Recurse
}
else {
    Write-Output ">> Wrong type of the Power BI file entered..."
}


if ($null -eq $trgFile) {
    Write-Host "`n >>> No file with '$pbixPartName' in filename found... `n"
    throw
}

pbi-tools.exe launch-pbi $trgFile.FullName