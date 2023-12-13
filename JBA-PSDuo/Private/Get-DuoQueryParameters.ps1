function Get-DuoQueryParameters {
    Param(
        [hashtable]$parameters
    )

    $canon_params = ""
    if ($parameters.Count -ge 1) {
        $ret = New-Object System.Collections.ArrayList

        foreach ($key in $parameters.keys) {
            foreach ($val in $parameters[$key]) {
                [string]$p = [System.Web.HttpUtility]::UrlEncode($key) + "=" + [System.Web.HttpUtility]::UrlEncode($val)
                # Signatures require upper-case hex digits.
                $p = [regex]::Replace($p, "(%[0-9A-Fa-f][0-9A-Fa-f])", { $args[0].Value.ToUpperInvariant() })
                $p = [regex]::Replace($p, "([!'()*])", { "%" + [System.Convert]::ToByte($args[0].Value[0]).ToString("X") })
                $p = $p.Replace("%7E", "~")
                $p = $p.Replace("+", "%20")
                $ret.Add($p) | Out-Null
            }
        }

        $ret.Sort([System.StringComparer]::Ordinal)
        [string]$canon_params = [string]::Join("&", ($ret.ToArray()))
        Write-Debug $canon_params
    }
    return $canon_params
}
