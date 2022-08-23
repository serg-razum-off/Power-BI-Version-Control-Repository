#SR: this is PowerShell Class to handle interactions with pbi-tools splitted .pbx

class Pbix {

    #properties
    [int]$filtersLine_Y
    [int]$firstLine_Y
    [int]$secondLine_Y
    
    #Constructor
    Pbix(
        [int]$fltr, 
        [int]$fLine, 
        [int]$secLine
        
        ) {
            $this.filtersLine_Y = $fltr
            $this.firstLine_Y = $fLine
            $this.secondLine_Y = $secLine          
         
            $this.Init()
        }
    
    #methods    

    [void] Init() {
        Set-Alias -Name touch -Value New-Item -Scope Global
        Write-Host ">>> Init Completed..."
    }

}