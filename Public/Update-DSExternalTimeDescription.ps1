function Update-DSExternalTimeDescription {
    [CmdletBinding(
        DefaultParameterSetName = 'Category',
        SupportsShouldProcess,
        ConfirmImpact = 'High'
    )]
    param (
        [Parameter(ParameterSetName = 'Category', Mandatory)]
        [ArgumentCompleter( {
                param ($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)

                $CategoryPrefixHashtable = Import-PowerShellDataFile $PSScriptRoot\config\CategoryPrefixHashtable.psd1

                $CategoryPrefixHashtable.Values | Where-Object { $_ -match "^$WordToComplete" }
            }
        )]
        [string]
        $Category,

        [Parameter(ParameterSetName = 'Prefix', Mandatory)]
        [string]
        $CategoryPrefix,

        [Parameter(ParameterSetName = 'Prefix')]
        [Parameter(ParameterSetName = 'Category')]
        [string]
        $Separator = '-',

        [Parameter(ParameterSetName = 'Description', Mandatory)]
        [string]
        $Description,

        [Parameter(ParameterSetName = 'Category')]
        [hashtable]
        $CategoryPrefixHashtable = $(Import-PowerShellDataFile $PSScriptRoot\config\CategoryPrefixHashtable.psd1),

        [Parameter()]
        [string]
        $AuthToken = (Get-Content .\authtoken.txt -ErrorAction SilentlyContinue)
    )

    $Headers = @{
        'Accept-Encoding' = 'gzip'
        'authorization'   = 'Bearer {0}' -f $AuthToken
    }
    $ExternalTime = (Invoke-RestMethod -UseBasicParsing -Uri "https://www.dreamingspanish.com/.netlify/functions/externalTime" -Headers $Headers).externalTimes.Where{ $_.type -ne 'initial' }

    if ($Category) {
        $CategoryPrefix = $CategoryPrefixHashtable.Keys.Where{ $CategoryPrefixHashtable[$_] -eq $Category }[0]
    }

    if ($CategoryPrefix) {
        $FullPrefix = '{0} {1}' -f $CategoryPrefix, $Separator
        $ExternalTime = $ExternalTime | Where-Object { -not $_.description.StartsWith($FullPrefix) }
        $ConfirmMessage = "This will update the description(s) to add the prefix: '$FullPrefix'"
    }
    else {
        $ConfirmMessage = "This will update the description(s) to '$Description'"
    }

    $FilteredEntries = $ExternalTime | Out-GridView -PassThru -Title 'Select external time entries to edit the description of'

    if (-not $FilteredEntries) {
        return
    }

    $FilteredEntries | Format-Table

    if ($PSCmdlet.ShouldProcess("The selected entries above will have the following action applied: $ConfirmMessage", 'Are you sure you want to update all the entries listed above?', $ConfirmMessage)) {
        foreach ($Entry in $FilteredEntries) {
            if (-not $Description) {
                $Description = $FullPrefix, $Entry.description -join ' '
            }

            $Data = @{
                date        = $Entry.date
                description = $Description
                id          = $Entry.id
                timeSeconds = $Entry.timeSeconds
                type        = $Entry.type
            }
            $Body = $Data | ConvertTo-Json -Compress
            $Response = Invoke-RestMethod -UseBasicParsing -Uri "https://www.dreamingspanish.com/.netlify/functions/externalTime" -Headers $Headers -Method 'PUT' -ContentType 'text/plain; charset=UTF-8' -Body $Body
    
            if ($Response.message -ne 'Okay.') {
                Write-Host "Setting '$Body' failed with the response '$Response'"
            }
        }
    }
}
