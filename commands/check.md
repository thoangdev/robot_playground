# Command: check

## Purpose

Run the full local quality gate before handing off changes.

---

## Steps

```bash
source venv/bin/activate
robotidy --check tests/
robocop tests/
python -m py_compile tests/resources/*.py
pip-audit -r requirements.txt
USE_PABOT=true PABOT_PROCESSES=4 HEADLESS=True ./scripts/run_robot_tests.sh tests/
```

Makefile shortcut:

```bash
make check
make test
```

`make check` covers lint, format, and audit. `make test` is intentionally separate so failures are easier to diagnose.

---

## Success Criteria

- Robotidy: `0 files reformatted`
- Robocop: `No issues found.`
- pip-audit: `No known vulnerabilities found`
- Robot runner: `17 tests, 17 passed, 0 failed, 0 skipped`

---

## On Failure

1. Stop at the first failed gate.
2. Fix the root cause.
3. Rerun the failed gate.
4. Rerun this full command before finalizing.
