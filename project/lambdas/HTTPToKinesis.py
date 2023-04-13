import logging
import os
import uuid

import boto3

logging.getLogger().setLevel(logging.INFO)


def lambda_handler(event, context):
    logging.info(event['body'])

    client = boto3.client('kinesis')

    response = client.put_record(
        StreamName=os.environ.get('DATA_STREAM_NAME'),
        Data=event['body'],
        PartitionKey=str(uuid.uuid4()))

    return response
