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

Project Structure [2023-01-24]:
```

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d----           3/11/2022  3:53 PM                _tmp
d----          14/01/2023  1:09 AM                .vscode
d----          19/01/2023  8:51 PM                AdventureWorks pbix
d----          23/01/2023 10:46 PM                Notebooks
d----          21/01/2023  7:01 PM                PowerShell-Scripts
d----          14/01/2023  1:09 AM                ProjectSettings
-a---          11/07/2022 11:20 AM             21 .gitignore
-a---          21/09/2022  4:43 PM          15859 Management Plan.xlsx
-a---           2/12/2022 12:55 PM            132 pbUsage.csv
-a---           1/01/2023 11:10 PM           3732 README.md


```

AdventureWorks pbix --> folder, containing PBIX, PBIT and expanded JSON schemas of the PBIT file.

PowerShell-Scripts --> folder, that includes:
* 01_MainClass.ps1
* Folders with scripts:
    * pbi-tools-scripts
    * pbi-REST-API-scripts /#TODO/

To operate these scripts properly, use Terminal --> 01_MainClass.ps1 object invocation, OR / AND add the below section to VS Code keyboard shoertcuts JSON:

```// Place your key bindings in this file to override the defaultsauto[]
[
    // ------------------------------------------------------------------------------------
    //SR [2022-07-28]: This section is for automation of Terminal pbi-tools commands
    // ------------------------------------------------------------------------------------
    {
        "key": "ctrl+shift+r",
        "command": "workbench.action.terminal.sendSequence",
        "when": "terminalFocus",
        "args": {
            "text": ". ./PowerShell-Scripts/01_MainClass.ps1; $pbix = [pbix]::new('', $true)"
        }
    },
    {
        "key": "ctrl+shift+l",
        "command": "workbench.action.terminal.sendSequence",
        "when": "terminalFocus",
        "args": {
            "text": "$pbix.pbiTools_Launch()"
        }
    },
    {
        "key": "ctrl+shift+b",
        "command": "workbench.action.terminal.sendSequence",
        "when": "terminalFocus",
        "args": {
            "text": "$pbix.pbiTools_Build()"
        }
    },
    {
        "key": "ctrl+shift+w",
        "command": "workbench.action.terminal.sendSequence",
        "when": "terminalFocus",
        "args": {
            "text": "$pbix.pbiTools_WatchMode()"
        }
    },
    {
        "key": "ctrl+alt+\\",
        "when": "editorFocus",
        "command": "workbench.action.splitEditorDown"
    }
    // ------------------------------------------------------------------------------------
]
```
. $PROFILE
save-settings
``` 

## PS Class
PS Class added to project under .\PowerShell-Scripts\PS_Class.ps1  <br>
Run VS Code as Admin for successfull operations.
