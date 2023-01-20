$script:ProjectSettingsPath = "D:\Projects\PBI Tools\Power-BI-Version-Control-repository\ProjectSettings\!ProjectSettings.json"

class PBIT {
<#
        .AUTHOR
            sergiy.razumov@gmail.com
        .DESCRIPTION
            ClassName PBIT == Power BI Tools
            docs for pbi-tools: https://pbi.tools/ ; https://pbi.tools/tutorials/getting-started-cli.html 
            PowerShell Class to handle automated interactions with pbi-tools, based on JSON schemas 
            currently one Proj for one pbi file in the directory; later init Class by name can be added.
            ❗ work with only one file at the moment 

        .EXAMPLE
            $var_class = [pbit]::new()
            $var_class = [pbit]::new($true)
            #todo: make all overload-type-methods() call engine-methods() with meaningfull parameters (@{}, "defValue"...)

        .Notes
            basic ProjectSettings are stored in ./projectSettings/ProjectSettings.json
    #>
    
    #============ #PROPERTIES ================================

    [pscustomobject]$projectSettings 
    [string]$projectRoot
    # for import tables and measures specification
    [array]$managementPlan
    # address of pbix. $null if not yet compiled or extracted
    [string]$pbixPath
    [string]$pbitPath

    #TODO: For lining up visuals
    #   ❓❓ Belowlocated props, are going to land in one of the .Net Classes for .pbix management. Default values for them already landed in Projects.json
    [int]$filtersLine_Y     
    [int]$firstLine_Y     
    [int]$secondLine_Y

    [bool]$verbose = $false  
    [scriptblock] $writeVerboseFunction
    
    #============== #CONSTRUCTORS ===========================
    #def
    PBIT() {
        $this.verbose = $true
        $this.SetVerbose()
        $this.inner_Init()
    }
    # for named parameters
    PBIT([hashtable]$params) { 
        $this.verbose = $null -eq $params['_verbose'] ? $true : $params['_verbose']
        $this.SetVerbose()
        $this.inner_Init()
    }
     
    #==================== #METHODS ===========================
    #📚 README: all major Methods are equipped with empty callers -- when no param is passed, method is called from the outside as: $this.git_myMethod()
    #📝all setting of personal aliases were moved to $PROFILE 

    #region ---------------- ✨ Internal Methods ---------------------- 
    [void] SetVerbose() {
        # Setter method for the $verbose property
        #   SR[2023-01-08] this method didn't want to work with Set_Verbose ([bool]$_verbose) signature
        if ($this.verbose) {
            $this.writeVerboseFunction = { 
                param($message)
                Write-Host -ForegroundColor Yellow "VERBOSE:" $message
            } 
        }
        else {
            $this.writeVerboseFunction = {
                #if wriverbose -eq $false, use outer $verbosePreference 
                param($message)
                & Write-Verbose $message
            } 
        }
    }   
    hidden [void] inner_Init() {
        # writing, depending on $VerbosePreference settings 
        & $this.writeVerboseFunction "=== Starting PBIX Cls inner_Init ===" 
        & $this.writeVerboseFunction ">>> Setting up PBIT Properties... " 
        & $this.writeVerboseFunction ">>> Updating Data from Management Excle file..." 
        
        # getting setting properties        
        $this.projectSettings = Get-Content $script:ProjectSettingsPath | ConvertFrom-Json
        $this.filtersLine_Y = $this.projectSettings.filtersLine_Y
        $this.firstLine_Y = $this.projectSettings.firstLine_Y
        $this.secondLine_Y = $this.projectSettings.secondLine_Y            
        $this.projectRoot = $this.projectSettings.projectRoot

        #getting Management Plan
        $this.managementPlan = Import-Excel (Get-ChildItem -Path $this.projectRoot *plan.xlsx* -r) `
            -WorksheetName "Planned Objects" `
            -StartRow 3
        
        # getting paths to pbi files
        $this.pbixPath = (Get-ChildItem -path $this.projectRoot -filter *.pbix -rec)
        $this.pbitPath = (Get-ChildItem -path $this.projectRoot -filter *.pbit -rec)
        
        # Updating Tables in Manage Plan
        $this.managementPlan_UpdateManagementPlanTables();
                
        # wrapping the inner_Init up
        & $this.writeVerboseFunction "=== PBIX Cls inner_Init Completed ===" 
        
    }
    #endregion
    
