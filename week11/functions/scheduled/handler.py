import json
import boto3
import os
from datetime import datetime, timezone

def lambda_handler(event, context):
    """
    Triggered by EventBridge on a schedule.
    Checks all ECS clusters in the account and logs a health report.
    """
    
    print(f"Scheduled check running at: {datetime.now(timezone.utc).isoformat()}")
    print(f"Event source: {event.get('source', 'unknown')}")
    
    # AWS_REGION is set automatically by Lambda runtime — no need to pass it in
    region = os.environ.get('AWS_REGION', 'eu-central-1')
    ecs_client = boto3.client('ecs', region_name=region)
    
    report = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "checks": []
    }
    
    # List all ECS clusters in the account
    clusters_response = ecs_client.list_clusters()
    cluster_arns = clusters_response.get('clusterArns', [])
    
    if not cluster_arns:
        print("No ECS clusters found")
        report["checks"].append({"type": "ecs", "status": "no_clusters"})
    else:
        clusters = ecs_client.describe_clusters(clusters=cluster_arns)
        
        for cluster in clusters['clusters']:
            name = cluster['clusterName']
            running = cluster['runningTasksCount']
            pending = cluster['pendingTasksCount']
            
            status = "healthy" if running > 0 else "no_running_tasks"
            
            print(f"Cluster {name}: {running} running, {pending} pending — {status}")
            
            report["checks"].append({
                "type": "ecs_cluster",
                "name": name,
                "running_tasks": running,
                "pending_tasks": pending,
                "status": status
            })
    
    print(f"Report complete: {json.dumps(report)}")
    
    return {
        "statusCode": 200,
        "body": json.dumps(report)
    }

