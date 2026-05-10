import json
import boto3
import urllib.parse

s3_client = boto3.client('s3')

def lambda_handler(event, context):
    """
    Fires automatically when a file is uploaded to the configured S3 bucket.
    The event contains details of what was uploaded.
    """
    
    print(f"S3 event received: {json.dumps(event)}")
    
    processed = []
    
    # S3 events can contain multiple records — bulk uploads send them together
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        
        # S3 keys are URL-encoded — spaces become +, special chars become %XX
        # unquote_plus decodes them back to readable names
        key = urllib.parse.unquote_plus(record['s3']['object']['key'])
        size = record['s3']['object']['size']
        
        print(f"Processing file: s3://{bucket}/{key} ({size} bytes)")
        
        # head_object reads metadata without downloading the file content
        response = s3_client.head_object(Bucket=bucket, Key=key)
        content_type = response.get('ContentType', 'unknown')
        
        processed.append({
            "bucket": bucket,
            "key": key,
            "size_bytes": size,
            "content_type": content_type,
            "status": "processed"
        })
        
        print(f"File details: {content_type}, {size} bytes")
    
    return {
        "statusCode": 200,
        "body": json.dumps({
            "processed_files": processed,
            "count": len(processed)
        })
    }
