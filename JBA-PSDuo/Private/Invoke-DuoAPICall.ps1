function Invoke-DuoAPICall {
    param
    (
        
        [String]$method,
        [String]$resource,
        [hashtable]$AuthHeaders,
        [String]$canon_params
    )

    $headers = @{
        'Accept-Charset'  = 'ISO-8859-1,utf-8'
        'Accept-Language' = 'en-US'
        'Accept-Encoding' = 'deflate,gzip'
        'Authorization'   = $AuthHeaders['Authorization']
        'X-Duo-Date'      = $AuthHeaders['X-Duo-Date']
    }

    [string]$encoding = "application/json"
    if ($resource -like 'https://*') {
        [string]$URI = $resource
    }
    else {
        throw $resource
    }

    $request = [System.Net.HttpWebRequest]::CreateHttp($URI)
    $request.Method = $method
    Write-Debug ('[' + $request.Method + " " + $request.RequestUri + ']')

    $request.Accept = $encoding
    $request.UserAgent = "Duo-PSModule/0.1"

    $request.AutomaticDecompression = @([System.Net.DecompressionMethods]::Deflate, [System.Net.DecompressionMethods]::GZip)
    
    foreach ($key in $headers.keys) {
        $request.Headers.Add($key, $headers[$key])
    }
 
    if ( ($method.ToUpper() -eq "POST") -or ($method.ToUpper() -eq "PUT") ) {
        #make key value list, not json when done
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($canon_params)
        $request.ContentType = 'application/x-www-form-urlencoded'
        $request.ContentLength = $bytes.Length
                 
        [System.IO.Stream]$outputStream = [System.IO.Stream]$request.GetRequestStream()
        $outputStream.Write($bytes, 0, $bytes.Length)
        $outputStream.Close()
        Remove-Variable -Name outputStream
    }

    Write-Debug $request.Headers['Authorization']
    Write-Debug $request.Headers['X-Duo-Date']

    try {
        [System.Net.HttpWebResponse]$response = $request.GetResponse()
       
        $sr = New-Object System.IO.StreamReader($response.GetResponseStream())
        $txt = $sr.ReadToEnd()
        $sr.Close()
        
        try {
            $psobj = ConvertFrom-Json -InputObject $txt
        }
        catch {
            Write-Warning $txt
            throw "Json Exception"
        }
    }
    catch [Net.WebException] { 
        [System.Net.HttpWebResponse]$response = $_.Exception.Response
        $sr = New-Object System.IO.StreamReader($response.GetResponseStream())
        $txt = $sr.ReadToEnd()
        $sr.Close()
        #Write-Warning $txt
        Throw $txt
    }
    catch {
        throw $_
    }
    finally {
        $response.Close()
        $response.Dispose()
    }
    return $psobj
}