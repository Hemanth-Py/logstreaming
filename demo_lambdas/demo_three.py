def lambda_handler(event, context):
    print("[demo_three] Lambda started")
    print("Hello from demo_three Lambda!")
    for i in range(2):
        print(f"[demo_three] Loop {i}")
    print("[demo_three] Lambda ending")
    return {"statusCode": 200, "body": "Hello from demo_three Lambda!"}
