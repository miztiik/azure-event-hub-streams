# Event Streaming with Azure Event Hub

The stores operated by Mystique enterprise generate a lot of events related to sales and inventory from multiple locations. In order to efficiently handle this high volume of data and facilitate further processing, Mystique enterprise requires a solution that allows them to ingest the data and store it in a central location.

A sample of their event is shown below Can you help them?

```json
{
  "id": "743da362-69df-4e63-a95f-a1d93e29825e",
  "request_id": "743da362-69df-4e63-a95f-a1d93e29825e",
  "store_id": 5,
  "store_fqdn": "localhost",
  "store_ip": "127.0.0.1",
  "cust_id": 549,
  "category": "Notebooks",
  "sku": 169008,
  "price": 45.85,
  "qty": 34,
  "discount": 10.3,
  "gift_wrap": true,
  "variant": "red",
  "priority_shipping": false,
  "ts": "2023-05-19T14:36:09.985501",
  "contact_me": "github.com/miztiik",
  "is_return": true
}
```

Event properties,

```json
{
   "event_type":"sale_event",
   "priority_shipping":false,
}
```

 Can you provide guidance on how to accomplish this?

## 🎯 Solution

To meet their needs, Mystique enterprise has chosen [Azure Event Hub][1] as the platform of choice. It provides the necessary capabilities to handle the ingestion and storage of the data. We can utilize the [capture streaming events capability][2] of Azure Event Hub to persist the message to Azure Blob Storage. This allows us to store the data in a central location for further processing.

In this demonstration, an Azure Function with a managed identity will generate events and send them to event hub within a designated event hub namespace. The hub is configred with `4` partitions, with `2` partitions allocated for each event type. The event hub is also configured to capture streaming events and store them in Azure Blob Storage. The Azure Function will be configured to utilize the managed identity to interact with the event hub and send events to the hub. The events will be stored in the blob storage based on the partition they are sent to.

By leveraging the capabilities of Bicep, all the required resources can be easily provisioned and managed with minimal effort. Bicep simplifies the process of defining and deploying Azure resources, allowing for efficient resource management.

![Miztiik Automation - Event Streaming with Azure Event Hub](images/miztiik_architecture_event_streaming%20with_azure_event_hub_to_blob_001.png)

