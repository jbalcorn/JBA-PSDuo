function Get-DuoAPIResponse {
    Param
    (
        $duoKey,
        [string]$method,
        [string]$path,
        [hashtable]$parameters
    )
	Add-Type -AssemblyName System.Web
	
    $results = New-Object System.Collections.ArrayList
    do {
        $canon_params = Get-DuoQueryParameters -parameters $parameters
    
        [string]$query = ""

        if (($method.ToUpper() -eq 'GET') -or ($method.ToUpper() -eq 'DELETE')) {
            if ($parameters.Count -gt 0) {
                $query = "?" + $canon_params
            }
        }

        $url = "https://$($duoKey.apiHost)$($path)$($query)"
        [string]$date_string = (Get-Date).ToUniversalTime().ToString("ddd, dd MMM yyyy HH:mm:ss -0000", ([System.Globalization.CultureInfo]::InvariantCulture))
        #
        ## Generate the AuthN Header
        #
    
        [string[]]$lines = @($date_string.Trim(), $method.ToUpperInvariant().Trim(), $duoKey.apihost.ToLower().Trim(), $path.Trim(), $canon_params.Trim())
        [string]$canon = [string]::Join("`n", $lines)

        $hmacsha1 = New-Object System.Security.Cryptography.HMACSHA1
        [byte[]]$data_bytes = [System.Text.Encoding]::UTF8.GetBytes($canon)
        [byte[]]$key_bytes = [System.Text.Encoding]::UTF8.GetBytes([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR( (ConvertTo-SecureString -string ($duoKey.sKeyEnc).ToString()) ) ))
        $hmacsha1.Key = $key_bytes
        $hmacsha1.ComputeHash($data_bytes) | Out-Null
        $hash_hex = [System.BitConverter]::ToString($hmacsha1.Hash)
        [string]$sig = $hash_hex.Replace("-", "").ToLower()

        [string]$auth = "$($duoKey.iKey):$($sig)"

        [byte[]]$plainText_bytes = [System.Text.Encoding]::ASCII.GetBytes($auth)

        [string]$authN = "Basic $([System.Convert]::ToBase64String($plainText_bytes))"

        $AuthHeaders =
        @{
            "X-Duo-Date"    = $date_string
            "Authorization" = $authN
        }
        $result = $null
        $metadata = $null
        $response = $null
        try {
            $result = Invoke-DuoAPICall -method $method -resource $url -AuthHeaders $AuthHeaders -canon_params $canon_params
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
            $results.AddRange($response)
            $done = $true
        } 
        elseif ($null -ne $metadata -and $null -ne $metadata.next_offset) {
            Write-Verbose "Partial Response, $($response.count) records, last timestamp: $(($response | Select -Last 1).isotimestamp)"
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