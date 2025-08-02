# Makefile for Robot Framework project automation

# Variables
ROBOT_OPTIONS = --outputdir results
TEST_DIRS = tests/
REQUIREMENTS = requirements.txt
VENV_DIR = venv

# Default target
.PHONY: help
help:
	@echo "Available commands:"
	@echo "  install     - Install dependencies"
	@echo "  setup       - Setup virtual environment and install dependencies"
	@echo "  init-browser - Initialize Browser library"
	@echo "  test        - Run all tests"
	@echo "  test-api    - Run API tests only"
	@echo "  test-gui    - Run GUI tests only"
	@echo "  test-db     - Run database tests only"
	@echo "  test-security - Run security tests only"
	@echo "  test-smoke  - Run smoke tests only"
	@echo "  test-parallel - Run tests in parallel"
	@echo "  clean       - Clean test results and cache"
	@echo "  lint        - Run code quality checks"
	@echo "  format      - Format Robot Framework code"
	@echo "  report      - Generate test report"
	@echo "  serve       - Serve test results on local server"

# Setup virtual environment
.PHONY: setup
setup:
	python3 -m venv $(VENV_DIR)
	$(VENV_DIR)/bin/pip install --upgrade pip
	$(VENV_DIR)/bin/pip install -r $(REQUIREMENTS)
	$(VENV_DIR)/bin/rfbrowser init

# Install dependencies
.PHONY: install
install:
	pip install -r $(REQUIREMENTS)
	rfbrowser init

# Initialize Browser library
.PHONY: init-browser
init-browser:
	rfbrowser init

# Run all tests
.PHONY: test
test:
	robot $(ROBOT_OPTIONS) $(TEST_DIRS)

# Run API tests only
.PHONY: test-api
test-api:
	robot $(ROBOT_OPTIONS) --include api $(TEST_DIRS)

# Run GUI tests only
.PHONY: test-gui
test-gui:
	robot $(ROBOT_OPTIONS) --include gui $(TEST_DIRS)

# Run database tests only
.PHONY: test-db
test-db:
	robot $(ROBOT_OPTIONS) --include database $(TEST_DIRS)

# Run security tests only
.PHONY: test-security
test-security:
	robot $(ROBOT_OPTIONS) --include security $(TEST_DIRS)

# Run smoke tests only
.PHONY: test-smoke
test-smoke:
	robot $(ROBOT_OPTIONS) --include smoke $(TEST_DIRS)

# Run tests in parallel
.PHONY: test-parallel
test-parallel:
	pabot --processes 4 $(ROBOT_OPTIONS) $(TEST_DIRS)

# Clean results and cache
.PHONY: clean
clean:
	rm -rf results/
	rm -rf logs/
	rm -rf __pycache__/
	find . -name "*.pyc" -delete
	find . -name "*.pyo" -delete
	find . -name "__pycache__" -type d -exec rm -rf {} +

# Run code quality checks
.PHONY: lint
lint:
	robocop $(TEST_DIRS)
	python -m py_compile tests/resources/*.py

# Format Robot Framework code
.PHONY: format
format:
	robotidy $(TEST_DIRS)

# Generate comprehensive test report
.PHONY: report
report:
	robotmetrics --inputpath results/ --output results/

# Serve test results on local server
.PHONY: serve
serve:
	python -m http.server 8000 --directory results/

# Run tests with custom tags
.PHONY: test-tag
test-tag:
	@read -p "Enter tag to run: " tag; \
	robot $(ROBOT_OPTIONS) --include $$tag $(TEST_DIRS)

# Environment setup for CI/CD
.PHONY: ci-setup
ci-setup:
	pip install -r $(REQUIREMENTS)
	rfbrowser init
	mkdir -p results

# Run tests for CI/CD with proper exit codes
.PHONY: ci-test
ci-test:
	robot $(ROBOT_OPTIONS) --exitonfailure $(TEST_DIRS)

# Database specific commands
.PHONY: setup-db-postgres
setup-db-postgres:
	@echo "Setting up PostgreSQL test database..."
	@echo "Make sure PostgreSQL is running and create a test database"
	@echo "Example: createdb test_db"

.PHONY: setup-db-mysql
setup-db-mysql:
	@echo "Setting up MySQL test database..."
	@echo "Make sure MySQL is running and create a test database"
	@echo "Example: mysql -e 'CREATE DATABASE test_db;'"

.PHONY: setup-db-mongodb
setup-db-mongodb:
	@echo "Setting up MongoDB test database..."
	@echo "Make sure MongoDB is running"
	@echo "Database will be created automatically on first use"

# Security testing with ZAP
.PHONY: start-zap
start-zap:
	@echo "Starting OWASP ZAP proxy..."
	@echo "Make sure you have ZAP installed and configured"
	@echo "Example: zap.sh -daemon -host 0.0.0.0 -port 8080"

.PHONY: test-security-with-zap
test-security-with-zap:
	@echo "Running security tests with ZAP proxy..."
	robot $(ROBOT_OPTIONS) --variable ZAP_PROXY:http://localhost:8080 --include security $(TEST_DIRS)
