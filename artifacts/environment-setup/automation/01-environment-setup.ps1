Remove-Module solliance-synapse-automation
Import-Module ".\artifacts\environment-setup\solliance-synapse-automation"

$InformationPreference = "Continue"

# These need to be run only if the Az modules are not yet installed
# Install-Module -Name Az -AllowClobber -Scope CurrentUser
# Install-Module -Name Az.CosmosDB -AllowClobber -Scope CurrentUser
# Import-Module Az.CosmosDB

#
# TODO: Keep all required configuration in C:\LabFiles\AzureCreds.ps1 file
. C:\LabFiles\AzureCreds.ps1

$userName = $AzureUserName                # READ FROM FILE
$password = $AzurePassword                # READ FROM FILE
$clientId = $TokenGeneratorClientId       # READ FROM FILE
$sqlPassword = $AzureSQLPassword          # READ FROM FILE

$securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $userName, $SecurePassword

Connect-AzAccount -Credential $cred | Out-Null

$resourceGroupName = (Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -like "*L400*" }).ResourceGroupName
$uniqueId =  (Get-AzResourceGroup -Name $resourceGroupName).Tags["DeploymentId"]
$subscriptionId = (Get-AzContext).Subscription.Id
$tenantId = (Get-AzContext).Tenant.Id

$templatesPath = ".\artifacts\environment-setup\templates"
$datasetsPath = ".\artifacts\environment-setup\datasets"
$pipelinesPath = ".\artifacts\environment-setup\pipelines"
$sqlScriptsPath = ".\artifacts\environment-setup\sql"
$workspaceName = "asaworkspace$($uniqueId)"
$cosmosDbAccountName = "asacosmosdb$($uniqueId)"
$cosmosDbDatabase = "CustomerProfile"
$cosmosDbContainer = "OnlineUserProfile01"
$dataLakeAccountName = "asadatalake$($uniqueId)"
$blobStorageAccountName = "asastore$($uniqueId)"
$keyVaultName = "asakeyvault$($uniqueId)"
$keyVaultSQLUserSecretName = "SQL-USER-ASA"
$sqlPoolName = "SQLPool01"
$integrationRuntimeName = "AzureIntegrationRuntime01"


$ropcBodyCore = "client_id=$($clientId)&username=$($userName)&password=$($password)&grant_type=password"
$global:ropcBodySynapse = "$($ropcBodyCore)&scope=https://dev.azuresynapse.net/.default"
$global:ropcBodyManagement = "$($ropcBodyCore)&scope=https://management.azure.com/.default"
$global:ropcBodySynapseSQL = "$($ropcBodyCore)&scope=https://sql.azuresynapse.net/.default"

$global:synapseToken = ""
$global:synapseSQLToken = ""
$global:managementToken = ""

$global:tokenTimes = [ordered]@{
        Synapse = (Get-Date -Year 1)
        SynapseSQL = (Get-Date -Year 1)
        Management = (Get-Date -Year 1)
}

Write-Information "Assign Ownership to L400 Proctors on Synapse Workspace"
Assign-SynapseRole -WorkspaceName $workspaceName -RoleId "6e4bf58a-b8e1-4cc3-bbf9-d73143322b78" -PrincipalId "37548b2e-e5ab-4d2b-b0da-4d812f56c30e"  # Workspace Admin
Assign-SynapseRole -WorkspaceName $workspaceName -RoleId "7af0c69a-a548-47d6-aea3-d00e69bd83aa" -PrincipalId "37548b2e-e5ab-4d2b-b0da-4d812f56c30e"  # SQL Admin
Assign-SynapseRole -WorkspaceName $workspaceName -RoleId "c3a6d2f1-a26f-4810-9b0f-591308d5cbf1" -PrincipalId "37548b2e-e5ab-4d2b-b0da-4d812f56c30e"  # Apache Spark Admin

Write-Information "Create KeyVault linked service $($keyVaultName)"

$result = Create-KeyVaultLinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $keyVaultName
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

Write-Information "Create Integration Runtime $($integrationRuntimeName)"

$result = Create-IntegrationRuntime -TemplatesPath $templatesPath -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -Name $integrationRuntimeName -CoreCount 16 -TimeToLive 60
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

Write-Information "Create Data Lake linked service $($dataLakeAccountName)"

$dataLakeAccountKey = List-StorageAccountKeys -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -Name $dataLakeAccountName
$result = Create-DataLakeLinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $dataLakeAccountName  -Key $dataLakeAccountKey
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

