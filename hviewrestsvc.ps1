function Get-HViewQueryResults
{
    Param
    (
        [string]$server,
        [string]$user,
        [string]$password,
        [string]$domain,
        [string]$command,
        [string]$property,
        [string]$value
    )
    # Ignora errori certificati
    #Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -ParticipateInCeip $false
    # Connessione al server hview locale
    $hvServer = Connect-HVServer -server $server -user $user -password $password -domain $domain
    # Popolo variabile servizi di query
    $hvServices = $hvServer.ExtensionData
    # Nuova istanza oggetto servizio query
    $queryService = New-Object VMware.Hv.QueryServiceService
    # Nuova istanza oggetto query definition
    $queryDefinition = New-Object VMware.Hv.QueryDefinition
    # Imposto su quale entità fare la query
    $queryDefinition.queryEntityType = 'SessionLocalSummaryView'
    # Eseguo la query
    $queryResults = $queryService.QueryService_Create($hvServices, $queryDefinition)
    # Restituisco i risultati della query
    $result = foreach ($obj in $queryResults.Results) { $obj.$command }
    $result2 = foreach ($obj2 in $result) { if ($obj2.$property -match $value) { $obj2 } }
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

        # If a request is sent to http:// :8000/namesdata
        if ($requestvars[3] -eq "namesdata" -or $requestvars[3] -eq "sessiondata") {
            # Esegui la funzione Get-HViewQueryResults con argomento in ingresso
            $result = Get-HViewQueryResults -server $args[0] -user $args[1] -password $args[2] -domain $args[3] -command $requestvars[3] -property $requestvars[4] -value $requestvars[5]
            # Convert the returned data to JSON and set the HTTP content type to JSON
            $message = ConvertTo-Json $result;
            $response.ContentType = 'application/json';
       } else {
            # If no matching subdirectory/route is found generate a 404 message
            $message = "This is not the page you're looking for.";
            $response.ContentType = 'text/html';
       }

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
