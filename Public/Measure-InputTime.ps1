function Measure-InputTime {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string[]]
        $Time,

        [Parameter()]
        [int]
        $Percent,

        [Parameter()]
        [float]
        $Speed
    )

    $SecondsList = foreach ($IndividualTime in $Time) {
        $IndividualTime, $IndividualPercent = $IndividualTime -split '[@]'
        $IndividualTimeArray = $IndividualTime -split '[.:]'
        $IndividualTimeSpan = New-TimeSpan -Minutes $IndividualTimeArray[0] -Seconds ($IndividualTimeArray[1] -as [int])

        if ($IndividualPercent) {
            $IndividualTimeSpan.TotalSeconds * ([int]$IndividualPercent / 100)
        }
        else {
            $IndividualTimeSpan.TotalSeconds
        }
    }

    $TotalSeconds = ($SecondsList | Measure-Object -Sum).Sum
    $TotalTimeSpan = New-TimeSpan -Seconds $TotalSeconds

    if ($Percent -gt 0) {
        $PercentSeconds = ($TotalSeconds * $Percent) / 100
        $PercentTimeSpan = New-TimeSpan -Seconds $PercentSeconds
        'Total time: {0:g} ({1}% of {2:g})' -f $PercentTimeSpan, $Percent, $TotalTimeSpan
    }
    elseif ($Speed -gt 0) {
        $PercentSeconds = ($TotalSeconds / $Speed)
        $SpeedTimeSpan = New-TimeSpan -Seconds $PercentSeconds
        'Total time: {0:g} ({1:g} at x{2})' -f $SpeedTimeSpan, $TotalTimeSpan, $Speed
    }
    else {
        'Total time: {0:g}' -f $TotalTimeSpan
    }
}
