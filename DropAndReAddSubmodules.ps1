#Cmdlet Binding Attributes
[CmdletBinding(
ConfirmImpact           ="High"
#,    DefaultParameterSetName ="Default"
#,    HelpURI                 =$null
#,    SupportsPaging          =$true <#Enables -First n, -Skip n, -IncludeTotalCount#>
#,    SupportsShouldProcess   =$true <#Enables -Confirm and -Whatif, for which you will want: If ($PSCmdlet.ShouldProcess("Message")) { BlockofCode } #>
#,    PositionalBinding       =$true <#True auto-enables positional. If false, [Parameter(Position=n)] overrides for those params.#>
)]

Param(

    [Parameter(Mandatory= $true,ValueFromPipelineByPropertyName= $true)]
      [String]$FullName
      ,[Parameter(Mandatory= $true,ValueFromPipelineByPropertyName= $true,HelpMessage= "HTTPS url for git submodule add, where the name of the submodule will replace SUBMODNAME")]
      [String]$NewUrl_WithReplaceable_SUBMODNAME
      ,[Parameter(Mandatory= $false)][Hashtable]$SubmoduleNameReplacements
      ,[Parameter(Mandatory= $false)][String[]]$SubmoduleExclusions
      ,[Switch]$Force
      )
BEGIN{
Import-Module $PSScriptRoot\Invoke-Git.psd1

<#
.SYNOPSIS
Script to remove and replace git submodules.
NO GUARANTEES ABOUT THIS SCRIPT! USE AT YOUR OWN RISK!
.DESCRIPTION
When changing the reference of submodules with further nested submodules,
the .git\modules\*\config references can get out of alignment with the actual
URLs used in the depth 1 submodules (so imagine repo "main," repo "sub," and
repo "nested." You can move the reference of nested in sub, but if sub is
a submodule of main, then you might be able to redirect sub but the config
information in main would insist on cloning nested from its old location).
This script can fix that by dropping and re-adding the submodule, but it does 
so by referencing the head commit of the submodule (so if you actually NEED a
particular commit, you will need to modify this).


#>

    IF(-not $Force.IsPresent) {
       Throw "DropAndReAddSubmodules.ps1 is a potentially highly destructive script. Run this in a COPY of your repo with NO CHANGES pending. It will REMOVE and REPLACE your submodules, so you can redirect them from one remote to another."
    }

    $CurrentGitStatus = @(Invoke-Git status-AsObject)
    IF ($CurrentGitStatus.Count -gt 0 ) {
        $CurrentGitStatus | Write-Verbose -Verbose
        Throw "Breaking - unresolved changes."}
}
PROCESS{

#region Echo parameters (https://stackoverflow.com/questions/21559724/getting-all-named-parameters-from-powershell-including-empty-and-set-ones)
Write-Verbose "Echoing parameters:"
$ParameterList = (Get-Command -Name $MyInvocation.InvocationName).Parameters;
foreach ($key in $ParameterList.keys)
{
    $var = Get-Variable -Name $key -ErrorAction SilentlyContinue;
    if($var)
    {
        Write-Verbose "$($var.name): $($var.value)"
    }
    <#Catches Dynamic Parameters with default values that were not explicitly set in the calling script.#>
    If(-not $var){
        If($PSBoundParameters[$key]) {
            "$($key): $($PSBoundParameters[$key])" | Write-Verbose
        }    
    }

}
Write-Verbose "Parameters done."
#endregion Echo parameters

    Push-Location
    Set-Location $FullName -Verbose

    #from git repo
    $targs = git submodule status | % { [pscustomobject]@{SHA1=$($_ -split ' ')[1];Submodule=$($_ -split ' ')[2] } } <#Could we do something with the SHA1? Yes, but this is already an untested behemoth.#>
    $targs = $targs | Where-Object {$_.Submodule -notin $SubmoduleExclusions}

    'Targets:' | Write-Verbose -Verbose
    $targs | Write-Verbose -Verbose

    git stash <#This SHOULD do nothing. We hope.#>

    foreach ($s in $targs) {
        git add .
        git rm $s.submodule
        Remove-Item ".\.git\modules\$($s.submodule)" -Recurse -Force
        
        If ($PSBoundParameters.ContainsKey('SubmoduleNameReplacements') ) { $replacement = $SubmoduleNameReplacements[$($s.submodule)]
            If ($replacement -notlike $null) {
                "Submodule renamed from $($s.submodule) to $replacement" | Write-Verbose -Verbose
                $s.submodule = $replacement
            }
        } <# END If ($PSBoundParameters.ContainsKey('SubmoduleNameReplacements') ) #>
        
        $url = $NewUrl_WithReplaceable_SUBMODNAME.Replace('SUBMODNAME',$($s.submodule))
        git submodule add $url
        Push-Location
        Set-Location ".\$($s.submodule)" -Verbose
        . .\setup.ps1
        Pop-Location

    }<# END foreach ($submodule in $targs) #>
    Pop-Location
}
END{}
