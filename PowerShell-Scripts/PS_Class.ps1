#SR: this is PowerShell Class to handle interactions with pbi-tools splitted .pbx

class PBIX {

    #PROPERTIES
    [int]$filtersLine_Y;     
    [int]$firstLine_Y;     
    [int]$secondLine_Y
    
    #CONSTRUCTOR default
    PBIX() {
            $this.filtersLine_Y = 10
            $this.firstLine_Y = 150
            $this.secondLine_Y = 300
         
            $this.Init()
        }
    #CONSTRUCTOR params
    PBIX(
        [int]$fltr, 
        [int]$fLine, 
        [int]$secLine        
        ) {
            $this.filtersLine_Y = $fltr
            $this.firstLine_Y = $fLine
            $this.secondLine_Y = $secLine          
         
            $this.Init()
        }
    
    #METHODS    
    [void] Init() {
        # SR: setting starting Environment
        $modulesList = @('ImportExcel')
        $modulesList | ForEach-Object 
        if (-not (Get-Module ImportExcel -ListAvailable)) {
            Install-Module -Name ImportExcel
        }
        
        Set-Alias -Name touch -Value New-Item -Scope Global
        
        Write-Host ">>> Class Init Completed..."
    }

}