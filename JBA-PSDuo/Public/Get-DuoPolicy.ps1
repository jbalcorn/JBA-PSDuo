function Get-DuoPolicy {
    Param (
        [Parameter(Mandatory = $true)][string]$duoKeyFile,
        [parameter(Mandatory = $false)][String]$policyID,
        [parameter(Mandatory = $false)][Int32]$limit
    )

    $duoKey = Get-DuoKey -keyfile $duokeyfile
    
    [string]$method = "GET"
    [string]$path = "/admin/v2/policies"

    [string[]]$param = "limit"

    $parameters = New-Object System.Collections.Hashtable

    if ($policyID -eq 'summary') {
        $path += '/summary'
    }
    elseif ($policyID -eq 'global') {
        $path += '/global'
    }
    elseif ($policyID) {
        $path += "/$($policyID)"
    }

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