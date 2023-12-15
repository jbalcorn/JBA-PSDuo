Function New-DuoAppKey {
    <#
    .SYNOPSIS
    Creates file for current user to store Duo app key information securely. File will only be able to be used by current user.

    .DESCRIPTION

    .PARAMETER keyfile
    String. File name for output.  Opetional.

    .INPUTS
    None. You cannot pipe objects to this function

    .OUTPUTS
    Feedback on runtime.  This function is not intended to be used in a pipeline.

    .EXAMPLE
    PS> New-DuoAppKey -keyfile duoKey.xml

    .LINK
    https://tfs.jonesday.net/tfs/Security/InfoSec%20Team/_git/DuoEnrollment

    .NOTES
    #>
    Param (
        [Parameter(Mandatory = $false)][string]$keyfile
    )

        $apihost = Read-Host -Prompt "API Host"

        $iKey = Read-Host -Prompt "Duo Application Key"

        $sKeyEnc = (ConvertFrom-SecureString -SecureString (Read-Host -AsSecureString -Prompt "PlainText Secret Key"))

        if (-Not $keyfile) {
            $keyfile = Get-PSDuoSaveFileName -Filter "XML Files|*.xml"
        }
        New-Object -TypeName PSObject -Property @{
            apihost = $apihost
            iKey    = $iKey
            sKeyEnc = $sKeyEnc
        } | Export-CLIXML -Path $keyfile

    }