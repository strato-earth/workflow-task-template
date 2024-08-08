# test_task.py

import unittest
from task import task_handler


class TestTaskHandler(unittest.TestCase):
    def test_handler(self):
        event = {"test": "value"}
        response = task_handler(event)
        self.assertEqual(response["statusCode"], 200)
        self.assertIn("Hello from", response["body"])


if __name__ == '__main__':
    unittest.main()
