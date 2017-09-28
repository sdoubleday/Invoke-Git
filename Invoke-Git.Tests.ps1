<#SDS Modified Pester Test file header to handle modules.#>
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = ( (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.' ) -replace '.ps1', '.psd1'
$scriptBody = "using module $here\$sut"
$script = [ScriptBlock]::Create($scriptBody)
. $script
Import-Module $here\EncodingHelper.psm1

#region Describe "Invoke-Git"
Describe "Invoke-Git" {
    
    CONTEXT 'Someday, maybe write tests.' {
        $dir = "$here\..\"
        $filePath = "$dir\Sample.txt"
        $initial  = 'Initial Value is Fred.'
        $alter    = 'Updated to Susan.'

#        BeforeEach{
#            New-Item  -ItemType File -Name $filePath -Value $initial | Out-Null
#        }<#End BeforeEach#>


        <#
        Edit a file inside a folder and see it as modified when status is run at the top level.
        Edit a file inside a folder and successfully pipe it to "git add" using my push-all-modified option (filter on WorkingStatus -eq 'M')

        
        
        delete a committed file and get it back
        Get back prior version of a committed file
        branch a file, update it, get back the initial branch version
        branch a file, update it, get back the main line file
        branch a file, update it, switch back to the main line, update it, get back the initial version.
        branch a file, update it, merge it back into the main line.

        #>
        It "Invoke-Git has tests" {
            
            $false | Should Be $true
        }
    } <#End Context Someday, maybe write tests.#>
}
#endregion Describe "Invoke-Git"
