function List-StorageAccountKeys {

    param(
    [parameter(Mandatory=$true)]
    [String]
    $SubscriptionId,

    [parameter(Mandatory=$true)]
    [String]
    $ResourceGroupName,

    [parameter(Mandatory=$true)]
    [String]
    $Name,

    [parameter(Mandatory=$true)]
    [String]
    $Token
    )

    $uri = "https://management.azure.com/subscriptions/$($SubscriptionId)/resourcegroups/$($ResourceGroupName)/providers/Microsoft.Storage/storageAccounts/$($Name)/listKeys?api-version=2015-05-01-preview"

    Write-Debug "Calling endpoint $uri"

    $result = Invoke-RestMethod  -Uri $uri -Method POST -Headers @{ Authorization="Bearer $Token" } -ContentType "application/json"
 
    Write-Debug $result

    return $result.key1
}

function List-CosmosDBKeys {

    param(
    [parameter(Mandatory=$true)]
    [String]
    $SubscriptionId,

    [parameter(Mandatory=$true)]
    [String]
    $ResourceGroupName,

    [parameter(Mandatory=$true)]
    [String]
    $Name,

    [parameter(Mandatory=$true)]
    [String]
    $Token
    )

    $uri = "https://management.azure.com/subscriptions/$($SubscriptionId)/resourcegroups/$($ResourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/$($Name)/listKeys?api-version=2016-03-31"

    Write-Debug "Calling endpoint $uri"

    $result = Invoke-RestMethod  -Uri $uri -Method POST -Headers @{ Authorization="Bearer $Token" } -ContentType "application/json"
 
    Write-Debug $result

    return $result.primaryMasterKey
}

function Create-KeyVaultLinkedService {
    
    param(
    [parameter(Mandatory=$true)]
    [String]
    $TemplatesPath,

    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName,

    [parameter(Mandatory=$true)]
    [String]
    $Name,

    [parameter(Mandatory=$true)]
    [String]
    $Token 
    )

    $keyVaultTemplate = Get-Content -Path "$($TemplatesPath)/key_vault_linked_service.json"
    $keyVault = $keyVaultTemplate.Replace("#LINKED_SERVICE_NAME#", $Name).Replace("#KEY_VAULT_NAME#", $Name)
    $uri = "https://$($WorkspaceName).dev.azuresynapse.net/linkedservices/$($Name)?api-version=2019-06-01-preview"


    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $keyVault -Headers @{ Authorization="Bearer $Token" } -ContentType "application/json"
 
    return $result
}

function Create-BlobStorageLinkedService {
    
    param(
    [parameter(Mandatory=$true)]
    [String]
    $TemplatesPath,

    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName,

    [parameter(Mandatory=$true)]
    [String]
    $Name,

    [parameter(Mandatory=$true)]
    [String]
    $Key,

    [parameter(Mandatory=$true)]
    [String]
    $Token 
    )

    $keyVaultTemplate = Get-Content -Path "$($TemplatesPath)/blob_storage_linked_service.json"
    $keyVault = $keyVaultTemplate.Replace("#LINKED_SERVICE_NAME#", $Name).Replace("#STORAGE_ACCOUNT_NAME#", $Name).Replace("#STORAGE_ACCOUNT_KEY#", $Key)
    $uri = "https://$($WorkspaceName).dev.azuresynapse.net/linkedservices/$($Name)?api-version=2019-06-01-preview"

    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $keyVault -Headers @{ Authorization="Bearer $Token" } -ContentType "application/json"
 
    return $result
}

function Create-DataLakeLinkedService {
    
    param(
    [parameter(Mandatory=$true)]
    [String]
    $TemplatesPath,

    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName,

    [parameter(Mandatory=$true)]
    [String]
    $Name,

    [parameter(Mandatory=$true)]
    [String]
    $Key,

    [parameter(Mandatory=$true)]
    [String]
    $Token 
    )

    $itemTemplate = Get-Content -Path "$($TemplatesPath)/data_lake_linked_service.json"
    $item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", $Name).Replace("#STORAGE_ACCOUNT_NAME#", $Name).Replace("#STORAGE_ACCOUNT_KEY#", $Key)
    $uri = "https://$($WorkspaceName).dev.azuresynapse.net/linkedservices/$($Name)?api-version=2019-06-01-preview"

    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $Token" } -ContentType "application/json"
    
    return $result
}

