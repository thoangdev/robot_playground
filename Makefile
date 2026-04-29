# Makefile for Robot Framework QA Template
TEST_DIRS        = tests/
VENV_DIR         = venv
ROBOT_RUNNER     = ./scripts/run_robot_tests.sh
PABOT_PROCESSES ?= 4

.PHONY: help setup install test test-api test-gui test-db test-mobile test-smoke test-parallel test-rerun test-tag test-zap lint format audit check serve dashboard clean
help:
	@echo "Setup"
	@echo "  setup          Create venv and install all dependencies"
	@echo "  install        Install dependencies into the active environment"
	@echo ""
	@echo "Running tests"
	@echo "  test           Run all suites"
	@echo "  test-api       API tests only"
	@echo "  test-gui       GUI tests only"
	@echo "  test-db        Database tests only"
	@echo "  test-mobile    Mobile/Appium tests only (skips unless RUN_MOBILE_TESTS=true)"
	@echo "  test-smoke     Smoke tests (fast feedback)"
	@echo "  test-parallel  Parallel run via pabot"
	@echo "  test-rerun     Serial run with automatic rerunfailed merge"
	@echo "  test-tag       Prompt for a custom tag and run matching tests"
	@echo "  test-zap       Run API+GUI through a local ZAP proxy (passive scan)"
	@echo ""
	@echo "Quality"
	@echo "  lint           Robocop static analysis"
	@echo "  format         Robotidy auto-format"
	@echo "  audit          pip-audit dependency vulnerability check"
	@echo "  check          lint + format + audit"
	@echo ""
	@echo "Results"
	@echo "  dashboard      Regenerate RobotDashboard from results/output.xml"
	@echo "  serve          Serve results/ on http://localhost:8000"
	@echo "  clean          Remove results/ and Python caches"

# ── Setup ─────────────────────────────────────────────────────────────────────

setup:
	python3 -m venv $(VENV_DIR)
	$(VENV_DIR)/bin/pip install --upgrade pip
	$(VENV_DIR)/bin/pip install -r requirements.txt
	$(VENV_DIR)/bin/rfbrowser init

install:
	pip install -r requirements.txt
	rfbrowser init

# ── Tests ─────────────────────────────────────────────────────────────────────

test:
	USE_PABOT=true PABOT_PROCESSES=$(PABOT_PROCESSES) $(ROBOT_RUNNER) $(TEST_DIRS)

test-api:
	USE_PABOT=true ROBOT_INCLUDE=api PABOT_PROCESSES=$(PABOT_PROCESSES) $(ROBOT_RUNNER) $(TEST_DIRS)

test-gui:
	USE_PABOT=true ROBOT_INCLUDE=gui PABOT_PROCESSES=$(PABOT_PROCESSES) $(ROBOT_RUNNER) $(TEST_DIRS)

test-db:
	USE_PABOT=true ROBOT_INCLUDE=database PABOT_PROCESSES=$(PABOT_PROCESSES) $(ROBOT_RUNNER) $(TEST_DIRS)

test-mobile:
	USE_PABOT=true ROBOT_INCLUDE=mobile PABOT_PROCESSES=$(PABOT_PROCESSES) $(ROBOT_RUNNER) $(TEST_DIRS)

test-smoke:
	USE_PABOT=true ROBOT_INCLUDE=smoke PABOT_PROCESSES=$(PABOT_PROCESSES) $(ROBOT_RUNNER) $(TEST_DIRS)

test-parallel:
	USE_PABOT=true PABOT_PROCESSES=$(PABOT_PROCESSES) $(ROBOT_RUNNER) $(TEST_DIRS)

test-rerun:
	USE_PABOT=false $(ROBOT_RUNNER) $(TEST_DIRS)

test-tag:
	@read -p "Tag to run: " tag; \
	USE_PABOT=true ROBOT_INCLUDE=$$tag PABOT_PROCESSES=$(PABOT_PROCESSES) $(ROBOT_RUNNER) $(TEST_DIRS)

# Run API and GUI tests through a local ZAP daemon for passive security scanning.
# Start ZAP first:  docker run -d -p 8080:8080 ghcr.io/zaproxy/zaproxy:stable zap-x.sh -daemon -host 0.0.0.0 -port 8080
test-zap:
	USE_PABOT=true ZAP_PROXY=http://localhost:8080 PABOT_PROCESSES=$(PABOT_PROCESSES) $(ROBOT_RUNNER) tests/api/ tests/gui/

# ── Quality ───────────────────────────────────────────────────────────────────

lint:
	robocop tests/
	python -m py_compile tests/resources/*.py

format:
	robotidy tests/

audit:
	pip-audit -r requirements.txt

check: lint format audit

# ── Results ───────────────────────────────────────────────────────────────────

serve:
	python -m http.server 8000 --directory results/

dashboard:
	robotdashboard -o results/output.xml -d results/robot_results.db -n results/dashboard.html -t "Robot Framework QA Dashboard" -u true

clean:
	rm -rf results/ __pycache__/
	find . -name "*.pyc" -delete
	find . -type d -name "__pycache__" -exec rm -rf {} +
