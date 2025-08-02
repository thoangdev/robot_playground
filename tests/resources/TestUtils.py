"""
Common Python keywords and utilities for Robot Framework tests
"""

import os
import json
import time
from datetime import datetime
from robot.api.deco import keyword
from robot.libraries.BuiltIn import BuiltIn


class TestUtils:
    """Custom Python library for Robot Framework with utility keywords"""
    
    ROBOT_LIBRARY_SCOPE = 'GLOBAL'
    
    def __init__(self):
        self.builtin = BuiltIn()
    
    @keyword
    def get_current_timestamp(self):
        """Get current timestamp in ISO format"""
        return datetime.now().isoformat()
    
    @keyword
    def wait_for_condition(self, condition_keyword, timeout=30, interval=1):
        """
        Wait for a condition to be true
        
        Args:
            condition_keyword: Robot Framework keyword that returns True/False
            timeout: Maximum time to wait in seconds
            interval: Time between checks in seconds
        """
        start_time = time.time()
        while time.time() - start_time < timeout:
            try:
                result = self.builtin.run_keyword(condition_keyword)
                if result:
                    return True
            except Exception:
                pass
            time.sleep(interval)
        
        raise AssertionError(f"Condition '{condition_keyword}' was not met within {timeout} seconds")
    
    @keyword
    def generate_test_data(self, data_type="email"):
        """
        Generate test data based on type
        
        Args:
            data_type: Type of data to generate (email, name, phone, etc.)
        """
        timestamp = int(time.time())
        
        data_generators = {
            'email': f'test_{timestamp}@example.com',
            'name': f'Test User {timestamp}',
            'phone': f'+1555{timestamp % 10000:04d}',
            'username': f'user_{timestamp}',
            'password': f'Pass_{timestamp}!'
        }
        
        return data_generators.get(data_type, f'test_data_{timestamp}')
    
    @keyword
    def load_json_test_data(self, file_path):
        """
        Load test data from JSON file
        
        Args:
            file_path: Path to JSON file relative to tests/data/
        """
        full_path = os.path.join('tests', 'data', file_path)
        
        if not os.path.exists(full_path):
            raise FileNotFoundError(f"Test data file not found: {full_path}")
        
        with open(full_path, 'r') as file:
            return json.load(file)
    
    @keyword
    def save_test_results(self, data, filename):
        """
        Save test results to file
        
        Args:
            data: Data to save
            filename: Name of file to save to
        """
        results_dir = 'results'
        os.makedirs(results_dir, exist_ok=True)
        
        file_path = os.path.join(results_dir, filename)
        
        if isinstance(data, (dict, list)):
            with open(file_path, 'w') as file:
                json.dump(data, file, indent=2)
        else:
            with open(file_path, 'w') as file:
                file.write(str(data))
        
        return file_path
    
    @keyword
    def compare_json_objects(self, actual, expected, ignore_keys=None):
        """
        Compare two JSON objects, optionally ignoring certain keys
        
        Args:
            actual: Actual JSON object
            expected: Expected JSON object
            ignore_keys: List of keys to ignore in comparison
        """
        if ignore_keys is None:
            ignore_keys = []
        
        def remove_ignored_keys(obj):
            if isinstance(obj, dict):
                return {k: remove_ignored_keys(v) for k, v in obj.items() if k not in ignore_keys}
            elif isinstance(obj, list):
                return [remove_ignored_keys(item) for item in obj]
            return obj
        
        cleaned_actual = remove_ignored_keys(actual)
        cleaned_expected = remove_ignored_keys(expected)
        
        if cleaned_actual != cleaned_expected:
            raise AssertionError(
                f"JSON objects do not match:\n"
                f"Actual: {json.dumps(cleaned_actual, indent=2)}\n"
                f"Expected: {json.dumps(cleaned_expected, indent=2)}"
            )
        
        return True
