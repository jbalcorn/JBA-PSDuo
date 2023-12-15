function Update-DuoPolicy {
    Param (
        [Parameter(Mandatory = $true)][string]$duoKeyFile,
        [parameter(Mandatory = $true)][String]$policyID,
        [parameter(Mandatory = $false)][string]$updates
    )

    $duoKey = Get-DuoKey -keyfile $duokeyfile
    
    [string]$method = "PUT"
    [string]$path = "/admin/v2/policies/{0}" -f $policyID

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
        $request = Invoke-DuoUpdate -duoKey $duoKey -method $method -path $path -parameters $parameters -body $updates -bodyformat 'application/json' -sig_version 5
    }
    catch {
        throw $_
    }
    return $request
}