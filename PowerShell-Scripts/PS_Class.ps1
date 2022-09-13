class PBIX {
    <#
        .AUTHOR
            sergiy.razumov@gmail.com
        .DESCRIPTION
            PowerShell Class to handle interactions with pbi-tools --> JSON splitted .pbx 
            One Proj for one pbi file --> number of changes is high. Several pbixes in one proj will mess up VC
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
        $this.Init("", $this.verbose)
    }
    #verbose
    PBIX($configString, $verbose) { 
        # $configString -- all 3 Y params: "{'filtersLine_Y':$filtersLine_Y, 'firstLine_Y':$firstLine_Y, 'secondLine_Y':$secondLine_Y}",
        $this.Init("", $verbose)
    }
    #param
    PBIX(
        [int]$filtersLine_Y, 
        [int]$firstLine_Y, 
        [int]$secondLine_Y,
        [bool]$verbose = $null 
    ) {         
        $this.Init(
            "{'filtersLine_Y':$filtersLine_Y, 'firstLine_Y':$firstLine_Y, 'secondLine_Y':$secondLine_Y}",
            $verbose
        )
    }
    
    #=============== #METHODS =============================    
    #-----------------------------------------------------
    hidden [void] WriteVerbose([string]$message) {
        # Printing Verbose messages
        if ($this.verbose) { 
            $VerbosePreference = "Continue" 
            Write-Verbose( "$message" )
            $VerbosePreference = 'SilentlyContinue' 
        }           
    }
    hidden [void] Init([string]$jprop, [bool]$Verbose) {
        <#
            .DESCRIPTION
                Method for init required values of the Obj. Use $Verbose to set it desired output.
        #>
        if ($Verbose) {
            $this.verbose = $true
        }
        $this.WriteVerbose("=== Starting PBIX Cls Init ===")
        
        # setting up required modules        
        $this.WriteVerbose(">>> Setting up Required Modules...")
        @('ImportExcel') | ForEach-Object {
            if (-not (Get-Module $_ -ListAvailable)) { Install-Module -Name $_ }
            else { $this.WriteVerbose( "module '$_' is already installed..." ) }
        }        
        
        $this.WriteVerbose( ">>> Setting up Properties... " )
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
        
        $this.WriteVerbose( ">>> Updating Data from Management Excle file..." )
        # setting properties
        $this.projectRoot = (Get-ChildItem -Path ../.gitignore -r).DirectoryName
        $this.managementPlan = Import-Excel (Get-ChildItem -Path $this.projectRoot *plan.xlsx* -r) `
            -WorksheetName "Planned Objects" `
            -StartRow 3
        
        $this.pbix = (Get-ChildItem -Path ../*.pbix -Recurse)
        $this.pbit = (Get-ChildItem -Path ../*.pbit -Recurse)
        # Updating Tables in Manage Plan
        $this.UpdateManagementPlanTables();
        
        # setting personal aliases
        $this.WriteVerbose( ">>> Setting personal Aliases..." )
        Set-Alias -Name touch -Value New-Item -Scope Global
        
        # wrapping the Init up
        $this.WriteVerbose( "=== PBIX Cls Init Completed ===" )        
    }
    #-----------------------------------------------------
    [void] Build() {
        <#
            .DESCRIPTION
                Compile PBIT from pbi-tools JSON model, launch PBIT. If Compillation was successful, data will start refresh
        #>    

        #SR: getting pbit
        $this.pbit = Get-ChildItem -Path $this.projectRoot *.pbit -Recurse
        $base_path = $this.pbit.DirectoryName

        #SR: getting metadata dir
        $md_dir = ($this.pbit.FullName -split "\\" ) 
        $md_dir = ($md_dir[$md_dir.Count - 1] -split ".pbit")

        #SR: compiling .pbit and launching it
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
            $this.WriteVerbose(">>> Compiled successfully: `n"); $this.WriteVerbose( $("-" * 100)   )
            $this.WriteVerbose("$res `n"); $this.WriteVerbose( $("-" * 100) )
        }

        #SR: launching
        pbi-tools.exe launch-pbi $this.pbit.FullName
    }
    [void] Launch() { $this.Launch("") } # method overload to solve omittable param. $pbixType=$null doesn't work
    [void] Launch($pbixType) {
        <#
            .DESCRIPTION
                Launches PBI file. Arg $pbixType = {"pbix" | "", "pbit"}
                Example: $pbix.Launch("pbix") #$pbix --> object; "pbix" same as "" OR "pbit" --> type of the file that is to be launched
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

        $this.WriteVerbose( ">>> File '$fileName' was launched..." )
    }
    [void] WatchMode() {
        #SR: Turning ON the watch mode
        $PrId = (pbi-tools.exe info | ConvertFrom-Json).pbiSessions.ProcessId

        if ($null -eq $PrId) {
            Write-Output "`n"
            throw ">>> Launch .pbix first, attach Watch Mode only after that..."
        }

        $this.WriteVerbose(">>> Watch Mode is on. Save report in PBI and see changes in a VS Code Git Tab")
        $this.WriteVerbose("--> Ctrt + C to Quit Watch Mode")
        
        pbi-tools.exe extract -pid $PrId -watch
    }

    [void] UpdateManagementPlanTables() {    
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

            # if Specification is already filled up, skip to next $xsl item
            if (([regex]::Match((Get-Content $path), $pattern)).Length -gt 200) {
                # continue ##! impoertant: if Specification is not updated, we will lose changes, that were potentially made in it
            }
            
            # writing to the target file
            (Get-Content $path) -join "`n" `
                -replace $pattern, ($required_qwr + $endingComma) `
            | Set-Content $path
        }        
    } # } UpdateManagementPlanTables
    
} # } PBIX Class