    #region ---------------- 🔧 Pbi-tools functionality  ---------------- 

    [void] Extract() {
        <#
            .DESCRIPTION
                Extracts PBI-JSON structured Metadata from .pbix file
        #> 
        #SR: getting pbix        
        $base_path = Split-Path $this.pbixPath -Parent
        $fileName = Split-Path $this.pbixPath -Leaf
         
        #SR: getting metadata folder -- it should be called as pbix file, but witout extension .pbix
        $md_dir = ($fileName -split ".pbix")[0] 

        check if Dir exists
        if ( -not (Test-Path "$base_path\$md_dir")  ) {
            New-Item -ItemType Directory -Path "$base_path\$md_dir"
        }

        # pbi-tools extract pbixPath $this.pbixPath -extractFolder "$base_path\$md_dir" 
        cw "$base_path\$md_dir" ## for debugging. When real extract is needed, uncomment upper line.
    }
    
    [void] Build() {
        <#
            .DESCRIPTION
                Compile PBIT from pbi-tools JSON model, launch PBIT. If Compillation was successful, data will start refresh
        #>    

        #SR: getting pbix location -- PBIT will be compiled to that folder,         
        $pbix_O = (Get-Item $this.pbixPath)
        $base_path = $pbix_O.DirectoryName #SR: $this.pbixPath contains only FullPath, not the Obj itself

        #SR: getting metadata dir
        $md_dir = ($pbix_O.FullName -split "\\" ) #get Arr of folder path
        $md_dir = ($md_dir[$md_dir.Count - 1] -split ".pbix")[0] #from last el /pbix name/ get name wo extension

        # $tmp = "$base_path\$md_dir" #* for debugging only
        
        #SR: compiling .pbit and launching #++
        $res = pbi-tools compile-pbix -folder "$base_path\$md_dir" `
            -outPath "$base_path" `
            -format PBIT `
            -overwrite;     

        #SR: if having Errs while compile
        $substrings_list = @("Error", "Global")
        if (($substrings_list | ForEach-Object { ($res -join "").contains($_) }) -contains $true) {
            Write-Host ">>> Error: `n"; 
            Write-Host ($res -join " <<>> ")
            throw
        }
        else {
            & $this.writeVerboseFunction (">>> PBIT: Compiled successfully: `n"); & $this.writeVerboseFunction ( $("-" * 50)   )
            & $this.writeVerboseFunction ("$res `n"); & $this.writeVerboseFunction ( $("-" * 50) )
        }
        