function Create-CosmosDBLinkedService {
    
    param(
    [parameter(Mandatory=$true)]
    [String]
    $TemplatesPath,

    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName,

    [parameter(Mandatory=$true)]
    [String]
    $Name,

    [parameter(Mandatory=$true)]
    [String]
    $Database,

    [parameter(Mandatory=$true)]
    [String]
    $Key,

    [parameter(Mandatory=$true)]
    [String]
    $Token 
    )

    $cosmosDbTemplate = Get-Content -Path "$($TemplatesPath)/cosmos_db_linked_service.json"
    $cosmosDb = $cosmosDbTemplate.Replace("#LINKED_SERVICE_NAME#", $Name).Replace("#COSMOSDB_ACCOUNT_NAME#", $Name).Replace("#COSMOSDB_DATABASE_NAME#", $Database).Replace("#COSMOSDB_ACCOUNT_KEY#", $Key)
    $uri = "https://$($WorkspaceName).dev.azuresynapse.net/linkedServices/$($Name)?api-version=2019-06-01-preview"

    Write-Information "Calling endpoint $uri"

    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $cosmosDb -Headers @{ Authorization="Bearer $Token" } -ContentType "application/json"
 
    Write-Information $result

    return $result
}

function Create-SQLPoolKeyVaultLinkedService {
    
    param(
    [parameter(Mandatory=$true)]
    [String]
    $TemplatesPath,

    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName,

    [parameter(Mandatory=$true)]
    [String]
    $Name,

    [parameter(Mandatory=$true)]
    [String]
    $DatabaseName,

    [parameter(Mandatory=$true)]
    [String]
    $UserName,

    [parameter(Mandatory=$true)]
    [String]
    $KeyVaultLinkedServiceName,

    [parameter(Mandatory=$true)]
    [String]
    $SecretName,

    [parameter(Mandatory=$true)]
    [String]
    $Token 
    )

    $itemTemplate = Get-Content -Path "$($TemplatesPath)/sql_pool_key_vault_linked_service.json"
    $item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", $Name).Replace("#WORKSPACE_NAME#", $WorkspaceName).Replace("#DATABASE_NAME#", $DatabaseName).Replace("#USER_NAME#", $UserName).Replace("#KEY_VAULT_LINKED_SERVICE_NAME#", $KeyVaultLinkedServiceName).Replace("#SECRET_NAME#", $SecretName)
    $uri = "https://$($WorkspaceName).dev.azuresynapse.net/linkedServices/$($Name)?api-version=2019-06-01-preview"

    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $Token" } -ContentType "application/json"

    return $result
}

function Create-IntegrationRuntime {
    
    param(
    [parameter(Mandatory=$true)]
    [String]
    $TemplatesPath,

    [parameter(Mandatory=$true)]
    [String]
    $SubscriptionId,

    [parameter(Mandatory=$true)]
    [String]
    $ResourceGroupName,

    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName,

    [parameter(Mandatory=$true)]
    [String]
    $Name,

    [parameter(Mandatory=$true)]
    [Int32]
    $CoreCount,

    [parameter(Mandatory=$true)]
    [Int32]
    $TimeToLive,

    [parameter(Mandatory=$true)]
    [String]
    $Token
    )

    $integrationRuntimeTemplate = Get-Content -Path "$($TemplatesPath)/integration_runtime.json"
    $integrationRuntime = $integrationRuntimeTemplate.Replace("#INTEGRATION_RUNTIME_NAME#", $Name).Replace("#CORE_COUNT#", $CoreCount).Replace("#TIME_TO_LIVE#", $TimeToLive)
    $uri = "https://management.azure.com/subscriptions/$($SubscriptionId)/resourcegroups/$($ResourceGroupName)/providers/Microsoft.Synapse/workspaces/$($WorkspaceName)/integrationruntimes/$($Name)?api-version=2019-06-01-preview"

    Write-Output "Calling endpoint $uri"

    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $integrationRuntime -Headers @{ Authorization="Bearer $Token" } -ContentType "application/json"
 
    Write-Output $result
}

function Create-Dataset {
    
    param(
    [parameter(Mandatory=$true)]
    [String]
    $DatasetsPath,

    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName,

    [parameter(Mandatory=$true)]
    [String]
    $Name,

    [parameter(Mandatory=$true)]
    [String]
    $LinkedServiceName,

    [parameter(Mandatory=$true)]
    [String]
    $Token 
    )

    $itemTemplate = Get-Content -Path "$($DatasetsPath)/$($Name).json"
    $item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", $LinkedServiceName)
    $uri = "https://$($WorkspaceName).dev.azuresynapse.net/datasets/$($Name)?api-version=2019-06-01-preview"

    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $Token" } -ContentType "application/json"
    
    return $result
}

