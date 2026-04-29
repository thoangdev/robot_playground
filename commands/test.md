# Command: test

## Purpose

Run Robot Framework suites through the canonical project runner with parallel execution, failed-test reruns, merged reports, xUnit output, and screenshot capture.

---

## Steps

```bash
source venv/bin/activate
USE_PABOT=true PABOT_PROCESSES=4 HEADLESS=True ./scripts/run_robot_tests.sh tests/
```

Shortcuts:

```bash
make test
make test-smoke
make test-api
make test-gui
make test-db
```

---

## Artifacts

- `results/output.xml`
- `results/log.html`
- `results/report.html`
- `results/xunit.xml`
- `results/screenshots/`
- `results/rerun/output.xml`, when the initial run failed

---

## Success Criteria

The final merged output reports:

```text
0 failed
0 skipped
```

If tests fail, use `skills/analyze-test-results.md`.
