#SR: getting pbit
$pbit = Get-ChildItem *.pbit -Recurse
$base_path = $pbit.DirectoryName

#SR: getting metadata dir
$md_dir = ($pbit.FullName -split "\\" ) 
$md_dir = ($md_dir[$md_dir.Count-1] -split ".pbit")

#SR: compiling .pbit and launching it
$res = pbi-tools compile-pbix -folder "$base_path\$md_dir" -outPath "$base_path" -format PBIT -overwrite;     

#SR: if having Errs while compile
$substring_list = @("Error", "Global")
if (($substring_list | %{($res -join "").contains($_)}) -contains $true) {
    Write-Output ">>> Error: `n"; Write-Output ($res -join " <<>> ")
    throw
} else {
    Write-Output ">>> Compiled successfully: `n"; Write-Output $("-"*100)
    Write-Output "$res `n"; Write-Output $("-"*100)
}

#SR: launching
pbi-tools.exe launch-pbi $pbit.FullName