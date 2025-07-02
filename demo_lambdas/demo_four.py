def lambda_handler(event, context):
    print("Hello from demo_four Lambda!")
    return {"statusCode": 200, "body": "Hello from demo_four Lambda!"}
