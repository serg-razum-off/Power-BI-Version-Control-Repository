
$pbixType = Read-Host -Prompt ">>> type 'PBIT' to launch template, leave blank for PBIX... --> "
$pbixPartName = Read-Host -Prompt ">>> Input Part of the PBI File that you want to launch... --> " #if Proj has >1  PBI files #TODO: make this a functtion.

if ($null -eq $trgFile) {
    Write-Host "`n >>> No such file found... `n"
    throw
}
if ($pbixType -eq "") {
    $trgFile = Get-ChildItem *$pbixPartName*.pbix -Recurse
    pbi-tools.exe launch-pbi $trgFile.FullName
}
elseif ($pbixType -eq "PBIT") {
    $trgFile = Get-ChildItem *.pbit -Recurse
    pbi-tools.exe launch-pbi $trgFile.FullName
}
else {
    Write-Output ">> Wrong type of the Power BI file entered..."
}