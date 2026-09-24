import json
import os
import urllib.request


def _format_event(detail):
    service = detail.get("service", "unknown")
    event_type = detail.get("eventTypeCode", detail.get("eventTypeCategory", "unknown"))
    region = detail.get("affectedRegion", detail.get("region", "ap-northeast-2"))
    status = detail.get("statusCode", "unknown")
    start_time = detail.get("startTime", "unknown")
    description = ""

    descriptions = detail.get("eventDescription") or []
    if descriptions:
        description = descriptions[0].get("latestDescription", "")

    return (
        ":rotating_light: AWS Health event detected\n"
        f"*Service*: {service}\n"
        f"*Region*: {region}\n"
        f"*Event*: {event_type}\n"
        f"*Status*: {status}\n"
        f"*Start*: {start_time}\n"
        f"*Description*: {description}"
    )


def handler(event, context):
    webhook_url = os.environ["SLACK_WEBHOOK_URL"]
    detail = event.get("detail", {})
    payload = {"text": _format_event(detail)}

    request = urllib.request.Request(
        webhook_url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    with urllib.request.urlopen(request, timeout=10) as response:
        response.read()

    return {"statusCode": 200}