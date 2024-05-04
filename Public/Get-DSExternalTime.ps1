function Get-DSExternalTime {
    [CmdletBinding()]
    param (
        [Parameter()]
        [hashtable]
        $CategoryPrefixHashtable,

        [Parameter()]
        [string]
        $AuthToken = (Get-Content .\authtoken.txt -ErrorAction SilentlyContinue)
    )

    if (-not $CategoryPrefixHashtable) {
        $ModuleBase = $MyInvocation.MyCommand.Module.ModuleBase
        $ConfigPath = Join-Path -Path $ModuleBase -ChildPath 'config\CategoryPrefixHashtable.psd1'
        $CategoryPrefixHashtable = Import-PowerShellDataFile $ConfigPath
    }

    $Headers = @{
        'Accept-Encoding' = 'gzip'
        'authorization'   = 'Bearer {0}' -f $AuthToken
    }
    $DayWatchedTime = Invoke-RestMethod -UseBasicParsing -Uri "https://www.dreamingspanish.com/.netlify/functions/dayWatchedTime" -Headers $Headers
    $ExternalTime = Invoke-RestMethod -UseBasicParsing -Uri "https://www.dreamingspanish.com/.netlify/functions/externalTime" -Headers $Headers

    $TimeSpan = New-TimeSpan -Start $DayWatchedTime[0].date -End (Get-Date)
    $AllDays = foreach ($DayNumber in 0..$TimeSpan.Days) {
    ([datetime]$DayWatchedTime[0].date).AddDays($DayNumber)
    }

    $DailySeconds = @{}
    foreach ($Day in $DayWatchedTime) {
        $Key = ([datetime]$Day.date).ToString('yyyy-MM-dd')
        $DailySeconds[$Key] = $Day.timeSeconds
    }

    $CumulativeSeconds = @{}
    $TimeCount = 0
    foreach ($Day in $AllDays) {
        $Key = ([datetime]$Day.date).ToString('yyyy-MM-dd')
        $TimeCount = $TimeCount + [int]$DailySeconds[$Key]
        $CumulativeSeconds[$Key] = $TimeCount
    }

    foreach ($Entry in $ExternalTime.externalTimes) {
        if ($Entry.type -eq 'initial') {
            continue
        }

        $CategoryRegex = [regex]::match($Entry.description, '^(\w\w) - (.*)$')

        if ($CategoryRegex.Success) {
            $Category = $CategoryPrefixHashtable[$CategoryRegex.Groups[1].Value]
            $Description = $CategoryRegex.Groups[2].Value
        }
        else {
            $Category = 'Other'
            $Description = $Entry.description
        }

        $Date = [datetime]$Entry.date
        $Key = $Date.ToString('yyyy-MM-dd')
        [PSCustomObject]@{
            Date            = $Date
            Category        = $Category
            DurationMins    = $Entry.timeSeconds / 60
            Description     = $Description
            HourCount       = [int][math]::Round($CumulativeSeconds[$Key] / (60 * 60))
            Type            = $Entry.type
            FullDescription = $Entry.description
        }
    }
}
