import json
import os
import sys
from pathlib import Path
from typing import Dict

sys.path.insert(0, os.getcwd())

WORK_DIR = Path(__file__).parent
TMP_DIR = Path("/tmp")


def load_json_resource(filename: str) -> Dict:
    file_path = os.path.join(WORK_DIR, "data", filename)
    with open(file_path, "r", encoding="utf-8") as reader:
        json_resource = json.load(reader)
    assert json_resource is not None

    return json_resource
