function Invoke-DuoUpdate {
    Param
    (
        $duoKey,
        [string]$method,
        [string]$bodyformat = 'encoded',
        [string]$path,
        [Int32]$sig_version = 2,
        [hashtable]$parameters,
        [string]$body
    )
    Add-Type -AssemblyName System.Web
	
    $results = New-Object System.Collections.ArrayList

    $canon_params = Get-DuoQueryParameters -parameters $parameters
    
    [string]$query = ""

    if (($method.ToUpper() -eq 'GET') -or ($method.ToUpper() -eq 'DELETE')) {
        throw "Use Get-DuoAPIResponse for GET or DELETE"
    }
    $url = "https://$($duoKey.apiHost)$($path)$($query)"

    do {
        [string]$date_string = (Get-Date).ToUniversalTime().ToString("ddd, dd MMM yyyy HH:mm:ss -0000", ([System.Globalization.CultureInfo]::InvariantCulture))
        $AuthHeaders =
        @{
            "X-Duo-Date" = $date_string
        }

        #
        ## Generate the AuthN Header
        #
    
        if ($sig_version -eq 1) {
            [string[]]$lines = @($method.ToUpperInvariant().Trim(), $duoKey.apihost.ToLower().Trim(), $path.Trim(), $canon_params.Trim())
        }
        elseif ($sig_version -eq 2) {
            [string[]]$lines = @($date_string.Trim(), $method.ToUpperInvariant().Trim(), $duoKey.apihost.ToLower().Trim(), $path.Trim(), $canon_params.Trim())
        }
        elseif ($sig_version -eq 4) {
            # $sig_version 4 is json only
            $body_hash = Get-DuoHash -str $body
            [string[]]$lines = @($date_string.Trim(), $method.ToUpperInvariant().Trim(), $duoKey.apihost.ToLower().Trim(), $path.Trim(), $canon_params.Trim(), $body_hash)
        }
        elseif ($sig_version -eq 5) {
            $body_hash = Get-DuoHash -str $body
            $canon_x_duo_headers = Get-CanonicalizedHeaders -headers $AuthHeaders
            [string[]]$lines = @($date_string.Trim(), $method.ToUpperInvariant().Trim(), $duoKey.apihost.ToLower().Trim(), $path.Trim(), $canon_params.Trim(), $body_hash, $canon_x_duo_headers)
        }
        [string]$canon = [string]::Join("`n", $lines)
        Write-Debug "Canonicalized String for Signature:`n$($canon)`n====="

        if ($sig_version -lt 4) {
            $hmacsha1 = New-Object System.Security.Cryptography.HMACSHA1
        }
        else {
            $hmacsha1 = New-Object System.Security.Cryptography.HMACSHA512
        }
        [byte[]]$data_bytes = [System.Text.Encoding]::UTF8.GetBytes($canon)
        [byte[]]$key_bytes = [System.Text.Encoding]::UTF8.GetBytes([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR( (ConvertTo-SecureString -string ($duoKey.sKeyEnc).ToString()) ) ))
        $hmacsha1.Key = $key_bytes
        $hmacsha1.ComputeHash($data_bytes) | Out-Null
        $hash_hex = [System.BitConverter]::ToString($hmacsha1.Hash)
        [string]$sig = $hash_hex.Replace("-", "").ToLower()

        [string]$auth = "$($duoKey.iKey):$($sig)"

        [byte[]]$plainText_bytes = [System.Text.Encoding]::ASCII.GetBytes($auth)

        [string]$authN = "Basic $([System.Convert]::ToBase64String($plainText_bytes))"

        $AuthHeaders['Authorization'] = $authN

        $result = $null
        $metadata = $null
        $response = $null
        try {
            Write-Verbose "Autheaders: $($AuthHeaders | Out-String)"
            Write-Verbose "Canon_params: $($canon_params)"
            Write-Verbose "Body: $($body)"
            $result = Invoke-DuoAPICall -method $method -resource $url -AuthHeaders $AuthHeaders -canon_params $canon_params -body $body -bodyformat $bodyformat
        }
        catch {
            if ($_.exception.message -match "42901") {
                $pause = $pause + 15
                Start-Sleep $pause
            }
            else {
                throw $_
            }
        }
        if ($result.stat -eq 'OK') {
            $pause = 0
            if ($path -match "/v2/logs/authentication") {
                $metadata = $result.response.metadata
                $response = $result.response.authlogs
            }
            else {
                $metadata = $result.metadata
                $response = $result.response
            }
        }
        if ($null -eq $result) {
            $done = $false
        }
        elseif ($result.stat -eq 'OK' -and $null -eq $metadata) {
            $results = $response
            $done = $true
        } 
        elseif ($null -ne $metadata -and $null -ne $metadata.next_offset) {
            Write-Verbose "Partial Response, $($response.count) records, last timestamp: $(($response | Select-Object -Last 1).isotimestamp)"
            _write-Log "Received $($response.count) of $($metadata.total_objects)"
            $results.AddRange($response)
            if ($path -match "/v2") {
                $parameters["next_offset"] = $metadata.next_offset -join ","
            }
            else {
                $parameters["offset"] = $metadata.next_offset
            }
            $done = $false
            Start-Sleep 5
        }
        elseif ($null -ne $metadata -and $null -eq $metadata.next_offset) {
            $results.AddRange($response)
            $done = $true
        }
        else {
            throw $result.response
        }
    } while ( $done -ne $true )
    return $results
}