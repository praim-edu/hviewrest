$queryableDataObjects = @(
    "ADUserOrGroupSummaryView",
    "ApplicationIconInfo",
    "ApplicationInfo",
    "DesktopSummaryView",
    "EntitledUserOrGroupGlobalSummaryView",
    "EntitledUserOrGroupLocalSummaryView",
    "EventSummaryView",
    "FarmHealthInfo",
    "FarmSummaryView",
    "GlobalApplicationEntitlementInfo",
    "GlobalEntitlementSummaryView",
    "MachineNamesView",
    "MachineSummaryView",
    "PersistentDiskInfo",
    "PodAssignmentInfo",
    "RDSServerInfo",
    "RDSServerSummaryView",
    "RegisteredPhysicalMachineInfo",
    "SessionGlobalSummaryView",
    "SessionLocalSummaryView",
    "TaskInfo",
    "UserHomeSiteInfo")

function Get-HViewQueryResults
{
    Param
    (
        [string]$server,
        [string]$user,
        [string]$password,
        [string]$domain,
        [string]$entity,
        [string]$command,
        [string]$property,
        [string]$value
    )
    # Ignora errori certificati
    #Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -ParticipateInCeip $false
    # Connessione al server hview
    $hvServer = Connect-HVServer -server $server -user $user -password $password -domain $domain
    # Popolo variabile servizi di query
    $hvServices = $hvServer.ExtensionData
    # Nuova istanza oggetto servizio query
    $queryService = New-Object VMware.Hv.QueryServiceService
    # Nuova istanza oggetto query definition
    $queryDefinition = New-Object VMware.Hv.QueryDefinition
    # Controllo se entity fa parte dei valori possibili
    $entity = $queryableDataObjects -match "$entity"
    # Controllo che entity sia valida
    if ($entity -eq $null -or $entity -eq "") {
        return $null
    }
    # Imposto su quale entita fare la query
    $queryDefinition.queryEntityType = $entity
    # Eseguo la query
    try {
        $queryResults = $queryService.QueryService_Create($hvServices, $queryDefinition)
        # Filtro i risultati della query
        $result = foreach ($obj in $queryResults.Results) { $obj.$command }
        $result2 = foreach ($obj2 in $result) { if ($obj2.$property -match $value) { $obj2 } }
        # Elimino la query
        $queryService.QueryService_Delete($hvServices, $queryResults.Id)
    }
    catch {
        return $null
    }
    # Disconnessione dal server hview
    #Disconnect-HVServer -Server $hvServer
    # Restituisco i risultati della query
    return $result2
}

# Create a listener on port 8000
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add('http://+:8000/')
$listener.Start()
'Listening ...'
# Run until you send a GET request to /end
while ($true) {
    $context = $listener.GetContext()

    # Capture the details about the request
    $request = $context.Request

    # Setup a place to deliver a response
    $response = $context.Response

    # Break from loop if GET request sent to /end
    if ($request.Url -match '/end$') {
        break
    } else {
        # Split request URL to get command and options
        $requestvars = ([String]$request.Url).split("/");

        $server = $($args[0])
        $user = $($args[1])
        $password = $($args[2])
        $domain = $($args[3])

        if ($server -ne $null -and
            $user -ne $null -and
            $password -ne $null -and
            $domain -ne $null -and
            $requestvars[3] -ne $null -and
            $requestvars[3] -ne "") {
            # Esegui la funzione Get-HViewQueryResults con argomento in ingresso
            $result = Get-HViewQueryResults -server $server -user $user -password $password -domain $domain -entity $requestvars[3] -command $requestvars[4] -property $requestvars[5] -value $requestvars[6] 
        }
        # Convert the returned data to JSON and set the HTTP content type to JSON
        $message = ConvertTo-Json $result;
        $response.ContentType = 'application/json';

       # Return empty message if message is null
       if ($message -eq $null) { $message = "" }

       # Convert the data to UTF8 bytes
       [byte[]]$buffer = [System.Text.Encoding]::UTF8.GetBytes($message)
       
       # Set length of response
       $response.ContentLength64 = $buffer.length
       
       # Write response out and close
       $output = $response.OutputStream
       $output.Write($buffer, 0, $buffer.length)
       $output.Close()
    }
}

#Terminate the listener
$listener.Stop()