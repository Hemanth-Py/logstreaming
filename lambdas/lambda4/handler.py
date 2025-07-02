def handler(event, context):
    print("Hello from Lambda 4")
    return {"statusCode": 200, "body": "Hello from Lambda 4"}
