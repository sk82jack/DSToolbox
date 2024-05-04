function Get-DSDayWatchedTimeStats {
    [CmdletBinding(DefaultParameterSetName = 'DateRange')]
    param (
        [Parameter(ParameterSetName = 'DateRange')]
        [switch]
        $GroupByMonth,

        [Parameter(ParameterSetName = 'Month', Mandatory)]
        [ArgumentCompleter( {
                param ($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)

                [cultureinfo]::InvariantCulture.DateTimeFormat.AbbreviatedMonthNames | Where-object { $_ -match "\w+" -and $_ -match "^$WordToComplete" }
            }
        )]
        [ValidateScript({
                $Names = [cultureinfo]::InvariantCulture.DateTimeFormat.AbbreviatedMonthNames | Where-Object { $_ -match "\w+" }
                if ($Names -contains $_) {
                    $True
                }
                else {
                    Throw "You entered an invalid month. Valid choices are $($Names -join ',')"
                    $False
                }
            }
        )]
        [string]
        $Month,

        [Parameter(ParameterSetName = 'Month')]
        [int]
        $Year = (Get-Date).Year,
    
        [Parameter(ParameterSetName = 'DateRange')]
        [datetime]
        $DateFrom,

        [Parameter(ParameterSetName = 'DateRange')]
        [datetime]
        $DateTo
    )

    $DayWatchedSplat = $PSBoundParameters
    if ($DayWatchedSplat.ContainsKey('GroupByMonth')) {
        $DayWatchedSplat.Remove('GroupByMonth')
    }

    $DayWatchedTime = Get-DSDayWatchedTime @DayWatchedSplat

    if (-not $DateFrom) {
        $DateFrom = $DayWatchedTime[0].Date
    }

    if (-not $DateTo) {
        $DateTo = $DayWatchedTime[-1].Date
    }

    if ($GroupByMonth) {
        $GroupedTime = $DayWatchedTime | Group-Object -Property { [cultureinfo]::InvariantCulture.DateTimeFormat.GetAbbreviatedMonthName($_.Date.Month), $_.Date.Year -join ' ' }
        $GroupedTime = $GroupedTime | Sort-Object { $_.Name.split()[1] }, { [cultureinfo]::InvariantCulture.DateTimeFormat.AbbreviatedMonthNames.IndexOf($_.Name.split()[0]) }

        foreach ($Group in $GroupedTime) {
            $WatchedStats = $Group.Group.DaySecs | Measure-Object -Sum -Average -Maximum -Minimum
            $GoalReachedDays = $Group.Group.Where{ $_.GoalReached }

            [pscustomobject]@{
                Month              = $Group.Name
                TotalWatchedHours  = [math]::Round(($WatchedStats.Sum / 3600), 1)
                AverageHoursPerDay = [math]::Round(($WatchedStats.Average / (60 * 60)), 1)
                MaximumHoursPerDay = [math]::Round(($WatchedStats.Maximum / (60 * 60)), 1)
                MinimumHoursPerDay = [math]::Round(($WatchedStats.Minimum / (60 * 60)), 1)
                GoalReachedPercent = [int][math]::Round(($GoalReachedDays.Count / $Group.Group.Count) * 100)
            }
        }
    }
    else {
        $WatchedStats = $DayWatchedTime.DaySecs | Measure-Object -Sum -Average -Maximum -Minimum
        $GoalReachedDays = $DayWatchedTime.Where{ $_.GoalReached }

        [pscustomobject]@{
            TimePeriod         = 'From {0:d} to {1:d}' -f $DateFrom, $DateTo
            TotalWatchedHours  = [math]::Round(($WatchedStats.Sum / 3600), 1)
            AverageHoursPerDay = [math]::Round(($WatchedStats.Average / (60 * 60)), 1)
            MaximumHoursPerDay = [math]::Round(($WatchedStats.Maximum / (60 * 60)), 1)
            MinimumHoursPerDay = [math]::Round(($WatchedStats.Minimum / (60 * 60)), 1)
            GoalReachedPercent = [int][math]::Round(($GoalReachedDays.Count / $DayWatchedTime.Count) * 100)
        }
    }
}
