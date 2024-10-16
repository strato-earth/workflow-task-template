import os
import sys


def main():
    runtime_env = os.getenv('RUNTIME_ENV', 'unknown')
    msg = f"Hello from {runtime_env}!"
    print(msg)

    if len(sys.argv) > 1:
        print('Received the following arguments:')
        for index, arg in enumerate(sys.argv[1:], start=1):
            print(f"Argument {index}: {arg}")
    else:
        print('No arguments were passed.')

    return 0


if __name__ == '__main__':
    main()
