# Power-BI-Version-Control-Repository
``` 
Ctrl+K, V or Ctrl+Shift+V --> to read this MD in VS Code 
```

This repository is a place to test VC approaches for Power BI
* Each Repository is created for managing ONE couple of (.pbix -- . pbit)
    * in future improvements can be done to manage several .pbix-es with one Project
    * current limitations are identification of model--> queries folder, where new PQwrs (.m) will be automatically created


Main attention is dedicated to VS Code integration vith PBI-Tools parsing model.
* VS Code inbuilt 
* PowerShell as 

# pbi-tools Actions 
[[About PBI Tools]](https://pbi.tools/)
[[Link to PBI Tools Actions]](https://toolkit.action-bi.com/pbi-tools/usage.html)

## PBI Tools Actions automation with PowerShell

PS Scripts, included into Project:
* PowerShell-Scripts\Compile-Build.ps1
* PowerShell-Scripts\Launch-PBIX-PBIT.ps1
* PowerShell-Scripts\Watch-Mode.ps1

To operate with these scripts properly, visit ./ProjectSetings and import required code to $PROFILE and to keybindings.json
To save modifications in $PROFILE or in keybindings.json use
```
. $PROFILE
save-settings
``` 

## PS Class
PS Class added to project under .\PowerShell-Scripts\PS_Class.ps1  <br>
Run VS Code as Admin for successfull operations.