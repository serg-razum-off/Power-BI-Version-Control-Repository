function a {
    <#
    .SYNOPSIS
    This function writes a string to the console.

    .DESCRIPTION
    The function takes an optional string parameter, which must be either "one" or "two". If no parameter is provided, the default value "one" is used. The function then writes the value of the string to the console.

    .EXAMPLE
    a -str "two"
    This example writes the string "two" to the console.

    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [validateset("one", "two")]
        [string] $str = "one"
    )
    cw "writing a => $str"
}
# docstring above works

function b { cw 'writing b' }
function c { cw 'writing c' } 

# trick with [PsCustomObject] does not solve the issue, as I'm getting an Object again))) So, addressing its methods is totally the same as addressing $pbx.something()
#this works. #TODO: check for parameters accuracy

$func = @{}
"a", "b", "c" | ForEach-Object { $func += @{$_ = Get-Command -Name $_ } }
