def lambda_handler(event, context):
    print("[demo_two] Handler invoked")
    print("[demo_two] Event:", event)
    y = 'test'
    print(f"[demo_two] y is {y}")
    print("Hello from demo_two Lambda!")
    print("[demo_two] End handler")
    return {"statusCode": 200, "body": "Hello from demo_two Lambda!"}
