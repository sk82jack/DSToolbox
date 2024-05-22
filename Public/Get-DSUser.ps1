function Get-DSUser {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $AuthToken = (Get-Content .\ds-authtoken.txt -ErrorAction SilentlyContinue)
    )

    $Headers = @{
        'Accept-Encoding' = 'gzip'
        'authorization'   = 'Bearer {0}' -f $AuthToken
    }
    $User = Invoke-RestMethod -UseBasicParsing -Uri "https://www.dreamingspanish.com/.netlify/functions/user" -Headers $Headers

    [pscustomobject]@{
        Email             = $User.user.email
        ExternalTimeHours = [math]::Round($User.user.externalTimeSeconds / (60 * 60), 1)
        DSTimeHours       = [math]::Round($User.user.watchTime / (60 * 60), 1)
        TotalTimeHours    = [math]::Round(($User.user.watchTime + $User.user.externalTimeSeconds) / (60 * 60), 1)
        DailyGoalMins     = $User.user.dailyGoalSeconds / 60
        SubStatus         = $User.user.Subscription.status
        SubEndDate        = $User.user.Subscription.currentPeriodEnd
        SubRenewalEnabled = -not $User.user.Subscription.cancelAtDateEnd
    }
}
