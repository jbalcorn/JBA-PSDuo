Function Get-CanonicalizedHeaders {
    <#
    .SYNOPSIS
        Canonicalize and hash the x-duo- headers for Duo v5 signature based on code from python client
        https://github.com/duosecurity/duo_client_python/blob/master/duo_client/client.py#L57
    #>
    param (
        [hashtable]$headers = @{}
    )

    $lowered_headers = @{}
    foreach ($key in $headers.keys) {
        $lkey = $key.ToLower()
        $lowered_headers[$lkey] = $headers[$key]
    }

    $canon_list = @()
    $header_list = @()
    foreach ($key in ($lowered_headers.Keys | Sort-Object)) {
        if ($header_list -notcontains $key) {
            $header_list += $key
            if ($key -match '^x-duo-') {
                # python code does canon_list.extend([header_name, value]), which just adds the elements to the end.  So add individual elements to the array
                $canon_list += $key
                $canon_list += $lowered_headers[$key]
            }
        }
    }
    $canon_string = $canon_list -join [char]0

    return Get-DuoHash -str $canon_string
}