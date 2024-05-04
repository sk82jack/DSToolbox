function Measure-InputTime {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string[]]
        $Time,

        [Parameter()]
        [int]
        $Percent
    )

    $SecondsList = foreach ($IndividualTime in $Time) {
        $IndividualTimeArray = $IndividualTime -split '[.:]'
        $IndividualTimeSpan = New-TimeSpan -Minutes $IndividualTimeArray[0] -Seconds ($IndividualTimeArray[1] -as [int])
        $IndividualTimeSpan.TotalSeconds
    }

    $TotalSeconds = ($SecondsList | Measure-Object -Sum).Sum
    $TotalTimeSpan = New-TimeSpan -Seconds $TotalSeconds

    if ($Percent -gt 0) {
        $PercentSeconds = ($TotalSeconds * $Percent) / 100
        $PercentTimeSpan = New-TimeSpan -Seconds $PercentSeconds
        'Total time: {0:g} ({1}% of {2:g})' -f $PercentTimeSpan, $Percent, $TotalTimeSpan
    }
    else {
        'Total time: {0:g}' -f $TotalTimeSpan
    }
}