Write-Information "Create Blob Storage linked service $($blobStorageAccountName)"

$blobStorageAccountKey = List-StorageAccountKeys -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -Name $blobStorageAccountName
$result = Create-BlobStorageLinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $blobStorageAccountName  -Key $blobStorageAccountKey
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

Write-Information "Start the $($sqlPoolName) SQL pool if needed."

$result = Get-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName
if ($result.properties.status -ne "Online") {
    Control-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -Action resume
    Wait-ForSQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -TargetStatus Online
}

Write-Information "Scale up the $($sqlPoolName) SQL pool to DW3000c to prepare for baby MOADs import."

Control-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -Action scale -SKU DW3000c
Wait-ForSQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -TargetStatus Online

Write-Information "Create SQL logins in master SQL pool"

$params = @{ PASSWORD = $sqlPassword }
$result = Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName "master" -FileName "01-create-logins" -Parameters $params
$result

Write-Information "Create SQL users and role assignments in $($sqlPoolName)"

$params = @{ USER_NAME = $userName }
$result = Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -FileName "02-create-users" -Parameters $params
$result

Write-Information "Create schemas in $($sqlPoolName)"

$params = @{}
$result = Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -FileName "03-create-schemas" -Parameters $params
$result

Write-Information "Create tables in the [wwi] schema in $($sqlPoolName)"

$params = @{}
$result = Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -FileName "04-create-tables-in-wwi-schema" -Parameters $params
$result


Write-Information "Create tables in the [wwi_ml] schema in $($sqlPoolName)"

$dataLakeAccountKey = List-StorageAccountKeys -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -Name $dataLakeAccountName
$params = @{ 
        DATA_LAKE_ACCOUNT_NAME = $dataLakeAccountName  
        DATA_LAKE_ACCOUNT_KEY = $dataLakeAccountKey 
}
$result = Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -FileName "05-create-tables-in-wwi-ml-schema" -Parameters $params
$result


Write-Information "Create tables in the [wwi_security] schema in $($sqlPoolName)"

$params = @{ 
        DATA_LAKE_ACCOUNT_NAME = $dataLakeAccountName  
}
$result = Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -FileName "06-create-tables-in-wwi-security-schema" -Parameters $params
$result


Write-Information "Create linked service for SQL pool $($sqlPoolName) with user asa.sql.admin"

$linkedServiceName = $sqlPoolName.ToLower()
$result = Create-SQLPoolKeyVaultLinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $linkedServiceName -DatabaseName $sqlPoolName `
                 -UserName "asa.sql.admin" -KeyVaultLinkedServiceName $keyVaultName -SecretName $keyVaultSQLUserSecretName
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

Write-Information "Create linked service for SQL pool $($sqlPoolName) with user asa.sql.highperf"

$linkedServiceName = "$($sqlPoolName.ToLower())_highperf"
$result = Create-SQLPoolKeyVaultLinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $linkedServiceName -DatabaseName $sqlPoolName `
                 -UserName "asa.sql.highperf" -KeyVaultLinkedServiceName $keyVaultName -SecretName $keyVaultSQLUserSecretName
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

Write-Information "Create data sets for data load in SQL pool $($sqlPoolName)"

$loadingDatasets = @{
        wwi02_date_adls = $dataLakeAccountName
        wwi02_product_adls = $dataLakeAccountName
        wwi02_sale_small_adls = $dataLakeAccountName
        wwi02_date_asa = $sqlPoolName.ToLower()
        wwi02_product_asa = $sqlPoolName.ToLower()
        wwi02_sale_small_asa = "$($sqlPoolName.ToLower())_highperf"
}

foreach ($dataset in $loadingDatasets.Keys) {
        Write-Information "Creating dataset $($dataset)"
        $result = Create-Dataset -DatasetsPath $datasetsPath -WorkspaceName $workspaceName -Name $dataset -LinkedServiceName $loadingDatasets[$dataset]
        Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId
}

Write-Information "Create pipeline to load the SQL pool"

$params = @{
        BLOB_STORAGE_LINKED_SERVICE_NAME = $blobStorageAccountName
}
$loadingPipelineName = "Setup - Load SQL Pool"
$fileName = "load_sql_pool_from_data_lake"

Write-Information "Creating pipeline $($loadingPipelineName)"

