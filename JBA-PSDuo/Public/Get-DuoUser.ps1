function Get-DuoUser {
    Param (
        [Parameter(Mandatory = $true)][string]$duoKeyFile,
        [parameter(Mandatory = $false)][ValidateLength(1, 100)][String]$username,
        [parameter(Mandatory = $false)][ValidateRange(1, 300)][int]$limit = 300
    )

    $duoKey = Get-DuoKey -keyfile $duokeyfile
    
    [string[]]$param = "username", "limit"
    $parameters = New-Object System.Collections.Hashtable

    [string]$method = "GET"
    [string]$path = "/admin/v1/users"
    if ($user_id) {
        $path += "/" + $user_id
    }
    else {
        foreach ($p in $param) {
            if (Get-Variable -Name $p -ErrorAction SilentlyContinue) {
                if ((Get-Variable -Name $p -ValueOnly) -ne "") {
                    $parameters.Add($p, (Get-Variable -Name $p -ValueOnly))
                }
            }
        }
    }

    try {
        $request = Get-DuoAPIResponse -duoKey $duoKey -method $method -path $path -parameters $parameters
    }
    catch {
        throw $_
    }
    return $request
}