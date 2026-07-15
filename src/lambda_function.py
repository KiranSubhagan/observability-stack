import json
import boto3

events = boto3.client("events")

REGION = "us-east-1"


def lambda_handler(event, context):

    detail = event.get("detail", {})
    tags = detail.get("tags", [])

    monitor_name = detail.get("meta", {}).get("monitor", {}).get("name")

    aws_account = None
    command = None
    host = None
    recovery = None

    # Extract values from tags
    for tag in tags:
        if tag.startswith("aws_account:"):
            aws_account = tag.split(":", 1)[1]
        elif tag.startswith("command:"):
            command = tag.split(":", 1)[1]
        elif tag.startswith("host:"):
            host = tag.split(":", 1)[1]
        elif tag.startswith("recovery:"):
            recovery = tag.split(":", 1)[1]

    # Validate required fields
    if aws_account is None:
        raise Exception("Required tag 'aws_account' is missing.")

    if command is None:
        raise Exception("Required tag 'command' is missing.")

    if host is None:
        raise Exception("Required tag 'host' is missing.")

    event_bus_arn = (
        f"arn:aws:events:{REGION}:{aws_account}:event-bus/default"
    )

    # Payload to forward
    payload = {
        "monitor_name": monitor_name,
        "aws_account": aws_account,
        "command": command,
        "host": host,
        "recovery": recovery,
        "tags": tags
    }

    response = events.put_events(
        Entries=[
            {
                "Source": "custom.datadog.recovery",
                "DetailType": event["detail-type"],
                "Detail": json.dumps(payload),
                "EventBusName": event_bus_arn,
            }
        ]
    )

    print("Forwarded Event:")
    print(json.dumps(payload, indent=2))

    print("PutEvents Response:")
    print(json.dumps(response, indent=2))

    # Check if EventBridge accepted the event
    if response.get("FailedEntryCount", 0) > 0:
        raise Exception(
            f"Failed to put event: {json.dumps(response['Entries'], indent=2)}"
        )

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Event forwarded successfully.",
            "response": response
        })
    }