$result = Create-Pipeline -PipelinesPath $pipelinesPath -WorkspaceName $workspaceName -Name $loadingPipelineName -FileName $fileName -Parameters $params
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

Write-Information "Running pipeline $($loadingPipelineName)"

$result = Run-Pipeline -WorkspaceName $workspaceName -Name $loadingPipelineName
$result = Wait-ForPipelineRun -WorkspaceName $workspaceName -RunId $result.runId
$result

Write-Information "Deleting pipeline $($loadingPipelineName)"

$result = Delete-ASAObject -WorkspaceName $workspaceName -Category "pipelines" -Name $loadingPipelineName
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

foreach ($dataset in $loadingDatasets.Keys) {
        Write-Information "Deleting dataset $($dataset)"
        $result = Delete-ASAObject -WorkspaceName $workspaceName -Category "datasets" -Name $dataset
        Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId
}


Write-Information "Create tables in wwi_perf schema in SQL pool $($sqlPoolName)"

$params = @{}
$scripts = [ordered]@{
        "07-create-wwi-perf-sale-heap" = "CTAS : Sale_Heap"
        "08-create-wwi-perf-sale-partition01" = "CTAS : Sale_Partition01"
        "09-create-wwi-perf-sale-partition02" = "CTAS : Sale_Partition02"
        "10-create-wwi-perf-sale-index" = "CTAS : Sale_Index"
        "11-create-wwi-perf-sale-hash-ordered" = "CTAS : Sale_Hash_Ordered"
        #"12-create-wwi-perf-sale-hash-projection" = "CTAS : Sale_Hash_Projection"              -- will be created in a lab
        #"13-create-wwi-perf-sale-hash-projection2" = "CTAS : Sale_Hash_Projection2"            -- will be created in a lab
        #"14-create-wwi-perf-sale-hash-projection-big" = "CTAS : Sale_Hash_Projection_Big"      -- will be created in a lab
        #"15-create-wwi-perf-sale-hash-projection-big2" = "CTAS : Sale_Hash_Projection_Big2"    -- will be created in a lab
}

foreach ($script in $scripts.Keys) {

        $refTime = (Get-Date).ToUniversalTime()
        Write-Information "Starting $($script) with label $($scripts[$script])"

        # refresh the token, just in case
        Refresh-Token -TokenType "SynapseSQL"
        
        # initiate the script and wait until it finishes
        Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -FileName $script -ForceReturn $true
        Wait-ForSQLQuery -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -Label $scripts[$script] -ReferenceTime $refTime
}

Write-Information "Scale down the $($sqlPoolName) SQL pool to DW1000c after baby MOADs import."

Control-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -Action scale -SKU DW1000c
Wait-ForSQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -TargetStatus Online


Write-Information "Create linked service for SQL pool $($sqlPoolName) with user asa.sql.import01"

$linkedServiceName = "$($sqlPoolName.ToLower())_import01"
$result = Create-SQLPoolKeyVaultLinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $linkedServiceName -DatabaseName $sqlPoolName `
                 -UserName "asa.sql.import01" -KeyVaultLinkedServiceName $keyVaultName -SecretName $keyVaultSQLUserSecretName
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

Write-Information "Create linked service for SQL pool $($sqlPoolName) with user asa.sql.workload01"

$linkedServiceName = "$($sqlPoolName.ToLower())_workload01"
$result = Create-SQLPoolKeyVaultLinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $linkedServiceName -DatabaseName $sqlPoolName `
                 -UserName "asa.sql.workload01" -KeyVaultLinkedServiceName $keyVaultName -SecretName $keyVaultSQLUserSecretName
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

Write-Information "Create linked service for SQL pool $($sqlPoolName) with user asa.sql.workload02"

