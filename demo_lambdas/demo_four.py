def lambda_handler(event, context):
    print("[demo_four] Handler started")
    print("Hello from demo_four Lambda!")
    z = 3.14
    print(f"[demo_four] Value of z: {z}")
    print("[demo_four] Handler finished")
    return {"statusCode": 200, "body": "Hello from demo_four Lambda!"}
