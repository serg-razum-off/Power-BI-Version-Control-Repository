class PBIX {
    <#
        .AUTHOR
            sergiy.razumov@gmail.com
        .SYNOPSYS
            PowerShell Class to handle interactions with pbi-tools --> splitted .pbx
        .EXAMPLE
            $pbix = [pbix]::new()
            $pbix = [pbix]::new(10, 175, 325, $false)
    #>
    #============ #PROPERTIES ================================
    # for searches
    [string]$projectRoot = (Get-ChildItem .gitignore -r).DirectoryName
    # For lining up visual
    [int]$filtersLine_Y;     
    [int]$firstLine_Y;     
    [int]$secondLine_Y
    # for dummy tables and measures creation    
    [array]$managementPlan

    # for paramless Ctor. See TODO: on param Ctor -- use ommitable (below)
    [bool]$verbose = $false 
    
    #============== #CONSTRUCTORS ===========================
    #def
    PBIX() {
        $this.Init("", $this.verbose)
    }
    #param
    PBIX(
        [int]$filtersLine_Y, 
        [int]$firstLine_Y, 
        [int]$secondLine_Y,
        [bool]$verbose = $null #TODO: make this param ommitable -- IF this is possible
    ) {         
        $this.Init(
            "{'filtersLine_Y':$filtersLine_Y, 'firstLine_Y':$firstLine_Y, 'secondLine_Y':$secondLine_Y}",
            $verbose
        )
    }
    
    #=============== #METHODS =============================    
    #-----------------------------------------------------
    hidden [void] 
    Init([string]$jprop, [bool]$Verbose) {
        <#
            .SYNOPSYS
                Method for init required values of the Obj. Use $Verbose to set it desired output.
        #>
        Write-Verbose ">>> Starting PBIX Cls Init <<<"
        
        # SR:   setting up required modules        
        @('ImportExcel') | ForEach-Object {
            if (-not (Get-Module $_ -ListAvailable)) { Install-Module -Name $_ }
            else { Write-Verbose "module '$_' is already installed..." }
        }
        
        # SR:  setting starting Environment        
        if ($Verbose) { $VerbosePreference = "Continue" ; $this.verbose = $Verbose }

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
        
        # SR: calculatable properties
        $this.managementPlan = Import-Excel (Get-ChildItem -Path $this.projectRoot *.xls* -r) -StartRow 3
        # SR:   setting personal aliases
        Set-Alias -Name touch -Value New-Item -Scope Global
        
        # wrapping the Init up
        Write-Verbose ">>> PBIX Cls Init Completed <<<"        
        if ($Verbose) { $VerbosePreference = 'SilentlyContinue' }         
    }
    #-----------------------------------------------------
    
    [void] 
    UpdateManagementPlan() {    
        <#
            .SYNOPSYS
                Method for updating "Specification" record in each of the tables in PBI --> PQ
        #>    
        
        #gettign content of mgm xls file -- only Tables
        $xls = (Import-Excel (Get-ChildItem -Path $this.projectRoot *.xls* -r) -StartRow 3) | Where-Object {$_.'02_Type' -eq 'Table'}
        $objKeys = ($xls | Get-Member -MemberType NoteProperty).Name

        foreach ($xlsRecord in $xls) {
            
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
            if(([regex]::Match((cat $path), 'let.*Source = ') -replace " ", "").Length -eq 10) #there is no "Specification" step in PQ Qwr
                {
                    (cat $path) -join "`n" `
                        -replace "let(.|\n)*Source = ", `
"let
    Specification = [],
    Source = " | Set-Content $path
                }
            
            # Evaluating correct RegEx for replacement in PQwr
            $pattern = '\[(.|\n)?\]'; 
            if (([regex]::Match((Get-Content $path), $pattern)).Length -eq 0) { 
                $pattern = '\[(.|\n)*\]' 
            }

            # if Specification is already filled up, skip to next $xsl item
            if (([regex]::Match((Get-Content $path), $pattern)).Length -gt 200) {
                continue
            }
            
            # writing to the target file
            (Get-Content $path) -join "`n" `
                -replace $pattern, $required_qwr `
            | Set-Content $path
        }
        
    } # } UpdateManagementPlan
    
} # } PBIX Class
