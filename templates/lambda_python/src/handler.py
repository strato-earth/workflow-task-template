from datetime import datetime
import pytz

def lambda_handler(event, context):
    current_time = datetime.now(pytz.timezone("America/Los_Angeles"))
    print(current_time)
    return {"statusCode": 200, "body": str(current_time)}
