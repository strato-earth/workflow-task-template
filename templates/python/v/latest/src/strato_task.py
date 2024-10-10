# strato_task.py

import os
import subprocess
import json
import sys
from task import task_handler


def run_script(script_path):
    """Run a shell script if it exists."""
    if os.path.exists(script_path):
        print(f'Running {script_path}...')
        subprocess.run(["bash", script_path], check=True)
    else:
        print(f'{script_path} not found, skipping.')


def handler(event=None, context=None):
    """Main task handler that executes pre and post scripts."""
    if event is None:
        event = {}

    try:
        # Execute pre.sh if it exists
        run_script('/var/task/pre.sh')

        # Execute main task logic
        response = task_handler(event)
        print("Task Response:", response)

        # Execute post.sh if it exists
        run_script('/var/task/post.sh')

        return response
    except Exception as error:
        print('Error occurred:', error)
        # Execute post.sh if it exists
        run_script('/var/task/post.sh')
        raise


def parse_args(args):
    """Parse command-line arguments as JSON."""
    if len(args) > 1:
        try:
            event = json.loads(args[1])
        except json.JSONDecodeError as e:
            print('Failed to parse arguments as JSON:', e)
            event = {}
    else:
        event = {}
    return event


if __name__ == '__main__':
    event = parse_args(sys.argv)
    handler(event)
