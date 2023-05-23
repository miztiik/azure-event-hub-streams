// SET MODULE DATE
param module_metadata object = {
  module_last_updated : '2023-05-21'
  owner: 'miztiik@github'
}

param deploymentParams object
param eventHubParams object
param tags object


param saName string
param blobContainerName string

// Get Storage Account Reference
resource r_sa 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
  name: saName
}


var event_hub_ns_name = replace('${eventHubParams.eventHubNamespaceNamePrefix}-event-hub-ns-${deploymentParams.enterprise_name_suffix}-${deploymentParams.global_uniqueness}', '_', '-')

resource r_event_hub_ns 'Microsoft.EventHub/namespaces@2022-01-01-preview' = {
  name: event_hub_ns_name
  location: deploymentParams.location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Standard'
    capacity: 1
  }
  properties: {
    isAutoInflateEnabled: true
    maximumThroughputUnits: 4
    kafkaEnabled: false
    zoneRedundant: true
  }
}


var event_hub_name = replace('${eventHubParams.eventHubNamePrefix}-stream-${deploymentParams.global_uniqueness}', '_', '-')

resource r_event_hub 'Microsoft.EventHub/namespaces/eventhubs@2022-01-01-preview' = {
  parent: r_event_hub_ns
  name: event_hub_name
  properties: {
    messageRetentionInDays: 7
    partitionCount: 4
    captureDescription: {
      enabled: true
      encoding: 'Avro'
      skipEmptyArchives: true
      intervalInSeconds: 300
      sizeLimitInBytes: 10485763
      destination: {
        name: 'EventHubArchive.AzureBlockBlob'
        properties: {
          storageAccountResourceId: r_sa.id
          blobContainer: blobContainerName
          archiveNameFormat: '{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}'
        }
      }
    }
  }
}


// OUTPUTS
output module_metadata object = module_metadata

output event_hub_ns_name string = r_event_hub_ns.name
output event_hub_name string = r_event_hub.name
