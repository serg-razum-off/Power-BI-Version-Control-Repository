#SR: this is PowerShell Class to handle interactions with pbi-tools --> splitted .pbx

class PBIX {

    #============ #PROPERTIES ================================
    [int]$filtersLine_Y;     
    [int]$firstLine_Y;     
    [int]$secondLine_Y
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
    [void] Init([string]$jprop, [bool]$Verbose) {
        
        ## SR:  setting starting Environment        
        if ($Verbose) { $VerbosePreference = "Continue" }
        Write-Verbose ">>> Starting PBIX Cls Init <<<"

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
                
        # SR:   setting modules
        @('ImportExcel') | ForEach-Object {
            if (-not (Get-Module $_ -ListAvailable)) 
            { Install-Module -Name $_ }
            else 
            { Write-Verbose "module '$_' is already installed..." }
        }                
        # SR:   setting aliases
        Set-Alias -Name touch -Value New-Item -Scope Global
        
        Write-Verbose ">>> PBIX Cls Init Completed <<<"

        if ($Verbose) { $VerbosePreference = 'SilentlyContinue' }
         
    }

}
