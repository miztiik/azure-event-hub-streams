// targetScope = 'subscription'

targetScope = 'resourceGroup'

// Parameters
param deploymentParams object
param identityParams object
param appConfigParams object
param storageAccountParams object
param logAnalyticsWorkspaceParams object
param funcParams object
param eventHubParams object
param cosmosDbParams object

param brandTags object

param dateNow string = utcNow('yyyy-MM-dd-hh-mm')

param tags object = union(brandTags, {last_deployed:dateNow})


// Create Identity
module r_usr_mgd_identity 'modules/identity/create_usr_mgd_identity.bicep' = {
  name: '${deploymentParams.enterprise_name_suffix}_${deploymentParams.global_uniqueness}_usr_mgd_identity'
  params: {
    deploymentParams:deploymentParams
    identityParams:identityParams
    tags: tags
  }
}

//Create App Config
module r_app_config 'modules/app_config/create_app_config.bicep' = {
  name: '${appConfigParams.appConfigNamePrefix}_${deploymentParams.global_uniqueness}_config'
  params: {
    deploymentParams:deploymentParams
    appConfigParams: appConfigParams
    tags: tags
  }
}

// Create Cosmos DB
module r_cosmosdb 'modules/database/cosmos.bicep' ={
  name: '${cosmosDbParams.cosmosDbNamePrefix}_${deploymentParams.global_uniqueness}_cosmos_db'
  params: {
    deploymentParams:deploymentParams
    cosmosDbParams:cosmosDbParams
    appConfigName: r_app_config.outputs.appConfigName
    tags: tags
  }
}

// Create the Log Analytics Workspace
module r_logAnalyticsWorkspace 'modules/monitor/log_analytics_workspace.bicep' = {
  name: '${logAnalyticsWorkspaceParams.workspaceName}_${deploymentParams.global_uniqueness}_la'
  params: {
    deploymentParams:deploymentParams
    logAnalyticsWorkspaceParams: logAnalyticsWorkspaceParams
    tags: tags
  }
}


// Create Storage Account
module r_sa 'modules/storage/create_storage_account.bicep' = {
  name: '${storageAccountParams.storageAccountNamePrefix}_${deploymentParams.global_uniqueness}_sa'
  params: {
    deploymentParams:deploymentParams
    storageAccountParams:storageAccountParams
    funcParams: funcParams
    tags: tags
  }
}


// Create Storage Account - Blob container
module r_blob 'modules/storage/create_blob.bicep' = {
  name: '${storageAccountParams.storageAccountNamePrefix}_${deploymentParams.global_uniqueness}_blob'
  params: {
    deploymentParams:deploymentParams
    storageAccountParams:storageAccountParams
    storageAccountName: r_sa.outputs.saName
    storageAccountName_1: r_sa.outputs.saName_1
    logAnalyticsWorkspaceId: r_logAnalyticsWorkspace.outputs.logAnalyticsPayGWorkspaceId
    enableDiagnostics: false
  }
  dependsOn: [
    r_sa
    r_logAnalyticsWorkspace
  ]
}

// Create the function app & Functions
module r_fn_app 'modules/functions/create_function.bicep' = {
  name: '${funcParams.funcNamePrefix}_${deploymentParams.global_uniqueness}_fn_app'
  params: {
    deploymentParams:deploymentParams
    r_usr_mgd_identity_name: r_usr_mgd_identity.outputs.usr_mgd_identity_name
    funcParams: funcParams
    funcSaName: r_sa.outputs.saName_1

    logAnalyticsWorkspaceId: r_logAnalyticsWorkspace.outputs.logAnalyticsPayGWorkspaceId
    enableDiagnostics: true
    tags: tags

    // appConfigName: r_appConfig.outputs.appConfigName

    saName: r_sa.outputs.saName
    blobContainerName: r_blob.outputs.blobContainerName

    cosmos_db_accnt_name: r_cosmosdb.outputs.cosmos_db_accnt_name
    cosmos_db_name: r_cosmosdb.outputs.cosmos_db_name
    cosmos_db_container_name: r_cosmosdb.outputs.cosmos_db_container_name

    event_hub_ns_name: r_event_hub.outputs.event_hub_ns_name
    event_hub_name: r_event_hub.outputs.event_hub_name
  }
  dependsOn: [
    r_sa
    r_logAnalyticsWorkspace
  ]
}


// Create Event Hub
module r_event_hub 'modules/integration/create_event_hub.bicep' = {
  name: '${eventHubParams.eventHubNamePrefix}_${deploymentParams.global_uniqueness}_event_Hub'
  params: {
    deploymentParams:deploymentParams
    eventHubParams:eventHubParams
    tags: tags

    saName: r_sa.outputs.saName
    blobContainerName: r_blob.outputs.blobContainerName
  }
}
