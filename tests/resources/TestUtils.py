"""Common Python keywords and utilities for Robot Framework tests."""

import json
import time
from datetime import datetime
from pathlib import Path
from typing import Any, Optional

from robot.api.deco import keyword
from robot.libraries.BuiltIn import BuiltIn


class TestUtils:
    """Custom Python library for Robot Framework with utility keywords."""

    ROBOT_LIBRARY_SCOPE = "GLOBAL"

    def __init__(self) -> None:
        self.builtin = BuiltIn()

    @keyword
    def get_current_timestamp(self) -> str:
        """Return current UTC timestamp in ISO-8601 format."""
        return datetime.utcnow().isoformat()

    @keyword
    def wait_for_condition(
        self,
        condition_keyword: str,
        timeout: int = 30,
        interval: int = 1,
    ) -> bool:
        """Poll *condition_keyword* until it returns truthy or *timeout* seconds elapses.

        Raises ``AssertionError`` when the timeout is reached without success.
        """
        deadline = time.time() + float(timeout)
        while time.time() < deadline:
            try:
                if self.builtin.run_keyword(condition_keyword):
                    return True
            except Exception:  # noqa: BLE001
                pass
            time.sleep(float(interval))
        raise AssertionError(
            f"Condition '{condition_keyword}' was not met within {timeout} seconds"
        )

    @keyword
    def generate_test_data(self, data_type: str = "email") -> str:
        """Generate a unique test value of *data_type* (email, name, phone, username, password)."""
        ts = int(time.time())
        generators: dict[str, str] = {
            "email": f"test_{ts}@example.com",
            "name": f"Test User {ts}",
            "phone": f"+1555{ts % 10_000:04d}",
            "username": f"user_{ts}",
            "password": f"Pass_{ts}!",
        }
        return generators.get(data_type, f"test_data_{ts}")

    @keyword
    def load_json_test_data(self, file_path: str) -> Any:
        """Load and return parsed JSON from *file_path* (relative to ``tests/data/``)."""
        full_path = Path("tests") / "data" / file_path
        if not full_path.exists():
            raise FileNotFoundError(f"Test data file not found: {full_path}")
        with full_path.open(encoding="utf-8") as fh:
            return json.load(fh)

    @keyword
    def save_test_results(self, data: Any, filename: str) -> str:
        """Persist *data* to ``results/<filename>`` and return the absolute path."""
        file_path = Path("results") / filename
        file_path.parent.mkdir(parents=True, exist_ok=True)
        with file_path.open("w", encoding="utf-8") as fh:
            if isinstance(data, (dict, list)):
                json.dump(data, fh, indent=2)
            else:
                fh.write(str(data))
        return str(file_path)

    @keyword
    def compare_json_objects(
        self,
        actual: Any,
        expected: Any,
        ignore_keys: Optional[list[str]] = None,
    ) -> bool:
        """Assert that *actual* and *expected* are equal, optionally skipping *ignore_keys*.

        Raises ``AssertionError`` with a diff on mismatch.
        """
        ignore_keys = ignore_keys or []

        def _strip(obj: Any) -> Any:
            if isinstance(obj, dict):
                return {k: _strip(v) for k, v in obj.items() if k not in ignore_keys}
            if isinstance(obj, list):
                return [_strip(i) for i in obj]
            return obj

        cleaned_actual = _strip(actual)
        cleaned_expected = _strip(expected)
        if cleaned_actual != cleaned_expected:
            raise AssertionError(
                "JSON objects do not match:\n"
                f"Actual:   {json.dumps(cleaned_actual, indent=2)}\n"
                f"Expected: {json.dumps(cleaned_expected, indent=2)}"
            )
        return True