function Create-Pipeline {
    
    param(
    [parameter(Mandatory=$true)]
    [String]
    $PipelinesPath,

    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName,

    [parameter(Mandatory=$true)]
    [String]
    $Name,

    [parameter(Mandatory=$true)]
    [String]
    $FileName,

    [parameter(Mandatory=$false)]
    [Hashtable]
    $Parameters = $null,

    [parameter(Mandatory=$true)]
    [String]
    $Token 
    )

    $item = Get-Content -Path "$($PipelinesPath)/$($FileName).json"
    
    if ($Parameters -ne $null) {
        foreach ($key in $Parameters.Keys) {
            $item = $item.Replace("#$($key)#", $Parameters[$key])
        }
    }

    $uri = "https://$($WorkspaceName).dev.azuresynapse.net/pipelines/$($Name)?api-version=2019-06-01-preview"

    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $Token" } -ContentType "application/json"
    
    return $result
}

function Run-Pipeline {
    
    param(

    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName,

    [parameter(Mandatory=$true)]
    [String]
    $Name,

    [parameter(Mandatory=$true)]
    [String]
    $Token 
    )

    $uri = "https://$($WorkspaceName).dev.azuresynapse.net/pipelines/$($Name)/createRun?api-version=2018-06-01"

    $result = Invoke-RestMethod  -Uri $uri -Method POST -Headers @{ Authorization="Bearer $Token" } -ContentType "application/json"
    
    return $result
}

function Get-PipelineRun {
    
    param(

    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName,

    [parameter(Mandatory=$true)]
    [String]
    $RunId,

    [parameter(Mandatory=$true)]
    [String]
    $Token 
    )

    $uri = "https://$($WorkspaceName).dev.azuresynapse.net/pipelineruns/$($RunId)?api-version=2019-06-01-preview"

    $result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization="Bearer $Token" }
    
    return $result
}

function Wait-ForPipelineRun {
    
    param(

    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName,

    [parameter(Mandatory=$true)]
    [String]
    $RunId,

    [parameter(Mandatory=$true)]
    [String]
    $Token 
    )

    Write-Information "Waiting for any pending operation to be properly triggered..."
    Start-Sleep -Seconds 20

    $result = Get-PipelineRun -WorkspaceName $WorkspaceName -RunId $RunId -Token $Token

    while ($result.status -eq "InProgress") {
        
        Write-Information "Waiting for operation to complete..."
        Start-Sleep -Seconds 10
        $result = Get-PipelineRun -WorkspaceName $WorkspaceName -RunId $RunId -Token $Token
    }

    return $result
}

function Get-OperationResult {
    
    param(

    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName,

    [parameter(Mandatory=$true)]
    [String]
    $OperationId,

    [parameter(Mandatory=$true)]
    [String]
    $Token 
    )

    $uri = "https://$($WorkspaceName).dev.azuresynapse.net/operationResults/$($OperationId)?api-version=2019-06-01-preview"

    $result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization="Bearer $Token" }
    
    return $result
}

function Wait-ForOperation {
    
    param(

    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName,

    [parameter(Mandatory=$true)]
    [String]
    $OperationId,

    [parameter(Mandatory=$true)]
    [String]
    $Token 
    )

    $uri = "https://$($WorkspaceName).dev.azuresynapse.net/operationResults/$($OperationId)?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization="Bearer $Token" }

    while ($result.status -ne $null) {
        
        if ($result.status -eq "Failed") {
            throw $result.error
        }

        Write-Information "Waiting for operation to complete (status is $($result.status))..."
        Start-Sleep -Seconds 10
        $result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization="Bearer $Token" }
    }

    return $result
}

function Delete-ASAObject {
    
    param(
   
    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName,

    [parameter(Mandatory=$true)]
    [String]
    $Category,

    [parameter(Mandatory=$true)]
    [String]
    $Name,

    [parameter(Mandatory=$true)]
    [String]
    $Token 
    )

    $uri = "https://$($WorkspaceName).dev.azuresynapse.net/$($Category)/$($Name)?api-version=2019-06-01-preview"

    $result = Invoke-RestMethod  -Uri $uri -Method DELETE -Headers @{ Authorization="Bearer $Token" }
    
    return $result
}

