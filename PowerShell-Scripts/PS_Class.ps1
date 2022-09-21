class PBIX {
    <#
        .AUTHOR
            sergiy.razumov@gmail.com
        .DESCRIPTION
            PowerShell Class to handle interactions with pbi-tools --> JSON splitted .pbx 
            One Proj for one pbi file --> number of changes is high. Several pbixes in one proj will mess up VC

            Methods are clustered into categories:
                $this.inner_
                $this.pbiTools_
                $this.managementTool_

        .EXAMPLE
            $pbix = [pbix]::new()
            $pbix = [pbix]::new(10, 175, 325, $false)
    #>
    #============ #PROPERTIES ================================
    # for searches cat's and ls's
    [string]$projectRoot
    # for import tables and measures specification
    [array]$managementPlan
    # address of pbix. $null if not yet compiled or extracted
    [string]$pbix
    [string]$pbit

    #TODO: For lining up visuals 
    [int]$filtersLine_Y;     
    [int]$firstLine_Y;     
    [int]$secondLine_Y

    [bool]$verbose = $false  # Set to $true for detailed output in $this.Methods()
    
    #============== #CONSTRUCTORS ===========================
    #def
    PBIX() {
        $this.inner_Init("", $this.verbose)
    }
    #verbose
    PBIX($configString, $verbose) { 
        # $configString -- all 3 Y params: "{'filtersLine_Y':$filtersLine_Y, 'firstLine_Y':$firstLine_Y, 'secondLine_Y':$secondLine_Y}",
        $this.inner_Init("", $verbose)
    }
    #param-d
    PBIX(
        [int]$filtersLine_Y, 
        [int]$firstLine_Y, 
        [int]$secondLine_Y,
        [bool]$verbose = $null 
    ) {         
        $this.inner_Init(
            "{'filtersLine_Y':$filtersLine_Y, 'firstLine_Y':$firstLine_Y, 'secondLine_Y':$secondLine_Y}",
            $verbose
        )
    }
    
    #==================== #METHODS ===========================
    #--------------------- Helpers -------------------------
    hidden [void] inner_WriteVerbose([string]$message) {
        # Printing Verbose messages
        if ($this.verbose) { 
            $VerbosePreference = "Continue" 
            Write-Verbose( "$message" )
            $VerbosePreference = 'SilentlyContinue' 
        }           
    }
    hidden [void] inner_Init([string]$jprop, [bool]$Verbose) {
        <#
            .DESCRIPTION
                Method for init required values of the Obj. Use $Verbose to set it desired output.
        #>
        if ($Verbose) {
            $this.verbose = $true
        }
        $this.inner_WriteVerbose("=== Starting PBIX Cls inner_Init ===")
        
        # setting up required modules        
        $this.inner_WriteVerbose(">>> Setting up Required Modules...")
        @('ImportExcel') | ForEach-Object {
            if (-not (Get-Module $_ -ListAvailable)) { Install-Module -Name $_ }
            else { $this.inner_WriteVerbose( "module '$_' is already installed..." ) }
        }        
        
        $this.inner_WriteVerbose( ">>> Setting up Properties... " )
        if ($jprop -ne "") {
            $junpacked = $jprop | ConvertFrom-Json
            
            $this.filtersLine_Y = $junpacked.filtersLine_Y
            $this.firstLine_Y = $junpacked.firstLine_Y
            $this.secondLine_Y = $junpacked.secondLine_Y            
        }
        else {
            $this.filtersLine_Y = 10
            $this.firstLine_Y = 150
            $this.secondLine_Y = 300
        }
        
        $this.inner_WriteVerbose( ">>> Updating Data from Management Excle file..." )
        # setting properties
        $this.projectRoot = (Get-ChildItem -Path ../.gitignore -r).DirectoryName
        $this.managementPlan = Import-Excel (Get-ChildItem -Path $this.projectRoot *plan.xlsx* -r) `
            -WorksheetName "Planned Objects" `
            -StartRow 3
        
        $this.pbix = (Get-ChildItem -Path ../*.pbix -Recurse)
        $this.pbit = (Get-ChildItem -Path ../*.pbit -Recurse)
        # Updating Tables in Manage Plan
        $this.managementPlan_UpdateManagementPlanTables();
        
        # setting personal aliases
        $this.inner_WriteVerbose( ">>> Setting personal Aliases..." )
        Set-Alias -Name touch -Value New-Item -Scope Global
        
        # wrapping the inner_Init up
        $this.inner_WriteVerbose( "=== PBIX Cls inner_Init Completed ===" )        
    }
    #--------------- Pbi-tools addressing  ----------------
    [void] pbiTools_Build() {
        <#
            .DESCRIPTION
                Compile PBIT from pbi-tools JSON model, launch PBIT. If Compillation was successful, data will start refresh
        #>    

        #SR: getting pbit
        
        $pbit_O = (Get-Item $this.pbit)
        $base_path = $pbit_O.DirectoryName #SR: for some reason $this.pbix contains only FullPath, not the Obj itself

        #SR: getting metadata dir
        $md_dir = ($pbit_O.FullName -split "\\" ) #get Arr of folder path
        $md_dir = ($md_dir[$md_dir.Count - 1] -split ".pbit")[0] #from last el /pbix name/ get name wo extension

        # $tmp = "$base_path\$md_dir" #* for debugging only
        
        #SR: compiling .pbit and launching #++
        $res = pbi-tools compile-pbix -folder "$base_path\$md_dir" `
            -outPath "$base_path" `
            -format PBIT -overwrite;     

        #SR: if having Errs while compile
        $substrings_list = @("Error", "Global")
        if (($substrings_list | ForEach-Object { ($res -join "").contains($_) }) -contains $true) {
            Write-Host ">>> Error: `n"; 
            Write-Host ($res -join " <<>> ")
            throw
        }
        else {
            $this.inner_WriteVerbose(">>> PBIT: Compiled successfully: `n"); $this.inner_WriteVerbose( $("-" * 50)   )
            $this.inner_WriteVerbose("$res `n"); $this.inner_WriteVerbose( $("-" * 50) )
        }
        
        #SR: launching
        $this.inner_WriteVerbose(">>> PBIT: Launched... `n"); $this.inner_WriteVerbose( $("-" * 50)   )
        pbi-tools.exe launch-pbi $this.pbit
    }
    [void] pbiTools_Launch() { $this.pbiTools_Launch("") } # method overload to solve omittable param. $pbixType=$null doesn't work
    [void] pbiTools_Launch($pbixType) {
        <#
            .DESCRIPTION
                Launches PBI file. Arg $pbixType = {"pbix" | "", "pbit"}
                Example: $pbix.pbiTools_Launch("pbix") #$pbix --> object; "pbix" same as "" OR "pbit" --> type of the file that is to be launched
        #>

        $trgFile = $null

        if ($pbixType -eq "" -or $pbixType -eq "pbix") {
            $trgFile = $this.pbix
        }
        elseif ($pbixType -eq "PBIT") {
            $trgFile = $this.pbit
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

        $this.inner_WriteVerbose( ">>> File '$fileName' was launched..." )
    }
    [void] pbiTools_WatchMode() {
        #SR: Turning ON the watch mode
        $PrId = (pbi-tools.exe info | ConvertFrom-Json).pbiSessions.ProcessId

        if ($null -eq $PrId) {
            Write-Output "`n"
            throw ">>> pbiTools_Launch .pbix first, attach Watch Mode only after that..."
        }

        $this.inner_WriteVerbose(">>> Watch Mode is on. Save report in PBI and see changes in a VS Code Git Tab")
        $this.inner_WriteVerbose("--> Ctrt + C to Quit Watch Mode")
        
        pbi-tools.exe extract -pid $PrId -watch
    }

    #---------------- managerment Plan --------------------
    [void] managementPlan_UpdateManagementPlanTables() {    
        <#
            .DESCRIPTION
                Method for updating "Specification" record in each of the tables in PBI --> PQ
        #>    
        
        # gettign content of mgm xlsFile -- only Tables
        #   1. updating mgm Plan --> this Meth is called directly, so it implies that mgm Plan was updated and is to be re-loaded
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

    #---------------- Git Automating --------------------
    [void] git_NewBranch() {
        #TODO: 	New Branch 
        #       ask for BrName
        $branchName = Read-Host -Prompt "Input name of new branch... ( [Q] to cancel ) --> "
        if ($branchName -eq "Q") { break }

        git checkout -b $branchName
    }
    
    [void] git_Commit() {
        #TODO:	Stage; Commit 
        #   Show changes
        $this.inner_WriteVerbose(">>> Files Changed or Created...")
        $res = @(); $res += git diff --stat; $res += git status -s -u  
        write-host ("-" * 50 + "`n") ;  
        $res | ForEach-Object {Write-Host $_ }
        write-host ("`n"+"-" * 50 ) ;  
        
        if ((Read-Host -Prompt "Proceed Committing? [Y] / N ") -eq "N"  ) { break }
        
        #   staging
        git add -A
        $this.inner_WriteVerbose(">>> Files Staged...")

        #   Committing
        Write-Host "Insert Commit Message ([Q] to cancel, [Enter] to open new line, [end] to finish input) --> "
        $commMessage = ""
        while (1) { $newline = read-host ;  if ($newline -eq "end") {break}; $commMessage+="$newline `n";}
        $commMessage = $commMessage.Trim()
        
        if ($commMessage -eq "Q") { break }
        
        git commit -a -m $commMessage
        $this.inner_WriteVerbose(">>> Committed successfully")
    }
    [void] git_Sync() {
        #   Synching
        if ((Read-Host -Prompt "Sync with Remote? [Y] / N") -eq "N") { break }
        
        git pull
        git push origin -u
    }
    [void] git_MergeToMain() {
        #TODO:	Merge to Master should be done by TL only]
        $currBranch = git branch --show-current
        $cbUpper = $currBranch.ToUpper()
        if ((Read-Host -Prompt "Are you sure want to merge current branch >> $cbUpper << into main? [Y] / N") -eq "N") { break }
        
        
        
        git checkout main
        # git pull
        # git merge $currBranch
        # git push main
        git checkout $currBranch
    }

    
} # } PBIX Class
