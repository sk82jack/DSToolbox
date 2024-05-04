function Confirm-GuidesPerDialect {
    [CmdletBinding(DefaultParameterSetName = 'Month')]
    param (
        [Parameter()]
        [string]
        $AuthToken = (Get-Content .\authtoken.txt -ErrorAction SilentlyContinue)
    )

    $GuidesPerDialect = Import-PowerShellDataFile .\Config\GuidesPerDialect.psd1

    $Headers = @{
        'Accept-Encoding' = 'gzip'
        'authorization'   = 'Bearer {0}' -f $AuthToken
    }
    $Response = (Invoke-RestMethod -UseBasicParsing -Uri "https://www.dreamingspanish.com/.netlify/functions/videos" -Headers $Headers).Videos
    $ResponseGuides = $Response.guides | ForEach-Object { $_ } | Sort-Object -Unique

    $ScriptGuides = $GuidesPerDialect.Keys | ForEach-Object { $GuidesPerDialect[$_] } | ForEach-Object { $_ } | Sort-Object -Unique

    Write-Host 'Arrow pointing left means they are listed on the website but not in the script. Arrow pointing right means they have been removed from the website but not from the script.'
    Compare-Object $ResponseGuides $ScriptGuides
}
