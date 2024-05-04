function Get-DSExternalTimeStats {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet('Category', 'Description', 'FullDescription')]
        [string]
        $GroupedBy = 'FullDescription',

        [Parameter()]
        [hashtable]
        $CategoryPrefixHashtable = $(Import-PowerShellDataFile $PSScriptRoot\config\CategoryPrefixHashtable.psd1)
    )

    $ExternalTime = . $PSScriptRoot\Get-DSExternalTime.ps1 -CategoryPrefixHashtable $CategoryPrefixHashtable


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
