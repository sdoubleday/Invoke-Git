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
            DefaultParameterSetName='Default'
            )]

    [Parameter(
        HelpMessage="Pick something from the list.",
        ParameterSetName='Default',
        Position = 0)] 
    [ValidateSet(
     'status'  <#status = Listing of Uncommitted files#>
    ,'status-short'  <#status-short = Status in short form#>
    ,'status-AsObject' <#status-AsObject = Converting strings into actual, useful things#>
    ,'stage-gridview'  <#stage-gridview = Simple interactive add to staging#>
    ,'stage-modified'  <#stage-modified = All previously committed and now modified files are added to staging.#>
    ,'unstage-gridview' <#unstage-gridview = Simple interactive reset HEAD#>
    ,'commit'      <#commit = Prompts for message and then commits staging area#>
    ,'amend'       <#amend = Overwrite the prior commit#>
    ,'diff-WdToStaged' <#diff-WdToStaged = differential of working directory to the staged files#>
    ,'diff-StagedToCommitted' <#diff-StagedToCommitted = differential of staged files to committed files.#>
    ,'log-lastFive'   <#log-lastFive = View last five commit details.#>
    ,'log-graph'   <#log-graph = git log --oneline --decorate --graph --all #>
    ,'view-config' <#view-config = List configuration values#>
    ,'revertWdToCommitted-gridview' <#Checks out the most recent commit to overwrite the target file.#>
    
    ,'tags-lastAsObject'                <#tags-lastAsObject = Get the last tag As Object (for use in the following commands).#>
    ,'tag-TertiaryVersionPlusPlus'      <#tag-TertiaryVersionPlusPlus = For tagging versions - x.x.1 to x.x.2 . #>
    ,'tag-MinorVersionPlusPlus'         <#tag-MinorVersionPlusPlus =  For tagging versions - x.1.x to x.2.0 . #>
    ,'tag-MajorVersionPlusPlus'         <#tag-MajorVersionPlusPlus =  For tagging versions - 1.x.x to 2.0.0 . #>
    ,'tag-ZZZVersion0dot0dot1'          <#tag-ZZZVersion0dot0dot1 =   Initial tag - 0.0.1 . #>
    ,'list-remote' <#list-remote = list the remotes.#>
    ,'get-branch'  <#get-branch = list the branches.#>

    ,'push-to-remote' <#push-to-remote = Push commits to a remote. Requires Remote parameter.#>
    ,'fetch-from-remote' <#fetch-from-remote = Fetches from a remote. Requires Remote parameter.#>

    ,'add-remote' <#add-remote = adds a new remote. Requires Remote and RemoteUrl parameters.#>

    ,'new-branch'      <#new-branch = Creates a new branch. Requires the Branch parameter.     #>
    ,'set-branch'      <#set-branch = Switches to an existing branch. Requires the branch parameter.     #>
    ,'merge-fromBranch'<#merge-fromBranch = Merges commits in from an existing branch. Requires the Branch Parameter.#>

    )]$GitCommand

)

DynamicParam {
    
    $array = @()
    IF ($GitCommand -in ('push-to-remote','fetch-from-remote') ) {$array += New-DynamicParameter -Name 'Remote' -Type String -Mandatory -ValidateSet @(git remote) }
    IF ($GitCommand -in ('add-remote') ) {$array += New-DynamicParameter -Name 'Remote' -Type String -Mandatory ; $array += New-DynamicParameter -Name 'RemoteURL' -Type String -Mandatory}
    IF ($GitCommand -in ('new-branch') ) {$array += New-DynamicParameter -Name 'Branch' -Type String -Mandatory}
    IF ($GitCommand -in ('set-branch','merge-fromBranch') ) {$array += New-DynamicParameter -Name 'Branch' -Type String -Mandatory -ValidateSet ( @(git branch -a).Replace('*','').TrimStart() ) }
    
    $array | New-DynamicParameterDictionary 

}<#End Dynamic Parameters#>

BEGIN {}
PROCESS {

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
        'list-remote'       {git remote --verbose}
        'get-branch'          {git branch}

        'push-to-remote'    {git push $PSBoundParameters['Remote']}
        'fetch-from-remote' {git fetch $PSBoundParameters['Remote']}
        
        'add-remote'        {write-verbose $PSBoundParameters['Remote'];write-verbose $PSBoundParameters['RemoteURL']; git remote add $PSBoundParameters['Remote'] $PSBoundParameters['RemoteURL']}

        'new-branch'          {git branch $PSBoundParameters['Branch']}
        'set-branch'          {git checkout $PSBoundParameters['Branch']}
        'merge-fromBranch'    {git merge $PSBoundParameters['Branch']}
    }<#End Switch#>


}<#End Process#>

END{}<#End End#>

}<#END Invoke-Git#>

New-Alias -Name gitgit -Value Invoke-Git -Force
New-Alias -Name gitg -Value Invoke-Git -Force

Export-ModuleMember -Function "Invoke-Git"
Export-ModuleMember -Alias "gitgit"
Export-ModuleMember -Alias "gitg"
