function Export-DSDayWatchedTime {
    [CmdletBinding(DefaultParameterSetName = 'clipboard')]
    param (
        [Parameter()]
        [switch]
        $Monthly,

        [Parameter(ParameterSetName = 'csv')]
        [switch]
        $ExportToCsv,

        [Parameter(ParameterSetName = 'csv')]
        [System.IO.FileInfo]
        $Path = (Join-Path -Path $PSScriptRoot -ChildPath "export\DayWatchedTime$(Get-Date -Format FileDate).csv"),

        [Parameter(ParameterSetName = 'clipboard')]
        [switch]
        $ExportToClipboard
    )

    $ExportDirectory = Split-Path -Path $Path -Parent
    if (-not (Test-Path $ExportDirectory)) {
        $null = New-Item -Path $ExportDirectory -ItemType Directory
    }

    if ($Monthly) {
        $ExportArray = Get-DSDayWatchedTimeStats -GroupByMonth
    }
    else {
        $DayWatchedTime = Get-DSDayWatchedTime
        $ExportArray = $DayWatchedTime.foreach{ $_.Date = $_.Date.ToString('d'); $_ }
    }

    if ($PSCmdlet.ParameterSetName -eq 'csv') {
        $ExportArray | Export-Csv -Path $Path -NoTypeInformation
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'clipboard') {
        $ExportArray | ConvertTo-Csv -Delimiter "`t" -NoTypeInformation | Set-Clipboard
    }
}
