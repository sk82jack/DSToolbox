function Get-DSVideoList {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $AuthToken = (Get-Content .\ds-authtoken.txt -ErrorAction SilentlyContinue)
    )

    $Headers = @{
        'Accept-Encoding' = 'gzip, deflate, br, zstd'
        'authorization'   = 'Bearer {0}' -f $AuthToken
    }
    $PlayList = Invoke-RestMethod -UseBasicParsing -Uri "https://www.dreamingspanish.com/.netlify/functions/playlist" -Headers $Headers
    $DayWatchedTime = Invoke-RestMethod -UseBasicParsing -Uri "https://www.dreamingspanish.com/.netlify/functions/dayWatchedTime" -Headers $Headers
    $Videos = (Invoke-RestMethod -UseBasicParsing -Uri "https://www.dreamingspanish.com/.netlify/functions/videos" -Headers $Headers).Videos
    
    $VideoHash = @{}
    foreach ($Video in $Videos) {
        $VideoHash[$Video._id] = $Video
    }

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

    foreach ($Video in $PlayList) {
        $Date = [datetime]$Video.addedDate
        $Key = $Date.ToString('yyyy-MM-dd')

        [pscustomobject]@{
            Title     = $VideoHash[$Video.videoId].title
            AddedDate = $Date
            HourCount = [int][math]::Round($CumulativeSeconds[$Key] / (60 * 60))
        }
    }
}
