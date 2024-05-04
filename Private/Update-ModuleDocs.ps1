function Update-ModuleDocs {
    [CmdletBinding()]
    param ()
    Import-Module .\DSToolbox.psd1 -Force

    # Create new markdown files for new functions
    New-MarkdownHelp -OutputFolder .\Docs -Module DSToolbox

    # Update markdown for updated functions
    Update-MarkdownHelp .\Docs

    # Export markdown changes to XML and then re-import module to test new help files
    New-ExternalHelp .\Docs -OutputPath en-US\ -Force
    Import-Module .\DSToolbox.psd1 -Force
}
