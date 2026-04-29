# CLAUDE.md — robot_playground

## Project Summary

`robot_playground` is a production-ready Robot Framework QA template for testing APIs, Web UIs, and databases. It runs out-of-the-box against public demo services ([jsonplaceholder.typicode.com](https://jsonplaceholder.typicode.com), [the-internet.herokuapp.com](https://the-internet.herokuapp.com)) and is designed to be cloned and adapted to real applications.

**Test tiers:** API · GUI (Browser Library / Playwright) · Database (SQLite / PostgreSQL / MySQL / MongoDB) · Mobile (AppiumLibrary, opt-in)
**Quality gates:** Robocop lint → Robotidy format → pip-audit → test matrix (Python 3.10–3.12) → OWASP ZAP scan
**Execution:** pabot parallel → rerun failures → merge reports → generate RobotDashboard → publish xunit results

---

## Core Architecture

```
tests/
├── api/          Robot Framework test suites for REST API validation
├── gui/          Browser Library / Playwright interaction tests
├── db/           Database CRUD and connectivity tests
├── mobile/       AppiumLibrary starter tests, skipped unless RUN_MOBILE_TESTS=true
├── resources/
│   ├── common.robot        13 shared RF keywords (browser, API, DB setup/teardown)
│   ├── TestUtils.py        Timestamp, data generation, JSON comparison utilities
│   └── DatabaseUtils.py   Multi-DB abstraction (SQLite, PostgreSQL, MySQL, MongoDB)
└── data/
    └── test_data.json      Static fixtures (credentials, endpoints, sample records)

scripts/
└── run_robot_tests.sh     Canonical test runner: pabot → rerun → merge

results/                   Generated artifacts (gitignored)
├── output.xml, log.html, report.html, dashboard.html
├── xunit.xml
├── screenshots/
└── pabot_results/
```

All shared behavior lives in `tests/resources/`. Tests import only from there — no logic in test files.

---

## Coding Standards

### Robot Framework files (`.robot`)

- **RF 7+ syntax only:** Use `IF/ELSE`, `TRY/EXCEPT`, `FOR ... BREAK/CONTINUE`, `VAR`. No legacy `Run Keyword If`.
- **One behavior per test.** Each test case validates a single observable outcome.
- **Independent tests.** No test may depend on another test's side effects. Use `Suite Setup`/`Suite Teardown` for shared fixtures.
- **No logic in test cases.** All implementation goes in keywords (in `resources/`).
- **Browser Library for GUI.** Use `Browser` keywords (`New Page`, `Fill Text`, `Click`, `Get Url`) through `common.robot`; do not add SeleniumLibrary.
- **AppiumLibrary for mobile.** Keep mobile keywords in `tests/resources/mobile.robot`; suites must skip cleanly unless `RUN_MOBILE_TESTS=true`.
- **120-character line limit.** Enforced by Robocop and Robotidy.
- **Max 15 keyword calls per keyword.** Enforced by Robocop (`too-many-calls-in-keyword`).
- **Descriptive keyword names.** Keywords must read as English sentences: `Verify API Response Returns Status 200`.

### Tagging

Every test must have at least one tag from each dimension:

| Dimension | Values |
|-----------|--------|
| Layer | `api` `gui` `database` |
| Priority | `smoke` `regression` |
| Operation | `get` `post` `put` `patch` `delete` `login` `crud` |
| Polarity | `positive` `negative` |

### Python resource files (`.py`)

- Standard Python 3.10+ style with type hints.
- Each function is a Robot Framework keyword (use `@keyword` decorator where disambiguation is needed).
- No business logic — utilities only. Test assertions belong in `.robot` files.
- Keep functions under 30 lines. Extract helpers for complexity.

### Data files

- All static fixtures in `tests/data/test_data.json`. Dynamic data via `TestUtils.generate_test_data()`.
- Never hardcode credentials, URLs, or DB connection strings in test files. Use variables from `robot.yaml` or `.env`.

---

## Agent Behavior Rules

- **Always run `make check` before proposing any test file change.** Never commit code that fails lint.
- **Read `robot.yaml` first** when a task involves configuration, variables, or paths — it is the single source of variable defaults.
- **Read `tests/resources/common.robot`** before writing any new keyword — existing keywords must not be duplicated.
- **Consult `tests/data/test_data.json`** before generating test data fixtures.
- **Prefer editing existing keywords over adding new ones.** Only add a keyword when no existing one can be extended.
- **Never modify `scripts/run_robot_tests.sh` without understanding all env-var branches** (`USE_PABOT`, `USE_XVFB`, `ROBOT_INCLUDE`, etc.).
- **Security tests run automatically** via OWASP ZAP in CI. Do not duplicate ZAP logic in `.robot` files.
- **When uncertain about a DB operation**, check `tests/resources/DatabaseUtils.py` — it abstracts SQLite, PostgreSQL, MySQL, and MongoDB uniformly.

---

## Tool and Skill Usage Guidelines

| Task | Use |
|------|-----|
| Run all tests | `make test` or skill `run-robot-tests` |
| Run a single suite | `robot --outputdir results tests/api/` |
| Run mobile suite | `make test-mobile` with `RUN_MOBILE_TESTS=true` and Appium capabilities |
| Lint RF code | `make lint` or skill `lint-and-format` |
| Auto-format RF code | `make format` |
| Audit dependencies | `make audit` or skill `audit-dependencies` |
| All quality gates | `make check` or command `check` |
| Parse test results | skill `analyze-test-results` |
| Regenerate dashboard | `make dashboard` |
| Set up environment | command `setup` |
| Serve HTML reports | `make serve` |

Skills in `/skills/` are reusable, atomic operations. Commands in `/commands/` are multi-step workflows that compose skills.

---

## File Structure Overview

```
robot_playground/
├── CLAUDE.md                      ← This file
├── agents/
│   ├── qa-engineer.md             ← Test authoring and review agent
│   └── ci-guardian.md             ← CI/CD pipeline health agent
├── skills/
│   ├── run-robot-tests.md         ← Execute RF test suites
│   ├── lint-and-format.md         ← Robocop + Robotidy
│   ├── audit-dependencies.md      ← pip-audit CVE scanning
│   └── analyze-test-results.md    ← Parse output.xml / log.html
├── commands/
│   ├── setup.md                   ← Environment bootstrap
│   ├── test.md                    ← Full test run workflow
│   ├── lint.md                    ← Lint-only workflow
│   ├── audit.md                   ← Dependency audit workflow
│   └── check.md                   ← All quality gates in sequence
├── tests/
│   ├── api/user_api_tests.robot
│   ├── gui/login_tests.robot
│   ├── db/database_tests.robot
│   ├── resources/
│   │   ├── common.robot
│   │   ├── TestUtils.py
│   │   └── DatabaseUtils.py
│   └── data/test_data.json
├── scripts/run_robot_tests.sh
├── Makefile
├── robot.yaml
├── requirements.txt
└── .env.example
```
