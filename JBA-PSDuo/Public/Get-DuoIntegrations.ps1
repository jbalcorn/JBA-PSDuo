function Get-DuoIntegrations {
    Param (
        [Parameter(Mandatory = $true)][string]$duoKeyFile
    )

    $duoKey = Get-DuoKey -keyfile $duokeyfile
    
    [string]$method = "GET"
    [string]$path = "/admin/v2/integrations"

    [string[]]$param = "limit"

    $parameters = New-Object System.Collections.Hashtable

    foreach ($p in $param) {
        if (Get-Variable -Name $p -ErrorAction SilentlyContinue) {
            if ((Get-Variable -Name $p -ValueOnly) -ne "") {
                $parameters.Add($p, (Get-Variable -Name $p -ValueOnly))
            }
        }
    }

    try {
        $request = Get-DuoAPIResponse -duoKey $duoKey -method $method -path $path -parameters $parameters -sig_version 5
    }
    catch {
        throw $_
    }
    return $request
}