$linkedServiceName = "$($sqlPoolName.ToLower())_workload02"
$result = Create-SQLPoolKeyVaultLinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $linkedServiceName -DatabaseName $sqlPoolName `
                 -UserName "asa.sql.workload02" -KeyVaultLinkedServiceName $keyVaultName -SecretName $keyVaultSQLUserSecretName
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId


Write-Information "Create data sets for Lab 08"

$datasets = @{
        wwi02_sale_small_workload_01_asa = "$($sqlPoolName.ToLower())_workload01"
        wwi02_sale_small_workload_02_asa = "$($sqlPoolName.ToLower())_workload02"
}

foreach ($dataset in $datasets.Keys) {
        Write-Information "Creating dataset $($dataset)"
        $result = Create-Dataset -DatasetsPath $datasetsPath -WorkspaceName $workspaceName -Name $dataset -LinkedServiceName $datasets[$dataset]
        Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId
}

Write-Information "Create pipelines for Lab 08"

$params = @{}
$workloadPipelines = [ordered]@{
        execute_business_analyst_queries = "Lab 08 - Execute Business Analyst Queries"
        execute_data_analyst_and_ceo_queries = "Lab 08 - Execute Data Analyst and CEO Queries"
}

foreach ($pipeline in $workloadPipelines.Keys) {
        Write-Information "Creating workload pipeline $($workloadPipelines[$pipeline])"
        $result = Create-Pipeline -PipelinesPath $pipelinesPath -WorkspaceName $workspaceName -Name $workloadPipelines[$pipeline] -FileName $pipeline -Parameters $params
        Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId
}


#
# =============== COSMOS DB IMPORT - MUST REMAIN LAST IN SCRIPT !!! ====================
#                         


# Increase RUs in CosmosDB container

$container = Get-AzCosmosDBSqlContainer `
        -ResourceGroupName $resourceGroupName `
        -AccountName $cosmosDbAccountName -DatabaseName $cosmosDbDatabase `
        -Name $cosmosDbContainer

Set-AzCosmosDBSqlContainer -ResourceGroupName $resourceGroupName `
        -AccountName $cosmosDbAccountName -DatabaseName $cosmosDbDatabase `
        -Name $cosmosDbContainer -Throughput 5000 `
        -PartitionKeyKind $container.Resource.PartitionKey.Kind `
        -PartitionKeyPath $container.Resource.PartitionKey.Paths

$name = "wwi02_online_user_profiles_01_adal"
$result = Create-Dataset -DatasetsPath $datasetsPath -WorkspaceName $workspaceName -Name $name -LinkedServiceName $dataLakeAccountName
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

$cosmosDbAccountKey = List-CosmosDBKeys -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -Name $cosmosDbAccountName
$result = Create-CosmosDBLinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $cosmosDbAccountName -Database $cosmosDbDatabase -Key $cosmosDbAccountKey
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

$name = "customer_profile_cosmosdb"
$result = Create-Dataset -DatasetsPath $datasetsPath -WorkspaceName $workspaceName -Name $name -LinkedServiceName $cosmosDbAccountName
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

$name = "Setup - Import User Profile Data into Cosmos DB"
$fileName = "import_customer_profiles_into_cosmosdb"
$result = Create-Pipeline -PipelinesPath $pipelinesPath -WorkspaceName $workspaceName -Name $name -FileName $fileName
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

$pipelineRunResult = Run-Pipeline -WorkspaceName $workspaceName -Name $name
$result = Wait-ForPipelineRun -WorkspaceName $workspaceName -RunId $pipelineRunResult.runId
$result

#
# =============== WAIT HERE FOR PIPELINE TO FINISH - MIGHT TAKE ~45 MINUTES ====================
#                         
#                    COPY 722647 records to CosmosDB ==> SELECT VALUE COUNT(1) FROM C
#

$container = Get-AzCosmosDBSqlContainer `
        -ResourceGroupName $resourceGroupName `
        -AccountName $cosmosDbAccountName -DatabaseName $cosmosDbDatabase `
        -Name $cosmosDbContainer

Set-AzCosmosDBSqlContainer -ResourceGroupName $resourceGroupName `
        -AccountName $cosmosDbAccountName -DatabaseName $cosmosDbDatabase `
        -Name $cosmosDbContainer -Throughput 400 `
        -PartitionKeyKind $container.Resource.PartitionKey.Kind `
        -PartitionKeyPath $container.Resource.PartitionKey.Paths

$name = "Setup - Import User Profile Data into Cosmos DB"
$result = Delete-ASAObject -WorkspaceName $workspaceName -Category "pipelines" -Name $name
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

$name = "customer_profile_cosmosdb"
$result = Delete-ASAObject -WorkspaceName $workspaceName -Category "datasets" -Name $name
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

$name = "wwi02_online_user_profiles_01_adal"
$result = Delete-ASAObject -WorkspaceName $workspaceName -Category "datasets" -Name $name
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

$name = $cosmosDbAccountName
$result = Delete-ASAObject -WorkspaceName $workspaceName -Category "linkedServices" -Name $name
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId
