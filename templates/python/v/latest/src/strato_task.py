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
        env_file = '/tmp/strato_env.json'
        with open(env_file, 'w') as f: json.dump(event, f)

        run_script('/var/task/pre.sh')

        with open(env_file, 'r') as f:
            env_vars = json.load(f)
            for key, value in env_vars.items():
                os.environ[key] = str(value)

        # Execute main task logic
        response = task_handler()
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
