# 📝SR[2023-01-13]: at current moment I don't see necessity to have a wrapper for Classes to address them like $wr.pbit, $wr.git...
# 📝    classes seem to be quite independent and self-sufficient

# ================= !!! ====================
$h = @{ID="x1" ; DoStuff = $Null }
$h.DoStuff = { $args[0] * $args[1] }
# note that $h = @{ID="x1" ; DoStuff = {$args[0] * $args[1]} } works as well


# Invoke your block : 
& $h.DoStuff 6 7
# ================= !!! ====================

if ($true) {
    <# Action to perform if the condition is true #>
}

$a = {
    param($param)
    Write-Output $param
}

&$a "Hello-world"

# -----------------------------------
