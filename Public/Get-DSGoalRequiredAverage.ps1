function Get-DSGoalRequiredAverage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [datetime]
        $GoalDate,

        [Parameter(Mandatory, ParameterSetName = 'Hours')]
        [int]
        $GoalHours,

        [Parameter(Mandatory, ParameterSetName = 'Level')]
        [ValidateRange(1, 7)]
        [int]
        $GoalLevel,

        [Parameter()]
        [ValidateSet('Today', 'Tomorrow')]
        [string]
        $StartFrom = 'Tomorrow',

        [Parameter()]
        [string]
        $AuthToken = (Get-Content .\ds-authtoken.txt -ErrorAction SilentlyContinue)
    )

    $StartDate = Get-Date -Hour 0 -Minute 0 -Second 0
    if ($StartFrom -eq 'Tomorrow') {
        $StartDate = $StartDate.AddDays(1)
    }

    if ($GoalDate -lt $StartDate) {
        Write-Warning -Message 'GoalDate must be a date after the StartFrom date'
        return
    }

    $Headers = @{
        'Accept-Encoding' = 'gzip'
        'authorization'   = 'Bearer {0}' -f $AuthToken
    }
    $User = Invoke-RestMethod -UseBasicParsing -Uri "https://www.dreamingspanish.com/.netlify/functions/user" -Headers $Headers

    $LevelHours = @{
        2 = 50
        3 = 150
        4 = 300
        5 = 600
        6 = 1000
        7 = 1500
    }
    if ($PsCmdlet.ParameterSetName -eq 'Level') {
        $GoalHours = $LevelHours[$GoalLevel]
    }

    $GoalSeconds = $GoalHours * (60 * 60)
    $TimeLeftSeconds = $GoalSeconds - ($User.user.watchTime + $User.user.externalTimeSeconds)
    $DaysLeftRange = New-TimeSpan -Start $StartDate -End $GoalDate
    $DaysLeft = [math]::Ceiling($DaysLeftRange.TotalDays)
    $DailyAverageHours = ($TimeLeftSeconds / $DaysLeft) / (60 * 60)
    [pscustomobject]@{
        DailyAverageRequiredHours  = [math]::Round($DailyAverageHours, 1)
        WeeklyAverageRequiredHours = [math]::Round(($DailyAverageHours * 7), 1)
    }
}
