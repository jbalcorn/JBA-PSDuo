function Get-DuoAuthLogs {
    <# 
    .Synopsis
    Used to get Duo v2 Authentication logs
    .Description
    Returns a collection of log entries See: https://duo.com/docs/adminapi#logs
    .Parameter mintime
    DateTime value - Date of first log to retrieve
    .Parameter users
    String Array. List of users to search for
    .Parameter applications
    String array. list of applications to search for, must use the key, not the name
    .parameter event_types
    String. Either "authentication" or "enrollment". If not present, searches for both.
    .parameter factors
    String Array.  Array of factors to search for.  Default is search all.
    .Example
    # Get 2 days of auth logs for 2 users
    $users = 'jp026791','jp025043'
    Get-DuoAuthLogs -mintime (Get-Date).AddDays(-2) -users $users -event_types authentication
    .Example
    # Get all authentication logs recieved on or after 30 days ago
    Get-DuoAuthLogs -mintime (Get-Date).AddDays(-30)
#>

    param
    (
        [Parameter(Mandatory = $true)][string]$duokeyfile,    
        [parameter(Mandatory = $false)][DateTime]$mintime,
        [parameter(Mandatory = $false)][string[]]$users,
        [parameter(Mandatory = $false)][string[]]$applications,
        [parameter(Mandatory = $false)][string[]]$factors,
        [parameter(Mandatory = $false)][ValidateSet('authentication', 'enrollment')][string]$event_types,
        [parameter(Mandatory = $false)][ValidateSet('success', 'denied', 'fraud')][string]$results,
        [Parameter(Mandatory = $false)][int]$limit = 1000
    )

    $duoKey = Get-DuoKey -keyfile $duokeyfile

    [string]$method = "GET"
    [string]$path = "/admin/v2/logs/authentication"
    
    [string[]]$param = "users", "applications", "factors", "event_types", "results", "limit"

    $parameters = New-Object System.Collections.Hashtable

    $epoch = Get-Date -Date "1970-01-01T00:00:00+00:00"
    if ($mintime) {
        try {
            $mintime13 = ((New-TimeSpan -Start $epoch -End $mintime).TotalMilliSeconds).ToInt64([System.Globalization.CultureInfo]::InvariantCulture)
        }
        catch {
            Throw "Mintime value is not a DateTime: $($error[0].Exception.message)"
        }
    }
    else {
        # Default to 1 day
        $mintime13 = ((New-TimeSpan -Start $epoch -End (Get-Date).AddDays(-1)).TotalMilliSeconds).ToInt64([System.Globalization.CultureInfo]::InvariantCulture)
    }
    $Parameters.Add("mintime", $mintime13)
    $parameters.Add("maxtime", ((New-TimeSpan -Start $epoch -End (Get-Date)).TotalMilliSeconds).ToInt64([System.Globalization.CultureInfo]::InvariantCulture))
    $parameters.Add("sort", "ts:asc")


    foreach ($p in $param) {
        if (Get-Variable -Name $p -ErrorAction SilentlyContinue) {
            if ((Get-Variable -Name $p -ValueOnly) -ne "") {
                $parameters.Add($p, (Get-Variable -Name $p -ValueOnly))
            }
        }
    }

    $response = Get-DuoAPIResponse -duoKey $duoKey -method $method -path $path -parameters $parameters
    return $response
}