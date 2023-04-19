import base64
import json
import logging
import os
import psycopg2
from dateutil.parser import parse

logging.getLogger().setLevel(logging.INFO)

db_host = os.environ['DB_HOST']
db_port = os.environ['DB_PORT']
db_name = os.environ['DB_NAME']
db_user = os.environ['DB_USER']
db_password = os.environ['DB_PASSWORD']


def lambda_handler(event, context):
    conn = psycopg2.connect(
        host=db_host,
        port=db_port,
        dbname=db_name,
        user=db_user,
        password=db_password
    )

    cur = conn.cursor()
    cur.execute("""CREATE TABLE IF NOT EXISTS events(id int, text varchar(100), date date)""")

    for record in event['Records']:
        r = json.loads(base64.b64decode(record['kinesis']['data']).decode('utf-8'))
        logging.info('Decoded result - %s', r)
        cur.execute("INSERT INTO events (id, text, date) VALUES (%s, %s, DATE %s)",
                    (r['id'], r['text'], parse(r['date'])))
    conn.commit()
    cur.close()
    conn.close()

    return {
        'statusCode': 200,
        'body': 'Data successfully stored in RDS PostgreSQL'
    }