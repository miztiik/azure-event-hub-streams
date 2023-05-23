import os
from azure.eventhub import EventHubConsumerClient
from azure.eventhub.extensions.checkpointstoreblob import BlobCheckpointStore
from azure.identity import DefaultAzureCredential

import logging

EVENT_HUB_FQDN = os.getenv("EVENT_HUB_FQDN", "warehouse-event-hub-ns-event-hub-streams-002.servicebus.windows.net")
EVENT_HUB_NAME = os.getenv("EVENT_HUB_NAME","store-events-stream-002")

SA_ACCOUNT_URL = os.getenv("SA_ACCOUNT_URL", "https://warehouseodly5v002.blob.core.windows.net/")
CONTAINER_NAME = os.getenv("CONTAINER_NAME","store-events-blob-002")

msg_count = 0
MAX_MESSAGE_COUNT = 10

def on_event(partition_context, event):
    # Put your code here.
    # If the operation is i/o intensive, multi-thread will have better performance.
    global msg_count
    msg_count += 1
    print("Received event from partition: {}.".format(partition_context.partition_id))
    print("Received event: {}".format(event.body_as_str()))
    write_or_amend_file(f"Received event: {event.body_as_str()} msg count: {msg_count}\n")
    if msg_count >= MAX_MESSAGE_COUNT:
        partition_context.update_checkpoint(event)
        print("Updated checkpoint at {}".format(event.offset))
        print("Exiting receive handler...")
        raise KeyboardInterrupt("Received {} messages, that's all we need".format(msg_count))
        # os._exit(1)


def write_or_amend_file(content, filename="example.txt"):
    mode = 'a' if os.path.exists(filename) else 'w'
    with open(filename, mode) as file:
        file.write(content)

# Write content to the file
write_or_amend_file('Hello, World!\n')

def on_partition_initialize(partition_context):
    # Put your code here.
    print("Partition: {} has been initialized.".format(partition_context.partition_id))


def on_partition_close(partition_context, reason):
    # Put your code here.
    print("Partition: {} has been closed, reason for closing: {}.".format(
        partition_context.partition_id,
        reason
    ))


def on_error(partition_context, error):
    # Put your code here. partition_context can be None in the on_error callback.
    if partition_context:
        print("An exception: {} occurred during receiving from Partition: {}.".format(
            partition_context.partition_id,
            error
        ))
    else:
        print("An exception: {} occurred during the load balance process.".format(error))



def receive_batch(time_limit_seconds=60, message_limit=5):
    azure_log_level = logging.getLogger("azure").setLevel(logging.ERROR)
    credential = DefaultAzureCredential(logging_enable=True, logging=azure_log_level)
    checkpoint_store = BlobCheckpointStore(
        blob_account_url=SA_ACCOUNT_URL,
        container_name=CONTAINER_NAME,
        credential=credential,
    )
    client = EventHubConsumerClient(
        fully_qualified_namespace=EVENT_HUB_FQDN,
        eventhub_name=EVENT_HUB_NAME,
        consumer_group="$Default",
        checkpoint_store=checkpoint_store,
        credential=credential,
    )
    try:
        with client:
            client.receive(
                on_event=on_event,
                on_partition_initialize=on_partition_initialize,
                on_partition_close=on_partition_close,
                on_error=on_error,
                starting_position="-1",  # "-1" is from the beginning of the partition.
            )
    except KeyboardInterrupt:
        print('Stopped receiving.')

receive_batch()
