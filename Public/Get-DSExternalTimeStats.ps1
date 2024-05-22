function Get-DSExternalTimeStats {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet('Category', 'Description', 'FullDescription')]
        [string]
        $GroupedBy = 'Description',

        [Parameter()]
        [hashtable]
        $CategoryPrefixHashtable
    )

    if (-not $CategoryPrefixHashtable) {
        $ModuleBase = $MyInvocation.MyCommand.Module.ModuleBase
        $ConfigPath = Join-Path -Path $ModuleBase -ChildPath 'config\CategoryPrefixHashtable.psd1'
        $CategoryPrefixHashtable = Import-PowerShellDataFile $ConfigPath
    }

    $ExternalTime = Get-DSExternalTime -CategoryPrefixHashtable $CategoryPrefixHashtable


    $GroupedOutput = $ExternalTime | Group-Object -Property $GroupedBy
    $Output = foreach ($Show in $GroupedOutput) {
        $Time = $Show.Group.DurationMins | Measure-Object -Sum
        [PSCustomObject]@{
            $GroupedBy = $Show.Name
            Hours      = [math]::Round(($Time.Sum / 60), 1)
            Count      = $Show.Count
            Mins       = [int]$Time.Sum
        }
    }
    $Output | Sort-Object -Property 'Mins' -Descending
}
