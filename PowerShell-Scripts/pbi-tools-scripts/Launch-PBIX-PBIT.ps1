
$pbixType = Read-Host -Prompt ">>> type 'PBIT' to launch template, leave blank for PBIX ... --> "

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