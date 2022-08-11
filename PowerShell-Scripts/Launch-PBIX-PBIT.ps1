
$pbixType = Read-Host -Prompt ">>> type 'PBIT' if you need to launch template, for PBIX leave it blank... --> "
if ($pbixType -eq "") {
    $trgFile = Get-ChildItem *.pbix -Recurse
    pbi-tools.exe launch-pbi $trgFile.FullName
}
elseif ($pbixType -eq "PBIT") {
    $trgFile = Get-ChildItem *.pbit -Recurse
    pbi-tools.exe launch-pbi $trgFile.FullName
}
else {
    Write-Output ">> Wrong type of the Power BI file entered..."
}