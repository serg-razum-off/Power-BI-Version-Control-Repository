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
                #REFACTOR: #⚠ : move methods from clusters to separate functions, to have dot notation for them. => $this.pbiTools.<methodName>

        .EXAMPLE
            $pbix = [pbix]::new()
            $pbix = [pbix]::new(10, 175, 325, $false)
    #>
    
    #============ #PROPERTIES ================================
    #for searches cat's and ls's
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
        
        # 📝setting personal aliases:
        #       Setting aliases with Class -- to have it run on every environm.  
        #       Setting with $profile will require $profile modification on every env
        $this.inner_WriteVerbose( ">>> Setting personal Aliases..." )
        Set-Alias -Name touch -Value New-Item -Scope Global
        
        # wrapping the inner_Init up
        $this.inner_WriteVerbose( "=== PBIX Cls inner_Init Completed ===" )
        
    }
    #--------------- Pbi-tools addressing  ----------------
    #   docs for pbi-tools: https://pbi.tools/ ; https://pbi.tools/tutorials/getting-started-cli.html 
    [void] pbiTools_Extract() {
        <#
            .DESCRIPTION
                Extracts PBI-JSON structured Metadata from .pbix file
        #> 
        #SR: getting pbix        
        $pbix_O = (Get-Item $this.pbix)
        $base_path = $pbix_O.DirectoryName #SR: for some reason $this.pbix contains only FullPath, not the Obj itself
 
        #SR: getting metadata dir
        $md_dir = ($pbix_O.FullName -split "\\" ) #get Arr of folder path
        $md_dir = ($md_dir[$md_dir.Count - 1] -split ".pbit")[0] #from last el /pbix name/ get name wo extension

        # check if Dir exists
        if ( -not (Test-Path "$base_path\$md_dir")  ) {
            New-Item -ItemType Directory -Path "$base_path\$md_dir"
        }

        pbi-tools extract -pbixPath $this.pbix -extractFolder "$base_path\$md_dir" 
    }
    
    [void] pbiTools_Build() {
        <#
            .DESCRIPTION
                Compile PBIT from pbi-tools JSON model, launch PBIT. If Compillation was successful, data will start refresh
        #>    

        #SR: getting pbix location -- PBIT will be compiled to that folder,         
        $pbix_O = (Get-Item $this.pbix)
        $base_path = $pbix_O.DirectoryName #SR: $this.pbix contains only FullPath, not the Obj itself

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
        try {
            $PrId = (pbi-tools.exe info | ConvertFrom-Json).pbiSessions.ProcessId
        }
        catch {
            throw ">>> use method pbiTools_Launch to start .pbix first, attach Watch Mode only after that..."
        }

        $this.inner_WriteVerbose(">>> Watch Mode is on. Save report in PBI and see changes in a VS Code Git Tab")
        $this.inner_WriteVerbose("--> Ctrt + C to Quit Watch Mode")
        
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

    #---------------- Git Automating --------------------
    #📚     README: all Git Methods are equipped with empty callers -- when no param is passed, method is called from the outside as: $this.git_myMethod()
    [void] git_ShowBranches() { 
        Write-Host ">>> Branches: "; Write-Host("-" * 50)
        $branches = git branch
        $branches | ForEach-Object { Write-Host $_ }        
        Write-Host("-" * 50)
    }
    [void] git_SwitchBranch() { $this.git_SwitchBranch("") }
    [void] git_SwitchBranch([string]$param) {
        #   Switching Branch
        $this.inner_WriteVerbose(">>> git_SwitchBranch <<<")
        
        $this.git_ShowBranches()        
        if ($param -eq "") {
            git checkout (Read-Host -Prompt ">>> Enter branch name: ")
            break
        }
        git checkout $param        
        $this.git_ShowBranches()
    }
    [void] git_NewBranch() { $this.git_NewBranch("") }
    [void] git_NewBranch([string]$param) {
        $this.inner_WriteVerbose(">>> git_NewBranch <<<")
        if (
            (Read-Host -Prompt ">>> You are branching from: | $(git branch --show-current) |. 'Q' to Cancel, [Y] to continue") `
                -in @("Q", "N", "end")
        ) { break }

        if ($param -eq "") {
            #       ask for BrName
            $branchName = Read-Host -Prompt "Input name of new branch... ( 'Q' to cancel ) --> "
            if ($branchName -eq "Q") { break }
        }
        else {
            $branchName = $param
        }

        git checkout -b $branchName

    }    
    [void] git_Commit() { $this.git_Commit("", $true) }
    [void] git_Commit([string]$param, [bool]$auto) {
        #   Show changes
        $this.inner_WriteVerbose(">>> git_Commit on Branch |" + ( git branch --show-current ) + "|" + " <<<")

        
        if (!$auto) {
            $this.inner_WriteVerbose(">>> Inspect files changed on VS Code Source Control Tab if needed...")
            if ((Read-Host -Prompt "Proceed Committing? [Y] / N ") -in @("N", "Q", "end")  ) { break }
	
        }        
        #   staging
        git add -A
        $this.inner_WriteVerbose(">>> Files Staged...")

        #   Committing
        $commMessage = ""
        if ($param -eq "") {
            Write-Host "Insert Commit Message ('Q' to cancel, [Enter] to open new line, 'end' to finish input) --> "
            while (1) { $newline = read-host ; if ($newline -eq "end") { break }; $commMessage += "$newline `n"; }
            $commMessage = $commMessage.Trim()
	        
            if ($commMessage -eq "Q") { break }
        }
        else {
            $commMessage = $param
        }
        
        git commit -a -m $commMessage
        $this.inner_WriteVerbose(">>> Committed successfully")
    }   
    [void] git_SyncBranch() { $this.git_SyncBranch($true) }
    [void] git_SyncBranch([bool]$auto) {
        #   Synching current brach
        $this.inner_WriteVerbose(">>> git_SyncBranch <<<")

        if (!$auto) {
            if ((Read-Host -Prompt "Sync with Remote? [Y] / N") -eq "N") { break }
	
        }        $currBranch = git branch --show-current
        
        git pull origin $currBranch
        git push origin $currBranch
    }
    [void] git_MergeToMain([string]$param) {
        #   Merge of current branch to Master --> can be done by priviliged users only
        $this.inner_WriteVerbose(">>> git_SyncBranch <<<")

        $currUser = git config user.email
        $allowMergeMain = $false

        $privilegedUsers = Import-Excel (Get-ChildItem -Path $this.projectRoot *plan.xlsx* -r) `
            -WorksheetName "PrivelegedUsers" `
            -StartRow 1

        ( $privilegedUsers | Where-Object { $_.MergeMain -eq $true } ).User `
        | ForEach-Object { 
            if ($_ -eq $currUser) { $allowMergeMain = $true ; break } 
        }

        if (!$allowMergeMain) { Write-Host ">>> No Access to this Method..."; break }

        $currBranch = git branch --show-current
        $cbUpper = $currBranch.ToUpper()
        if ((Read-Host -Prompt "Are you sure want to merge current branch >> $cbUpper << into main? [Y] / N") -eq "N") { break }
        
        git checkout main
        git pull
        git merge $currBranch
        git push origin main
        git checkout $currBranch
    }    
    [void] git_MergeFromMain() {
        #	Merge from Master to current branch --> to FF other developers' changes
        $this.inner_WriteVerbose(">>> git_MergeFromMain <<<")

        $currBranch = git branch --show-current
        $cbUpper = $currBranch.ToUpper()
        if ((Read-Host -Prompt "Are you sure want to merge Main into >> $cbUpper << ? [Y] / N") -eq "N") { break }
        
        git checkout main
        git pull
        git checkout $currBranch
        git merge main    
    }
} 
