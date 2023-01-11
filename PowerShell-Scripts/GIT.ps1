class GIT {
    <#
        SR [06-01-2023]: 
            This class contains methods for automating git CLI commands.
        params: 
            $auto --> is used in methods to escape user interactions during perfoming GIT actions
        example:
            1. 
                $obj = [git]::new($true, $false)
            2. 
                $params = @{_auto=$true; _verbodse=$false} | % {$_.values} #--> pass named parameters
                $obj = [git]::new($params)
     #>

    # Property to control user interactions
    [bool] $auto
    [bool] $verbose
    [string] $main_branch_name = ( git symbolic-ref refs/remotes/origin/HEAD ).split('/')[-1]
    [scriptblock] $writeVerboseFunction

    # Constructors
    GIT() {
        $this.auto = $true
        $this.verbose = $false            
        $this.SetVerbose()
    }
    # for named parameters
    GIT( [hashtable]$params) {
        $this.auto = $null -eq $params['_auto'] ? $true : $params['_auto']
        $this.verbose = $null -eq $params['_verbose'] ? $true : $params['_verbose']
        $this.SetVerbose()
    }

    [void] SetVerbose() {
        if ($this.verbose) {
            $this.writeVerboseFunction = { 
                param($message)
                Write-Host -ForegroundColor Yellow "VERBOSE:" $message
            } 
        }
        else {
            $this.writeVerboseFunction = { 
                param($message)
                Write-Verbose $message
            } 
        }
        & $this.writeVerboseFunction ">>> GIT Class Inited <<<"
    }
    
    #---------------- Git Automating --------------------
    [void] ShowBranches() { 
        Write-Host ">>> Branches: "; Write-Host("-" * 50)
        $branches = git branch
        $branches | ForEach-Object { Write-Host $_ }        
        Write-Host("-" * 50)
    }
    [void] SwitchBranch() { $this.SwitchBranch("") }
    [void] SwitchBranch([string]$branchName) {
        #   Switching Branch
        & $this.writeVerboseFunction ">>> SwitchBranch <<<"
        
        $this.ShowBranches()        
        if ($branchName -eq "") {
            git checkout (Read-Host -Prompt ">>> Enter branch name: ")
            break
        }
        git checkout $branchName        
        $this.ShowBranches()
    }
    [void] NewBranch() { $this.NewBranch("") }
    [void] NewBranch([string]$branchName) {
        & $this.writeVerboseFunction ">>> NewBranch <<<"
        if (
            (Read-Host -Prompt ">>> You are branching from: | $(git branch --show-current) |. 'Q' to Cancel, [Y] to continue") `
                -in @("Q", "N", "end")
        ) { break }
    
        if ($branchName -eq "") {
            #       ask for BrName
            $branchName = Read-Host -Prompt "Input name of new branch... ( 'Q' to cancel ) --> "
            if ($branchName -eq "Q") { break }
        }
        
    
        git checkout -b $branchName
    
    }    
    [void] Commit() { $this.Commit("", $true) }
    [void] Commit([string]$commitMessage, [bool]$auto) {
        #   Show changes
        Write-Verbose (">>> Commit on Branch |" + ( git branch --show-current ) + "|" + " <<<")
    
        
        if (!$auto) {
            Write-Verbose (">>> Inspect files changed on VS Code Source Control Tab if needed...")
            if ((Read-Host -Prompt "Proceed Committing? [Y] / N ") -in @("N", "Q", "end")  ) { break }
    
        }        
        #   staging
        git add -A
        Write-Verbose (">>> Files Staged...")
    
        #   Committing
        $commMessage = ""
        if ($commitMessage -eq "") {
            Write-Host "Insert Commit Message ('Q' to cancel, [Enter] to open new line, 'end' to finish input) --> "
            while (1) { $newline = read-host ; if ($newline -eq "end") { break }; $commMessage += "$newline `n"; }
            $commMessage = $commMessage.Trim()
            
            if ($commMessage -eq "Q") { break }
        }
        else {
            $commMessage = $commitMessage
        }
        
        git commit -a -m $commMessage
        Write-Verbose (">>> Committed successfully")
    }   
    [void] SyncBranch() { $this.SyncBranch($true) }
    [void] SyncBranch([bool]$auto) {
        #   Synching current brach
        Write-Verbose (">>> SyncBranch <<<")
    
        if (!$auto) {
            if ((Read-Host -Prompt "Sync with Remote? [Y] / N") -eq "N") { break }
    
        }        $currBranch = git branch --show-current
        
        git pull origin $currBranch
        git push origin $currBranch
    }
    [void] MergeToMain([string]$param) {
        #   Merge of current branch to Master --> can be done by priviliged users only
        Write-Verbose (">>> SyncBranch <<<")
    
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
    [void] MergeFromMain() {
        #	Merge from Master to current branch --> to FF other developers' changes
        Write-Verbose (">>> MergeFromMain <<<")
    
        $currBranch = git branch --show-current
        $cbUpper = $currBranch.ToUpper()
        if ((Read-Host -Prompt "Are you sure want to merge Main into >> $cbUpper << ? [Y] / N") -eq "N") { break }
        
        git checkout main
        git pull
        git checkout $currBranch
        git merge main    
    }
}