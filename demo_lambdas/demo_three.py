def lambda_handler(event, context):
    print("Hello from demo_three Lambda!")
    return {"statusCode": 200, "body": "Hello from demo_three Lambda!"}
