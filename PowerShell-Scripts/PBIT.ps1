$script:ProjectSettingsPath = "D:\Projects\PBI Tools\Power-BI-Version-Control-repository\ProjectSettings\!ProjectSettings.json"

class PBIX {
    <#
        .AUTHOR
            sergiy.razumov@gmail.com
        .DESCRIPTION
            PowerShell Class to handle interactions with pbi-tools --> JSON splitted .pbx 
            currently one Proj for one pbi file --> number of changes is high. Several pbixes in one proj will mess up VC

            Methods are clustered into categories:  
                $this.inner_
                $this.pbiTPathools_
                $this.managementTool_
                #REFACTOR: #⚠ : move methods from clusters to separate functions, to have dot notation for them. => $this.pbiTPathools.<methodName>

        .EXAMPLE
            $pbix = [pbix]::new()
            $pbix = [pbix]::new($true)

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
    [int]$filtersLine_Y;     
    [int]$firstLine_Y;     
    [int]$secondLine_Y

    [bool]$verbose = $false ; # set to $true when initing the Class, if needed
    
   #============== #CONSTRUCTORS ===========================
    #def
    PBIX() {
        $this.inner_Init()
    }
    # for named parameters
    PBIX([hashtable]$params) { 
        $this.verbose = $params['_verbose']
        $this.set_verbose($params['_verbose'])
        $this.inner_Init()
    }
    # for bool _verbose
    PBIX([bool]$_verbose) { 
        $this.SetVerbose($_verbose)
        $this.inner_Init()
    }
    
    # Setter method for the $verbose property
    #   SR[2023-01-08] this method didn't want to work with Set_Verbose ([bool]$_verbose) signature
    [void] SetVerbose([bool]$verbose) {
        $this.verbose = $verbose                
        if ($this.verbose) {
            $global:VerbosePreference = "Continue" 
        }
        else {
            $global:VerbosePreference = "SilentlyContinue" 
        }
    }
   
    #==================== #METHODS ===========================
    #📚 README: all major Methods are equipped with empty callers -- when no param is passed, method is called from the outside as: $this.git_myMethod()
    #📝all setting of personal aliases were moved to $PROFILE
    
    #--------------------- tech Helpers -------------------------
    # hidden [void] inner_WriteVerbose([string]$message) {
    #     # Printing Verbose messages
    #     if ($this.verbose) { 
    #         $VerbosePreference = "Continue" 
    #         Write-Verbose( "$message" )
    #         $VerbosePreference = 'SilentlyContinue' 
    #     }           
    # }
    
    hidden [void] inner_Init() {
        # writing, depending on $VerbosePreference settings 
        Write-Verbose ( "=== Starting PBIX Cls inner_Init ===" )
        Write-Verbose ( ">>> Setting up PBIT Properties... " )
        Write-Verbose ( ">>> Updating Data from Management Excle file..." )
        
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
        Write-Verbose ( "=== PBIX Cls inner_Init Completed ===" )
        
    }
    #--------------- Pbi-tools addressing  ----------------
    #   docs for pbi-tools: https://pbi.tools/ ; https://pbi.tools/tutorials/getting-started-cli.html 

    [void] pbiTools_Extract() {
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
    
    [void] pbiTools_Build() {
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
            Write-Verbose (">>> PBIT: Compiled successfully: `n"); Write-Verbose ( $("-" * 50)   )
            Write-Verbose ("$res `n"); Write-Verbose ( $("-" * 50) )
        }
        
        #SR: launching
        Write-Verbose (">>> PBIT: Launched... `n"); Write-Verbose ( $("-" * 50)   )
        pbi-tools.exe launch-pbi $this.pbitPath
    }
    [void] pbiTools_Launch() { $this.pbiTPathools_Launch("") } # method overload to solve omittable param. $pbixType=$null doesn't work
    [void] pbiTools_Launch($pbixType) {
        <#
            .DESCRIPTION
                Launches PBI file. Arg $pbixType = {"pbix" | "", "pbit"}
                Example: $pbix.pbiTools_Launch("pbix") #$pbix --> object; "pbix" same as "" OR "pbit" --> type of the file that is to be launched
        #>

        $trgFile = $null

        if ($pbixType -eq "" -or $pbixType -eq "pbix") {
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

        Write-Verbose ( ">>> File '$fileName' was launched..." )
    }
    [void] pbiTools_WatchMode() {
        #SR: Turning ON the watch mode
        try {
            $PrId = (pbi-tools.exe info | ConvertFrom-Json).pbiSessions.ProcessId
        }
        catch {
            throw ">>> use method pbiTools_Launch to start .pbix first, attach Watch Mode only after that..."
        }

        Write-Verbose (">>> Watch Mode is on. Save report in PBI and see changes in a VS Code Git Tab")
        Write-Verbose ("--> Ctrt + C to Quit Watch Mode")
        
        pbi-tools.exe extract -pid $PrId -watch
    }

    #---------------- Managerment Plan --------------------
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
} 
