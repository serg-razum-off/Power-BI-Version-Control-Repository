#SR: Turning ON the watch mode

$PrId = (pbi-tools.exe info | ConvertFrom-Json).pbiSessions.ProcessId

if ($null -eq $PrId) {
    Write-Output "`n"
    throw ">>> Launch .pbix first, attach Watch Mode only after that..."
}
else {
    pbi-tools.exe extract -pid $PrId -watch
}