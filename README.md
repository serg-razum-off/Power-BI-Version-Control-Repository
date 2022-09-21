# Power-BI-Version-Control-Repository
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

To operate with these scripts properly, add this section to VS Code keyboard shoertcuts JSON:

```// Place your key bindings in this file to override the defaultsauto[]
[
    // ------------------------------------------------------------------------------------
    //SR [2022-07-28]: This section is for automation of Terminal pbi-tools commands
    // ------------------------------------------------------------------------------------
    {
        "key": "ctrl+shift+l",
        "command": "workbench.action.terminal.sendSequence",
        "when": "terminalFocus",
        "args": {
            "text": "./PowerShell-Scripts/pbi-tools-scripts/Launch-PBIX-PBIT.ps1"
        }
    },
    {
        "key": "ctrl+shift+b",
        "command": "workbench.action.terminal.sendSequence",
        "when": "terminalFocus",
        "args": {
            "text": "./PowerShell-Scripts/pbi-tools-scripts/Compile-Build.ps1"
        }
    },
    {
        "key": "ctrl+shift+w",
        "command": "workbench.action.terminal.sendSequence",
        "when": "terminalFocus",
        "args": {
            "text": "./PowerShell-Scripts/pbi-tools-scripts/Watch-Mode.ps1"
        }
    }
    // ------------------------------------------------------------------------------------
]
```
## PS Class
PS Class added to project under .\PowerShell-Scripts\PS_Class.ps1  <br>
Run VS Code as Admin for successfull operations.