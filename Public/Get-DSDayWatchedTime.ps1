function Get-DSDayWatchedTime {
    [CmdletBinding(DefaultParameterSetName = 'DateRange')]
    param (
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
        $DateTo,

        [Parameter()]
        [switch]
        $ExcludeEmptyDays,

        [Parameter()]
        [string]
        $AuthToken = (Get-Content .\ds-authtoken.txt -ErrorAction SilentlyContinue)
    )

    $Headers = @{
        'Accept-Encoding' = 'gzip'
        'authorization'   = 'Bearer {0}' -f $AuthToken
    }
    $DayWatchedTime = Invoke-RestMethod -UseBasicParsing -Uri "https://www.dreamingspanish.com/.netlify/functions/dayWatchedTime" -Headers $Headers

    if ($Month) {
        $MonthNumber = [cultureinfo]::InvariantCulture.DateTimeFormat.AbbreviatedMonthNames.IndexOf($Month) + 1
        $DateFrom = Get-Date -Year $Year -Month $MonthNumber -Day 1 -Hour 0 -Minute 0 -Second 0 -Millisecond 0
        $DateTo = $DateFrom.AddMonths(1).AddDays(-1)
    }

    if (-not $DateFrom) {
        $DateFrom = Get-Date $DayWatchedTime[0].date
    }

    $Now = Get-Date
    if (-not $DateTo -or $DateTo -gt $Now) {
        if ($Now.Hour -lt 4) {
            $DateTo = $Now.AddDays(-1)
        }
        else {
            $DateTo = $Now
        }
    }

    $TimeSpan = New-TimeSpan -Start $DateFrom -End $DateTo
    $AllDays = foreach ($DayNumber in 0..$TimeSpan.Days) {
        $DateFrom.AddDays($DayNumber)
    }

    $DailySeconds = @{}
    $DailyGoalReached = @{}
    foreach ($Day in $DayWatchedTime) {
        $Key = ([datetime]$Day.date).ToString('yyyy-MM-dd')
        $DailySeconds[$Key] = $Day.timeSeconds
        $DailyGoalReached[$Key] = $Day.goalReached
    }

    $CumulativeSeconds = 0
    foreach ($Day in $AllDays) {
        $Key = $Day.ToString('yyyy-MM-dd')
        $DailySecs = [int]$DailySeconds[$Key]
        $CumulativeSeconds = $CumulativeSeconds + [int]$DailySeconds[$Key]

        if ($ExcludeEmptyDays -and $DailySecs -eq 0) {
            continue
        }

        [PSCustomObject]@{
            Date            = $Day
            DayMins         = [int][math]::Round($DailySecs / 60)
            DayHours        = [math]::Round($DailySecs / (60 * 60), 1)
            DaySecs         = $DailySecs
            CumulativeHours = [math]::Round($CumulativeSeconds / (60 * 60), 1)
            CumulativeSecs  = $CumulativeSeconds
            GoalReached     = [bool]$DailyGoalReached[$Key]
        }
    }
}
