class MyClass
{
    MyClass($arg1, $arg2)
    {
        $this.MyMethod($arg1, $arg2)
    }

    MyMethod($arg1, $arg2)
    {
        Write-Host "Argument 1: $arg1"
        Write-Host "Argument 2: $arg2"
    }
}

$a = [MyClass]::new(1,2)