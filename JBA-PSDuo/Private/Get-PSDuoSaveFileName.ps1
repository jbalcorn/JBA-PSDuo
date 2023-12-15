Function Get-PSDuoSaveFileName {
    <#
.SYNOPSIS
Prompts for the name of a file to save to.
.PARAMETER initialDirectory
Directory to show in dialog
.PARAMETER Filter
Can be used to find a specific find of file by default, e.g. *.xml
.EXAMPLE
Import-csv (Get-OpenFileName -Filter '*.xml')
    #>
    Param (
        [Parameter(mandatory = $false)][string]$initialDirectory,
        [Parameter(Mandatory = $false)][string]$Filter = '*.xml'
    )

    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null

    $dialog = New-Object System.Windows.Forms.SaveFileDialog
    $dialog.initialDirectory = $initialDirectory
    $dialog.filter = $Filter
    $dialog.ShowDialog() | Out-Null
    $dialog.filename

}
