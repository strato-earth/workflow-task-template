# test_integration.py

import unittest
from strato_task import handler


class TestIntegration(unittest.TestCase):
    def test_integration(self):
        event = {"integration": "test"}
        response = handler(event)
        self.assertEqual(response["statusCode"], 200)
        self.assertIn("Hello from", response["body"])


if __name__ == '__main__':
    unittest.main()
