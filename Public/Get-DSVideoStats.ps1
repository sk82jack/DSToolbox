function Get-DSVideoStats {
    [CmdletBinding(DefaultParameterSetName = 'Summary')]
    param (
        [Parameter(ParameterSetName = 'Specific')]
        [ValidateSet('Superbeginner', 'Beginner', 'Intermediate', 'Advanced')]
        [string[]]
        $Level,

        [Parameter()]
        [ValidateSet('AllLATAM', 'AllSpain', 'Andalusia', 'Argentina', 'Bolivia', 'Canary Islands', 'Chile', 'Colombia', 'Mexico', 'Panama', 'SpainStandard', 'Uruguay', 'Venezuela')]
        [string[]]
        $Dialect,

        [Parameter()]
        [ValidateSet('Agustina', 'Tomás', 'Marce', 'Andrea', 'Claudia', 'Edwin', 'Michelle', 'Sofía', 'Alma', 'Andrés', 'Pablo', 'Sandra', 'Adrià', 'Jostin', 'Shelcin')]
        [string[]]
        $Guide,

        [Parameter(ParameterSetName = 'Specific')]
        [ValidateSet('Free', 'Premium')]
        [string[]]
        $Subscription = @('Free', 'Premium'),

        [Parameter(ParameterSetName = 'Summary')]
        [switch]
        $Summary,

        [Parameter()]
        [switch]
        $ExcludeWatched,

        [Parameter()]
        [string]
        $AuthToken = (Get-Content .\authtoken.txt -ErrorAction SilentlyContinue)
    )

    $GuidesPerDialect = Import-PowerShellDataFile $PSScriptRoot\config\GuidesPerDialect.psd1


    $Headers = @{
        'Accept-Encoding' = 'gzip'
        'authorization'   = 'Bearer {0}' -f $AuthToken
    }
    $Response = (Invoke-RestMethod -UseBasicParsing -Uri "https://www.dreamingspanish.com/.netlify/functions/videos" -Headers $Headers).Videos

    if ($Level) {
        $Response = $Response.Where{ $_.level -in $Level }
    }

    if ($Dialect) {
        if ($Dialect -eq 'AllLATAM') {
            $Dialect = @(
                'Argentina'
                'Bolivia'
                'Chile'
                'Colombia'
                'Mexico'
                'Panama'
                'Uruguay'
                'Venezuela'
            )
        }
        elseif ($Dialect -eq 'AllSpain') {
            $Dialect = @(
                'Andalusia'
                'Canary Islands'
                'SpainStandard'
            )
        }

        $DialectGuides = foreach ($IndividualDialect in $Dialect) {
            $GuidesPerDialect[$IndividualDialect]
        }
        $Response = $Response.Where{ $_.guides -match "^($($DialectGuides -join '|'))$" }
    }

    if ($Guide) {
        $Response = $Response.Where{ $_.guides -match $($Guide -join '|') }
    }

    if ($Subscription -notcontains 'Free') {
        $Response = $Response.Where{ $_.private }
    }
    elseif ($Subscription -notcontains 'Premium') {
        $Response = $Response.Where{ -not $_.private }
    }

    if ($ExcludeWatched) {
        $WatchedVideos = (Invoke-RestMethod -UseBasicParsing -Uri "https://www.dreamingspanish.com/.netlify/functions/watchedVideo" -Headers $Headers).watchedVideos
        $WatchedVideoIds = $WatchedVideos.Where{ $_.watched }.videoId
        $Response = $Response.Where{ $_._id -notin $WatchedVideoIds }
    }

    if ($PsCmdlet.ParameterSetName -eq 'Summary') {
        foreach ($Lvl in 'Superbeginner', 'Beginner', 'Intermediate', 'Advanced') {
            $FreeLvlSum = $Response.Where{ $_.Level -eq $Lvl -and -not $_.private }.duration | Measure-Object -Sum
            $FreeLvlHours = $FreeLvlSum.Sum / 3600
            $PremiumLvlSum = $Response.Where{ $_.Level -eq $Lvl -and $_.private }.duration | Measure-Object -Sum
            $PremiumLvlHours = $PremiumLvlSum.Sum / 3600

            $TotalLvlHours = ($FreeLvlSum.Sum + $PremiumLvlSum.Sum) / 3600

            [pscustomobject]@{
                Level             = $Lvl
                FreeVideoCount    = $FreeLvlSum.Count
                FreeVideoHours    = [System.Math]::Round($FreeLvlHours, 1)
                PremiumVideoCount = $PremiumLvlSum.Count
                PremiumVideoHours = [System.Math]::Round($PremiumLvlHours, 1)
                TotalVideoCount   = $FreeLvlSum.Count + $PremiumLvlSum.Count
                TotalVideoHours   = [System.Math]::Round($TotalLvlHours, 1)
            }
        }
    }
    else {
        $Sum = $Response.duration | Measure-Object -Average -Maximum -Minimum -Sum
        $Hours = $Sum.Sum / 3600
        $Average = $Sum.Average / 60
        $Maximum = $Sum.Maximum / 60
        $Minimum = $Sum.Minimum / 60

        [pscustomobject]@{
            Videos           = $Sum.Count
            Hours            = [System.Math]::Round($Hours, 1)
            'Average (mins)' = [System.Math]::Round($Average, 1)
            'Maximum (mins)' = [System.Math]::Round($Maximum, 1)
            'Minimum (mins)' = [System.Math]::Round($Minimum, 1)
        }
    }
}