function Control-SQLPool {

    param(
    [parameter(Mandatory=$true)]
    [String]
    $SubscriptionId,

    [parameter(Mandatory=$true)]
    [String]
    $ResourceGroupName,

    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName,

    [parameter(Mandatory=$true)]
    [String]
    $SQLPoolName,

    [parameter(Mandatory=$true)]
    [String]
    $Action,

    [parameter(Mandatory=$false)]
    [String]
    $SKU,

    [parameter(Mandatory=$true)]
    [String]
    $Token
    )

    $uri = "https://management.azure.com/subscriptions/$($SubscriptionId)/resourcegroups/$($ResourceGroupName)/providers/Microsoft.Synapse/workspaces/$($WorkspaceName)/sqlPools/$($SQLPoolName)#ACTION#?api-version=2019-06-01-preview"
    $method = "POST"
    $body = $null

    if (($Action.ToLowerInvariant() -eq "pause") -or ($Action.ToLowerInvariant() -eq "resume")) {

        $uri = $uri.Replace("#ACTION#", "/$($Action)")

    } elseif ($Action.ToLowerInvariant() -eq "scale") {
        
        $uri = $uri.Replace("#ACTION#", "")
        $method = "PATCH"
        $body = "{""sku"":{""name"":""$($SKU)""}}"

    } else {
        
        throw "The $($Action) control action is not supported."

    }

    $result = Invoke-RestMethod  -Uri $uri -Method $method -Body $body -Headers @{ Authorization="Bearer $Token" } -ContentType "application/json"

    return $result
}

function Get-SQLPool {

    param(
    [parameter(Mandatory=$true)]
    [String]
    $SubscriptionId,

    [parameter(Mandatory=$true)]
    [String]
    $ResourceGroupName,

    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName,

    [parameter(Mandatory=$true)]
    [String]
    $SQLPoolName,

    [parameter(Mandatory=$true)]
    [String]
    $Token
    )

    $uri = "https://management.azure.com/subscriptions/$($SubscriptionId)/resourcegroups/$($ResourceGroupName)/providers/Microsoft.Synapse/workspaces/$($WorkspaceName)/sqlPools/$($SQLPoolName)?api-version=2019-06-01-preview"

    $result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization="Bearer $Token" } -ContentType "application/json"

    return $result
}

function Wait-ForSQLPool {

    param(
    [parameter(Mandatory=$true)]
    [String]
    $SubscriptionId,

    [parameter(Mandatory=$true)]
    [String]
    $ResourceGroupName,

    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName,

    [parameter(Mandatory=$true)]
    [String]
    $SQLPoolName,

    [parameter(Mandatory=$false)]
    [String]
    $TargetStatus,

    [parameter(Mandatory=$true)]
    [String]
    $Token
    )

    Write-Information "Waiting for any pending operation to be properly triggered..."
    Start-Sleep -Seconds 20

    $result = Get-SQLPool -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -WorkspaceName $WorkspaceName -SQLPoolName $SQLPoolName -Token $Token

    if ($TargetStatus) {
        while ($result.properties.status -ne $TargetStatus) {
            Write-Information "Current status is $($result.properties.status). Waiting for $($TargetStatus) status..."
            Start-Sleep -Seconds 10
            $result = Get-SQLPool -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -WorkspaceName $WorkspaceName -SQLPoolName $SQLPoolName -Token $Token
        }
    }

    Write-Information "The SQL pool has now the $($TargetStatus) status."
    return $result
}

function Wait-ForSQLQuery {

    param(
    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName,

    [parameter(Mandatory=$true)]
    [String]
    $SQLPoolName,

    [parameter(Mandatory=$true)]
    [String]
    $Label,

    [parameter(Mandatory=$false)]
    [DateTime]
    $ReferenceTime,

    [parameter(Mandatory=$true)]
    [String]
    $Token
    )

    Write-Information "Waiting for any pending operation to be properly triggered..."
    Start-Sleep -Seconds 10
    
    $sql = "select status from sys.dm_pdw_exec_requests where [label] = '$($Label)' and submit_time > '$($ReferenceTime.ToString("yyyy-MM-dd HH:mm:ss"))'"

    $result = Execute-SQLQuery -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -SQLQuery $sql -Token $synapseSQLToken
    while (($result.data[0][0] -ne "Cancelled") -and ($result.data[0][0] -ne "Completed")) {
        Write-Information "Current status is $($result.data[0][0]). Waiting for query to finish..."
            Start-Sleep -Seconds 10
            $result = Execute-SQLQuery -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -SQLQuery $sql -Token $synapseSQLToken
    }

    if ($result.data[0][0] -eq "Cancelled") {
        throw "There was an error executing the query."
    }

    Write-Information "The query was successfully executed."
}

