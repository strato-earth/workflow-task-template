import unittest
import subprocess


class TestIntegration(unittest.TestCase):

    def test_integration(self):
        # Simulate running the task.py script as part of the integration test
        result = subprocess.run(
            ['python', 'src/task.py'], capture_output=True, text=True
        )
        output = result.stdout

        self.assertEqual(result.returncode, 0)
        self.assertIn(
            "Hello from", output
        )


if __name__ == '__main__':
    unittest.main()
