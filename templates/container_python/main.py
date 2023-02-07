## Put your python code here

def handler(event, context):
    message = "Hello World!"
    print(message)
    return {
        'message': message
    }