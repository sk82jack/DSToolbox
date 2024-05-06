function Export-DSExternalTime {
    [CmdletBinding(DefaultParameterSetName = 'clipboard')]
    param (
        [Parameter()]
        [ValidateSet('Category', 'Description', 'FullDescription')]
        [string]
        $GroupedBy = 'FullDescription',

        [Parameter(ParameterSetName = 'csv')]
        [switch]
        $ExportToCsv,

        [Parameter(ParameterSetName = 'csv')]
        [System.IO.FileInfo]
        $Path = (Join-Path -Path $PSScriptRoot -ChildPath "export\ExternalTime$(Get-Date -Format FileDate).csv"),

        [Parameter(ParameterSetName = 'clipboard')]
        [switch]
        $ExportToClipboard
    )

    $ExportDirectory = Split-Path -Path $Path -Parent
    if (-not (Test-Path $ExportDirectory)) {
        $null = New-Item -Path $ExportDirectory -ItemType Directory
    }

    if ($GroupedBy) {
        $ExternalTimeStats = Get-DSExternalTimeStats -GroupedBy $GroupedBy
        $ExportArray = $ExternalTimeStats
    }
    else {
        $ExternalTime = Get-DSExternalTime
        $ExportArray = $ExternalTime.foreach{ $_.Date = $_.Date.ToString('d'); $_ }
    }

    if ($PSCmdlet.ParameterSetName -eq 'csv') {
        $ExportArray | Export-Csv -Path $Path -NoTypeInformation
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'clipboard') {
        $ExportArray | ConvertTo-Csv -Delimiter "`t" -NoTypeInformation | Set-Clipboard
    }
}
