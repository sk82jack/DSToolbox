function Export-DSExternalTime {
    [CmdletBinding(DefaultParameterSetName = 'clipboard')]
    param (
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

    $ExternalTime = . $PSScriptRoot\Get-DSExternalTime.ps1

    $ExportDirectory = Split-Path -Path $Path -Parent
    if (-not (Test-Path $ExportDirectory)) {
        $null = New-Item -Path $ExportDirectory -ItemType Directory
    }

    $ExportArray = $ExternalTime.foreach{ $_.Date = $_.Date.ToString('d'); $_ }
    if ($PSCmdlet.ParameterSetName -eq 'csv') {
        $ExportArray | Export-Csv -Path $Path -NoTypeInformation
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'clipboard') {
        $ExportArray | ConvertTo-Csv -Delimiter "`t" -NoTypeInformation | Set-Clipboard
    }
}
