# task.py

import os


def task_handler(event):
    msg = f"Hello from {os.getenv('RUNTIME_ENV', 'unknown')}!"
    print(msg)

    response = {
        "statusCode": 200,
        "body": msg
    }

    return response
