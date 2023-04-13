import json
import boto3
import base64
import logging

logging.getLogger().setLevel(logging.INFO)


def lambda_handler(event, context):
    s3_client = boto3.client('s3')

    for i in event['Records']:
        r = json.loads(base64.b64decode(i['kinesis']['data']).decode('utf-8'))
        logging.info('Decoded result - %s', r)

        s3_client.put_object(Bucket='tarassitohwbucket',
                             Key=f"kinesis/date={r['date'].replace('-', '')}/{r['id']}.json",
                             Body=json.dumps(r))

