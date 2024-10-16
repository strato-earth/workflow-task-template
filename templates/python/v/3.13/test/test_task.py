import unittest
import subprocess


class TestTaskMain(unittest.TestCase):
    def test_main(self):
        # Run the task.py script and capture the output
        result = subprocess.run(
            ['python', 'src/task.py'], capture_output=True, text=True
        )
        output = result.stdout

        # Check if the script ran successfully
        self.assertEqual(result.returncode, 0)

        # Verify that the output contains the expected message
        self.assertIn("Hello from", output)


if __name__ == '__main__':
    unittest.main()
