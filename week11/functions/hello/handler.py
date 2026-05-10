import json
import os
import requests  # available via the Layer — not bundled in hello.zip

def lambda_handler(event, context):
    
    print(f"Received event: {json.dumps(event)}")
    
    name = "World"
    if event.get("queryStringParameters"):
        name = event["queryStringParameters"].get("name", "World")
    
    # Make an outbound HTTP call from inside Lambda
    # This shows Lambda has internet access and reveals its outbound IP
    try:
        response = requests.get("https://api.ipify.org?format=json", timeout=5)
        lambda_ip = response.json().get("ip", "unknown")
    except Exception as e:
        lambda_ip = f"error: {str(e)}"
    
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({
            "message": f"Hello, {name}!",
            "function": context.function_name,
            "environment": os.environ.get("ENVIRONMENT", "unknown"),
            "lambda_outbound_ip": lambda_ip
        })
    }
