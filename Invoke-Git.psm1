function Invoke-Git {
<#
.SYNOPSIS
Wrapper for basic CLI git. I alias this as gitgit.

.EXAMPLE
Preparing for a push to the remote:
gitgit -RemoteCommand fetch-from-remote -remote <RemoteName>
gitgit -GitCommand log-graph
gitgit -BranchCommand merge-fromBranch -Branch <RemoteName>/<BranchName>
gitgit -GitCommand log-graph
gitgit -RemoteCommand push-to-remote -Remote <RemoteName>

#>

PARAM(

    [CmdletBinding(
            DefaultParameterSetName='Default')]

    [Parameter(
        HelpMessage="Pick something from the list.",
        ParameterSetName='Default')] 
    [ValidateSet(
     'status'  <#Listing of Uncommitted files#>
    ,'status-short'  <#Status in short form#>
    ,'status-AsObject' <#Converting strings into actual, useful things#>
    ,'stage-gridview'  <#Simple interactive add to staging#>
    ,'stage-modified'
    ,'unstage-gridview' <#Simple interactive reset HEAD#>
    ,'commit'      <#Prompts for message and then commits staging area#>
    ,'amend'       <#Overwrite the prior commit#>
    ,'diff-WdToStaged'
    ,'diff-StagedToCommitted'
    ,'log-lastFive'   <#View last five commit details.#>
    ,'log-graph'   <# git log --oneline --decorate --graph --all #>
    ,'view-config'
    ,'revertWdToCommitted-gridview' <#Checks out the most recent commit to overwrite the target file.#>
    
    ,'tags-lastAsObject'                <#Last As Object#>
    ,'tag-TertiaryVersionPlusPlus'      <#For marking versions. #>
    ,'tag-MinorVersionPlusPlus'         <#For marking versions. #>
    ,'tag-MajorVersionPlusPlus'         <#For marking versions. #>
    ,'tag-ZZZVersion0dot0dot1'          <#For marking versions. #>
    ,'zzz-init'    <#Set up a repository at the current directory. Sorted to the end of the validate list.#>
    )]$GitCommand

    ,[Parameter(
        <#HelpMessage="",#>
        ParameterSetName='Remotes')] 
    [ValidateSet(
     'push-to-remote'
    ,'fetch-from-remote'
    ,'list-remote'
    )]$RemoteCommand
    ,[Parameter(
        <#HelpMessage="",#>
        ParameterSetName='AddRemote')]    
    [ValidateSet(
     'add-remote'
    )]$RemoteCommand_Add
    ,[Parameter(
        <#HelpMessage="",#>
        Mandatory=$true,
        ParameterSetName='Remotes')] 
    [Parameter(
        HelpMessage="For list-remote, type anything, it gets ignored.",
        Mandatory=$true,
        ParameterSetName='AddRemote')]
     [String]$Remote
    ,[Parameter(
        Mandatory=$true,
        HelpMessage="This only matters for adding new remotes.",
        ParameterSetName='AddRemote')] 
    [String]$RemoteUrl


    ,[Parameter(
        <#HelpMessage="",#>
        ParameterSetName='Branches')] 
    [ValidateSet(
    <#various branching and merging and undoing commands are needed.#>
     'new-branch'
    ,'set-branch'
    ,'get-branch' 
    ,'merge-fromBranch'
    )]$BranchCommand
    ,[Parameter(
        <#HelpMessage="",#>
        ParameterSetName='Branches')] 
    [String]$Branch
    

    )

IF($PSCmdlet.ParameterSetName -like "Default")
{
    SWITCH ($GitCommand)
    {
        'status'  <#Listing of Uncommitted files#>                              {git status}
        'status-short'  <#Status in short form#>                                {git status --short}
        'status-AsObject' <#Converting strings into actual, useful things#>     {git status --porcelain | select @{name="Path";expression={$_.Remove(0,3)}}, @{name="StagingStatus";expression={$_.Substring(0,1)}}, @{name="WorkingStatus";expression={$_.Substring(1,1)}}}
        'stage-gridview'  <#Simple interactive add to staging#>                 {Invoke-Git -GitCommand status-AsObject | Out-GridView -Title 'Pick Files to Stage for Commit' -OutputMode Multiple | ForEach-Object {git add $_.Path} }
        'stage-modified'  <#Ignores not-yet initially committed files#>         {Invoke-Git -GitCommand status-AsObject | Where-Object {$_.WorkingStatus -like "M"} | ForEach-Object {git add $_.Path}}
        'unstage-gridview'  <#Simple interactive reset HEAD#>                   {Invoke-Git -GitCommand status-AsObject | Out-GridView -Title 'Pick Files to Unstage from Pending Commit' -OutputMode Multiple | ForEach-Object {git reset HEAD $_.Path} }
        'commit'      <#Prompts for message and then commits staging area#>     {git commit}
        'amend'      <#Prompts for message and then recommits staging area#>    {git commit --amend}
        'diff-WdToStaged'                                                       {git diff}
        'diff-StagedToCommitted'                                                {git diff --staged}
        'log-lastFive'                                                          {git log -n 5}
        'log-graph'   <# git log --oneline --decorate --graph --all #>          {git log --oneline --decorate --graph --all}
        'view-config'                                                           {git config --list}
        'revertWdToCommitted-gridview' <#Checks out the most recent commit to overwrite the target file.#>        {Invoke-Git -GitCommand status-AsObject | Where-Object {$_.WorkingStatus -eq 'M'} | Out-GridView -Title 'Pick Files to REVERT to most recent Commit - CHANGES WILL BE LOST' -OutputMode Multiple | ForEach-Object {git checkout -- $_.Path} }
        'tags-lastAsObject'                <#Last As Object#>                                                     {$maxTag = @(git tag | Sort-Object -Descending)[0] -split '[.]',4 ; New-Object PSObject -Property @{MajorVersion=[Int]($maxTag[0]).Remove(0,1); MinorVersion=[Int]$maxTag[1]; TertiaryVersion=[Int]$maxTag[2]; ZOther=$maxTag[3]}}
        'tag-TertiaryVersionPlusPlus'      <#For marking versions. #>                                             {$a = Invoke-Git -GitCommand tags-lastAsObject ; git tag -a "v$($a.MajorVersion).$($a.MinorVersion).$($a.TertiaryVersion + 1)" }
        'tag-MinorVersionPlusPlus'         <#For marking versions. #>                                             {$a = Invoke-Git -GitCommand tags-lastAsObject ; git tag -a "v$($a.MajorVersion).$($a.MinorVersion + 1).0" }
        'tag-MajorVersionPlusPlus'         <#For marking versions. #>                                             {$a = Invoke-Git -GitCommand tags-lastAsObject ; git tag -a "v$($a.MajorVersion + 1).0.0" }
        'tag-ZZZVersion0dot0dot1'          <#For marking versions. #>                                             {git tag -a "v0.0.1" }
        'zzz-init'    <#Set up a repository at the current directory. Sorted to the end of the validate list.#>   {git init}
        
    }<#End Switch#>
}<#End IF($PSCmdlet.ParameterSetName -like "Default")#>

IF($PSCmdlet.ParameterSetName -like "Remotes")
{
    SWITCH ($RemoteCommand)
    {
        'push-to-remote'    {git push $Remote}
        'fetch-from-remote' {git fetch $Remote}
        'list-remote'       {git remote --verbose}
    }<#End Switch#>

}<#End IF($PSCmdlet.ParameterSetName -like "Remotes")#>

IF($PSCmdlet.ParameterSetName -like "AddRemote")
{
    SWITCH ($RemoteCommand_Add)
    {
        'add-remote'        {git remote add $Remote $RemoteURL}
    }<#End Switch#>

}<#End IF($PSCmdlet.ParameterSetName -like "AddRemote")#>


IF($PSCmdlet.ParameterSetName -like "Branches")
{
    SWITCH ($BranchCommand)
    {
        'new-branch'          {git branch $Branch}
        'set-branch'          {git checkout $Branch}
        'get-branch'          {git branch}
        'merge-fromBranch'    {git merge $Branch}
    }<#End Switch#>

}<#End IF($PSCmdlet.ParameterSetName -like "Branches")#>


}<#END Invoke-Git#>

New-Alias -Name gitgit -Value Invoke-Git -Force
New-Alias -Name gitg -Value Invoke-Git -Force

Export-ModuleMember -Function "Invoke-Git"
Export-ModuleMember -Alias "gitgit"
Export-ModuleMember -Alias "gitg"