function Execute-SQLQuery {

    param(
    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName,

    [parameter(Mandatory=$true)]
    [String]
    $SQLPoolName,

    [parameter(Mandatory=$true)]
    [String]
    $SQLQuery,

    [parameter(Mandatory=$false)]
    [Boolean]
    $ForceReturn,

    [parameter(Mandatory=$true)]
    [String]
    $Token
    )

    $uri = "https://$($WorkspaceName).sql.azuresynapse.net:1443/databases/$($SQLPoolName)/query?api-version=2018-08-01-preview&application=ArcadiaSqlEditor&topRows=5000&queryTimeoutInMinutes=59&allResultSets=true"

    $headers = @{ 
        Authorization="Bearer $($Token)"
    }

    if ($ForceReturn) {
        try {
            Invoke-WebRequest -Uri $uri -Method POST -Body $SQLQuery -Headers $headers -ContentType "application/x-www-form-urlencoded; charset=UTF-8" -UseBasicParsing -TimeoutSec 15
        } catch {}
        return
    }

    $rawResult = Invoke-WebRequest -Uri $uri -Method POST -Body $SQLQuery -Headers $headers `
        -ContentType "application/x-www-form-urlencoded; charset=UTF-8" -UseBasicParsing

    $result = ConvertFrom-Json $rawResult.Content

    $errors = @()
    foreach ($partialResult in $result) {
        if (-not $partialResult.isSuccess) {

            $errors += $partialResult.message
        }
    }
    if ($errors.Count -gt 0) {
        throw (-join $errors)
    }

    return $result
}

function Execute-SQLScriptFile {

    param(
    [parameter(Mandatory=$true)]
    [String]
    $SQLScriptsPath,

    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName,

    [parameter(Mandatory=$true)]
    [String]
    $SQLPoolName,

    [parameter(Mandatory=$true)]
    [String]
    $FileName,

    [parameter(Mandatory=$false)]
    [Hashtable]
    $Parameters,

    [parameter(Mandatory=$false)]
    [Boolean]
    $ForceReturn,

    [parameter(Mandatory=$true)]
    [String]
    $Token
    )

    $sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/$($FileName).sql"

    if ($Parameters) {
        foreach ($key in $Parameters.Keys) {
            $sqlQuery = $sqlQuery.Replace("#$($key)#", $Parameters[$key])
        }
    }

    return Execute-SQLQuery -WorkspaceName $WorkspaceName -SQLPoolName $SQLPoolName -SQLQuery $sqlQuery -ForceReturn $ForceReturn -Token $Token
}

function Create-SQLScript {
    
    param(
    [parameter(Mandatory=$true)]
    [String]
    $TemplatesPath,

    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName,

    [parameter(Mandatory=$true)]
    [String]
    $Name,

    [parameter(Mandatory=$true)]
    [String]
    $TemplateFileName,

    [parameter(Mandatory=$true)]
    [String]
    $ScriptFileName,

    [parameter(Mandatory=$true)]
    [String]
    $Token 
    )

    $item = Get-Content -Raw -Path "$($TemplatesPath)/$($TemplateFileName).json"
    $query = Get-Content -Raw -Path $ScriptFileName -Encoding utf8
    $query = (ConvertTo-Json $query.ToString())

    $item = $item.Replace("#SQL_SCRIPT_NAME#", $Name).Replace("#SQL_SCRIPT_QUERY#", $query)

    Write-Information $item

    $uri = "https://$($WorkspaceName).dev.azuresynapse.net/sqlscripts/$($Name)?api-version=2019-06-01-preview"

    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $Token" } -ContentType "application/json"
    
    return $result
}

Export-ModuleMember -Function List-StorageAccountKeys
Export-ModuleMember -Function List-CosmosDBKeys
Export-ModuleMember -Function Create-KeyVaultLinkedService
Export-ModuleMember -Function Create-BlobStorageLinkedService
Export-ModuleMember -Function Create-DataLakeLinkedService
Export-ModuleMember -Function Create-CosmosDBLinkedService
Export-ModuleMember -Function Create-SQLPoolKeyVaultLinkedService
Export-ModuleMember -Function Create-IntegrationRuntime
Export-ModuleMember -Function Create-Dataset
Export-ModuleMember -Function Create-Pipeline
Export-ModuleMember -Function Run-Pipeline
Export-ModuleMember -Function Get-PipelineRun
Export-ModuleMember -Function Wait-ForPipelineRun
Export-ModuleMember -Function Get-OperationResult
Export-ModuleMember -Function Wait-ForOperation
Export-ModuleMember -Function Delete-ASAObject
Export-ModuleMember -Function Control-SQLPool
Export-ModuleMember -Function Get-SQLPool
Export-ModuleMember -Function Wait-ForSQLPool
Export-ModuleMember -Function Execute-SQLQuery
Export-ModuleMember -Function Execute-SQLScriptFile
Export-ModuleMember -Function Wait-ForSQLQuery
Export-ModuleMember -Function Create-SQLScript