        #SR: launching
        & $this.writeVerboseFunction (">>> PBIT: Launched... `n"); & $this.writeVerboseFunction ( $("-" * 50)   )
        pbi-tools.exe launch-pbi $this.pbitPath
    }
    [void] Launch() { $this.Launch("pbix") } # method overload to solve omittable param. 
    [void] Launch($pbixType) {
        <#
            .DESCRIPTION
                Launches PBI file. Arg $pbixType = {"pbix" | "", "pbit"}
                Example: $pbix.Launch("pbix") #$pbix --> object; "pbix" same as "" OR "pbit" --> type of the file that is to be launched
        #>

        $trgFile = $null

        if ($pbixType -eq "pbix") {
            $trgFile = $this.pbixPath
        }
        elseif ($pbixType -eq "PBIT") {
            $trgFile = $this.pbitPath
        }
        else {
            Write-Output ">> Wrong type of the Power BI file entered..."
        }

        if ($null -eq $trgFile) {
            Write-Host "`n >>> No file '$trgFile' found... `n"
            throw
        }
        
        $fileName = $trgFile.Split("\\")
        $fileName = $fileName[$fileName.Count - 1]
        
        pbi-tools.exe launch-pbi $trgFile

        & $this.writeVerboseFunction ">>> File '$fileName' was launched..." 
    }
    [void] WatchMode() {
        #SR: Turning ON the watch mode
        try {
            # $PrId = (pbi-tools.exe info | ConvertFrom-Json).pbiSessions.ProcessId #--> this will work only when 1 .pbx is launched
            $thisPbxPathLeaf = splt $this.pbixPath -Leaf
            $PrId = (
                (pbi-tools.exe info | ConvertFrom-Json | Select-Object pbisessions ).pbisessions | 
                Where-Object { (splt $_.pbixPath -Leaf) -eq ( $thisPbxPathLeaf ) }
            ).ProcessId 
        }
        catch {
            throw ">>> use method Launch to start .pbix first, attach Watch Mode only after that..."
        }

        & $this.writeVerboseFunction ">>> Watch Mode is on {PrId=$PrId}. Save report in PBI and see changes in a VS Code Git Tab"
        & $this.writeVerboseFunction "--> Ctrt + C to Quit Watch Mode"
        
        pbi-tools.exe extract -pid $PrId -watch
    }
    #endregion 

    #region ---------------- 🛒 Managerment Plan ----------------------- 
    [void] managementPlan_UpdateManagementPlanTables() {    
        <#
            .DESCRIPTION
                Method for updating "Specification" record in each of the tables in PBI --> PQ
        #>    
        
        # gettign content of mgm xlsFile -- only Tables
        #   1. read mgm Pln again (changes) 
        $this.managementPlan = Import-Excel (Get-ChildItem -Path $this.projectRoot *plan.xlsx* -r) `
            -WorksheetName "Planned Objects" `
            -StartRow 3
        $mgmPlanTables = $this.managementPlan `
        | Where-Object { $_.'02_Type' -eq 'Table' } `
        | Where-Object { $_.'08_Status' -ne 'Removed' }
            
        $objKeys = ($mgmPlanTables | Get-Member -MemberType NoteProperty).Name

        foreach ($xlsRecord in $mgmPlanTables) {
            
            # combining Specification for current record to inject to PQ qwr
            $pq = @()
            $objKeys | ForEach-Object { $pq += ($_ + " = " + """" + $xlsRecord.$_ + """") } 
            $required_qwr = "[ `n`t" + ($pq -join ",`n `t`t") + " `n`t]"
            
            # Checking if target PQwr file exists. If not -- creating one with code == Spec template
            $path = (Get-ChildItem ($xlsRecord.'01_Object Name' + '.m') -r).FullName;

            if ($null -eq $path) {
                $path = (Get-ChildItem queries -r).FullName + '\' + ($xlsRecord.'01_Object Name' + '.m')
                "let
    Specification = []
    in 
Specification" | Set-Content $path
            }
            
            # Checking if in existing PQ file we doesn't have "Specification". If not -- injecting it
            if (([regex]::Match((Get-Content $path), 'let.*Source = ') -replace " ", "").Length -eq 10) {
                #there is no "Specification" step in PQ Qwr
                    (Get-Content $path) -join "`n" `
                    -replace "let(.|\n)*Source = ", `
                    "let
    Specification = [],
    Source = " | Set-Content $path
            }
            
            # Evaluating correct RegEx for replacement in PQwr
            $pattern = '\[(.|\n)?\]'; # Specification is [], not filled with data
            $endingComma = ''
            if (([regex]::Match((Get-Content $path), $pattern)).Length -eq 0) { 
                $pattern = '\[(.|\n)*\],' # grabs Specification Record in PQwr
                $endingComma = ','
            }

            # if Specification is already as required, skip to next $xsl item
            if (
                [regex]::Match((Get-Content $path), $pattern) `
                    -replace ' ', '' `
                    -replace '`n', ''`
                    -eq `
                    $required_qwr `
                    -replace ' ', '' `
                    -replace '`n', ''
            ) {
                continue 
            }
            
            # writing to the target file
            (Get-Content $path) -join "`n" `
                -replace $pattern, ($required_qwr + $endingComma) `
            | Set-Content $path
        }        
    } # } UpdateManagementPlanTables   
    #endregion

    #region ---------------- 📊 Design Objects .pbix -------------------- 
    [void] AddPage (){}
    [void] AddVisualObject (){        <# prop validate {chart, slicer, filter} #>    }
    [void] AddMeasure (){<# service Method; can be used solely or with integration with ImportMeasures Meth #>}
    [void] AddQuery () {<# when a Qwr is added to Model, PowerBI can create table itself #> }
    #endregion
} 
