## SR: this is the fastest solution.
# Get-ChildItem *.pbix -Recurse | Select-Object -ExpandProperty DirectoryName | Set-Location 

## these are other searches
# $test = Get-ChildItem *.pbix -Recurse | Format-List -Property DirectoryName 

# $test2 = ((Get-ChildItem *.pbix -Recurse | Format-List  -Property DirectoryName | Out-String) -split " : ")[1]
# $test2

#  try {
#     Get-Item -Path 'C:\nonex' -ErrorAction Stop; Write-Host '>>> Writing in continuation'
#  }
#  catch {
#     Write-Host ">>> desription of Err:"
#     Write-Error $_.Exception
#     Write-Host "This is Catch Clause"
#  }
## SR: this is the fastest solution.
# Get-ChildItem *.pbix -Recurse | Select-Object -ExpandProperty DirectoryName | Set-Location 

## these are other searches
$test = Get-ChildItem *.pbix -Recurse | Format-List -Property DirectoryName 

# $test2 = ((Get-ChildItem *.pbix -Recurse | Format-List  -Property DirectoryName | Out-String) -split " : ")[1]
# $test2

#  try {
#     Get-Item -Path 'C:\nonex' -ErrorAction Stop; Write-Host '>>> Writing in continuation'
#  }
#  catch {
#     Write-Host ">>> desription of Err:"
#     ">>> $_.Exception"
#     # Write-Error $_
#     Write-Host "This is Catch Clause"
#  }

 