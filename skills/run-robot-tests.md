# Skill: run-robot-tests

## Purpose

Execute Robot Framework test suites and return a structured summary of pass/fail counts, duration, and any failures. Wraps the project's canonical runner (`scripts/run_robot_tests.sh`) and supports both full-suite and targeted runs.

---

## When to Use

- After writing or modifying test files, to verify they execute correctly.
- To reproduce a CI failure locally.
- To run a specific tag or suite in isolation during development.
- To perform a smoke check before pushing a branch.

---

## Input

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `suite` | string | `tests/` | Path to suite directory or `.robot` file |
| `tags` | string | (none) | RF tag expression: `smoke`, `api AND positive`, `NOT regression` |
| `browser` | string | `chrome` | Browser for GUI tests |
| `headless` | bool | `True` | Run browser without display |
| `db_type` | string | `sqlite` | Database backend |
| `mobile` | bool | `False` | Set `RUN_MOBILE_TESTS=true` to run Appium tests against a real device/emulator |
| `pabot` | bool | `True` | Use parallel execution |
| `processes` | int | `4` | pabot worker count |
| `extra_args` | string | (none) | Raw `robot`/`pabot` flags passed through |

---

## Output

- `results/output.xml` — machine-readable result tree
- `results/log.html` — detailed execution log with screenshots
- `results/report.html` — summary dashboard
- `results/dashboard.html` — RobotDashboard trend and drilldown report
- `results/robot_results.db` — RobotDashboard result history database
- `results/xunit.xml` — xunit-format results for CI ingestion
- `results/screenshots/` — failure screenshots (GUI tests)
- Exit code: `0` = all passed, non-zero = failures or errors

---

## Execution Steps

```bash
# Full run (all suites, parallel)
./scripts/run_robot_tests.sh tests/

# Single suite
robot --outputdir results tests/api/user_api_tests.robot

# Tagged subset
robot --include smoke --outputdir results tests/

# Parallel with custom process count
PABOT_PROCESSES=2 ./scripts/run_robot_tests.sh tests/

# GUI tests headless via Browser Library / Playwright
HEADLESS=True robot --outputdir results tests/gui/

# Specific browser
BROWSER=firefox robot --outputdir results tests/gui/

# Appium mobile suite (requires running Appium server and configured device/app)
RUN_MOBILE_TESTS=true MOBILE_PLATFORM=android make test-mobile

# Rerun only failed tests
robot --rerunfailed results/output.xml --outputdir results/rerun tests/
```

---

## Constraints

- Requires an active Python virtual environment: `source venv/bin/activate` or `make setup`.
- GUI tests use MarketSquare Browser Library. Run `rfbrowser init` after installing requirements.
- Mobile tests use AppiumLibrary and are skipped by default. They require Appium 2, a booted simulator/emulator or real device, and app capabilities.
- Database tests default to SQLite — no external service needed. For PostgreSQL/MySQL, set `DB_*` env vars.
- ZAP proxy tests require a running ZAP instance: `make test-zap` handles this locally.
- `results/` is gitignored. Do not commit test artifacts.

---

## Safety Considerations

- Never run tests against a production environment. The `BASE_URL` and `API_BASE_URL` in `robot.yaml` point to public demo services. Override only for test environments.
- GUI tests open a real browser process (unless headless). Ensure no sensitive information is visible on-screen during recording.
- Database tests that INSERT/DELETE operate only on the configured test database (`results/test.db` for SQLite). Verify `DB_NAME` before pointing at any shared database.
