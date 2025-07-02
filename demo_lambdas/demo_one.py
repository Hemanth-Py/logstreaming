def lambda_handler(event, context):
    print("[demo_one] Start handler")
    print("[demo_one] Received event:", event)
    print("Hello from demo_one Lambda!")
    x = 42
    print(f"[demo_one] The answer is {x}")
    return {"statusCode": 200, "body": "Hello from demo_one Lambda!"}