1. ## 🧰 Prerequisites

   This demo, along with its instructions, scripts, and Bicep template, has been specifically designed to be executed in the `northeurope` region. However, with minimal modifications, you can also try running it in other regions of your choice (the specific steps for doing so are not covered in this context)

   - 🛠 Azure CLI Installed & Configured - [Get help here](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
   - 🛠 Azure Function Core Tools - [Get help here](https://learn.microsoft.com/en-us/azure/azure-functions/functions-run-local?tabs=v4%2Cwindows%2Ccsharp%2Cportal%2Cbash#install-the-azure-functions-core-tools)
   - 🛠 Bicep Installed & Configured - [Get help here](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install)
     - 🛠 [Optional] VS Code & Bicep Extenstions - [Get help here](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#vs-code-and-bicep-extension)
   - `jq` - [Get help here](https://stedolan.github.io/jq/download/)
   - `bash` or git bash - [Get help here](https://git-scm.com/downloads)

1. ## ⚙️ Setting up the environment

   - Get the application code

     ```bash
     git clone https://github.com/miztiik/azure-event-hub-streams.git
     cd azure-event-hub-streams
     ```

1. ## 🚀 Prepare the local environment

   Ensure you have jq, Azure Cli and bicep working

    ```bash
   jq --version
   func --version
   bicep --version
   bash --version
   az account show
    ```

1. ## 🚀 Deploying the Solution

   - **Stack: Main Bicep**
     We will create the following resources
     - **Storage Accounts** for storing the events
       - General purpose Storage Account - Used by Azure functions to store the function code
       - `warehouse*` -  Azure Function will store the events here
     - **Event Hub Namespace**
       - Event Hub Stream, with `4` Partitions
         - Even Partitions - `0` & `2` - `inventory_Event`
         - Odd Partitions - `1` & `3` - `sale_event`
         - Event Hub Capture - Enabled
           - Events will be stored in `warehouse*` storage account.
     - **Managed Identity**
        - This will be used by the Azure Function to interact with the service bus
     - **Python Azure Function**
        - **Producer**: `HTTP` Trigger. Customized to send `count` number of events to the service bus, using parameters passed in the query string. `count` defaults to `10`
     - _Note: There are few additional resources created, but you can ignore them for now, they aren't required for this demo, but be sure to clean them up later_

      Initiate the deployment with the following command,

      ```bash
      # make deploy
      sh deployment_scripts/deploy.sh
      ```

      After successfully deploying the stack, Check the `Resource Groups/Deployments` section for the resources.

1. ## 🔬 Testing the solution

   - **Trigger the function**

      ```bash
      FUNC_URL="https://event-hub-streams-store-backend-fn-app-003.azurewebsites.net/api/store-events-producer-fn"
      curl ${FUNC_URL}?count=10
      ```

      You should see an output like this,

      ```json
      {
      "miztiik_event_processed": true,
      "msg": "Generated 10 messages",
      "resp": {
         "status": true,
         "tot_msgs": 10,
         "bad_msgs": 1,
         "sale_evnts": 4,
         "inventory_evnts": 6,
         "tot_sales": 507.03000000000003
      },
      "count": 10,
      "last_processed_on": "2023-05-23T08:33:36.642732"
      }
      ```

      During the execution of this function, a total of 10 messages were produced, with 4 of them being classified as `sale_events` and 6 of them as `inventory_events`. Please note that the numbers may vary for your specific scenario if you run the producer function multiple times.

      Additionally, when observing the storage of events in Blob Storage, you will notice that inventory_events are stored in blob prefixes either labeled as `0` or `2`, while `sale_events` are stored in blob prefixes labeled as either `1` or `3`. This configuration is a result of setting up the event hub to utilize 4 partitions, with 2 partitions allocated for each event type.

      ![Miztiik Automation - Event Streaming with Azure Event Hub](images/miztiik_architecture_event_streaming%20with_azure_event_hub_to_blob_002.png)
      ![Miztiik Automation - Event Streaming with Azure Event Hub](images/miztiik_architecture_event_streaming%20with_azure_event_hub_to_blob_005.png)
      ![Miztiik Automation - Event Streaming with Azure Event Hub](images/miztiik_architecture_event_streaming%20with_azure_event_hub_to_blob_003.png)
      ![Miztiik Automation - Event Streaming with Azure Event Hub](images/miztiik_architecture_event_streaming%20with_azure_event_hub_to_blob_004.png)

1. ## 📒 Conclusion

   In this demonstration, we showcase a streamlined process for event streaming using Azure Event Hub. By leveraging this approach, event producers can efficiently capture and store events in Blob Storage. This allows for optimized event processing and enables targeted handling based on specific criteria, facilitating seamless downstream processing.
  
1. ## 🧹 CleanUp

   If you want to destroy all the resources created by the stack, Execute the below command to delete the stack, or _you can delete the stack from console as well_

   - Resources created during [Deploying The Solution](#-deploying-the-solution)
   - _Any other custom resources, you have created for this demo_

   ```bash
   # Delete from resource group
   az group delete --name Miztiik_Enterprises_xxx --yes
   # Follow any on-screen prompt
   ```

   This is not an exhaustive list, please carry out other necessary steps as maybe applicable to your needs.

## 📌 Who is using this

This repository aims to show how to Bicep to new developers, Solution Architects & Ops Engineers in Azure.


### 💡 Help/Suggestions or 🐛 Bugs

Thank you for your interest in contributing to our project. Whether it is a bug report, new feature, correction, or additional documentation or solutions, we greatly value feedback and contributions from our community. [Start here](/issues)

### 👋 Buy me a coffee

[![ko-fi](https://www.ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/Q5Q41QDGK) Buy me a [coffee ☕][900].

### 📚 References

1. [Azure Docs - Event Hub][1]
1. [Azure Docs - Event Hub - Streaming Event Capture][2]
1. [Azure Docs - Event Hub Python Samples][3]
1. [Azure Docs - Managed Identity][8]
1. [Azure Docs - Managed Identity Caching][9]
1. [Gitub Issue - Default Credential Troubleshooting][10]
1. [Gitub Issue - Default Credential Troubleshooting][11]

[1]: https://learn.microsoft.com/en-us/azure/event-hubs
[2]: https://learn.microsoft.com/en-us/azure/event-hubs/event-hubs-capture-overview
[3]: https://github.com/Azure/azure-sdk-for-python/blob/main/sdk/eventhub/azure-eventhub/samples
[8]: https://learn.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/overview
[9]: https://learn.microsoft.com/en-us/azure/app-service/overview-managed-identity?tabs=portal%2Chttp#configure-target-resource
[10]: https://github.com/microsoft/azure-container-apps/issues/442
[11]: https://github.com/microsoft/azure-container-apps/issues/325#issuecomment-1265380377

### 🏷️ Metadata

![miztiik-success-green](https://img.shields.io/badge/Miztiik:Automation:Level-200-blue)

**Level**: 200

[100]: https://www.udemy.com/course/aws-cloud-security/?referralCode=B7F1B6C78B45ADAF77A9
[101]: https://www.udemy.com/course/aws-cloud-security-proactive-way/?referralCode=71DC542AD4481309A441
[102]: https://www.udemy.com/course/aws-cloud-development-kit-from-beginner-to-professional/?referralCode=E15D7FB64E417C547579
[103]: https://www.udemy.com/course/aws-cloudformation-basics?referralCode=93AD3B1530BC871093D6
[899]: https://www.udemy.com/user/n-kumar/
[900]: https://ko-fi.com/miztiik
[901]: https://ko-fi.com/Q5Q41QDGK