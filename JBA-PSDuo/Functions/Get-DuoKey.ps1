function Get-duoKey {
    Param (
        [Parameter(mandatory = $true)]$keyfile
    )

    try {
        return Import-CLIXML -path $keyfile -ErrorAction Stop
    }
    catch {
        throw $_
    }
}
