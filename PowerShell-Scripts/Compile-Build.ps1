#SR: getting pbit
$pbit = Get-ChildItem *.pbit -Recurse
$base_path = $pbit.DirectoryName

#SR: getting metadata dir
$md_dir = ($pbit.FullName -split ".pbit" -split "\\") #TODO: optimize splitting
$md_dir = $md_dir[$md_dir.Count-2]

#SR: compiling .pbit and launching it
$res = pbi-tools compile-pbix -folder "$base_path\$md_dir" -outPath "$base_path" -format PBIT -overwrite;     
$substring_list = @("Error", "Global")
if (($substring_list | %{($res -join "").contains($_)}) -contains $true) {
    Write-Output "`n >>> Error: `n"; Write-Output ($res -join " <<>> ")
    throw
} else {
    Write-Output "`n >>> Compiled successfully: `n"; Write-Output $("-"*100)
    Write-Output "$res `n"; Write-Output $("-"*100)
}
pbi-tools.exe launch-pbi $pbit.FullName