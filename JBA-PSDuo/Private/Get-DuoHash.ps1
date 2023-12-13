Function Get-DuoHash {
    <#
    .SYNOPSIS
        Return a hash of the passed in string for Duo v5 signature. Based on code from Duo python client 
        https://github.com/duosecurity/duo_client_python/blob/master/duo_client/client.py#L57
    #>
    param (
        [string]$str
    )

    [byte[]]$bytes = [System.Text.Encoding]::UTF8.GetBytes($str)
    $stream = [IO.MemoryStream]::new($bytes)
    $hash = Get-FileHash -InputStream $stream -Algorithm SHA512

    return ($hash.hash).ToLower()
}