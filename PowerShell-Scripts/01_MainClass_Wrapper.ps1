function a { cw 'writing a' }
function b { cw 'writing b' }
function c { cw 'writing c' } 

# trick with [PsCustomObject] does not solve the issue, as I'm getting an Object again))) So, addressing its methods is totally the same as addressing $pbx.something()
#this works. #TODO: check for parameters accuracy

$func = @{}
"a","b","c" | % {$func += @{$_ = Get-Command -Name $_}}
