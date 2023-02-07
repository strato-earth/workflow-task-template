from src.handler import lambda_handler

def handler(event, context):
    lambda_handler(event, context)

if __name__ == '__main__':
    handler(None, None)        