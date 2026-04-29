# Robot Framework QA Template

[![Tests](https://github.com/your-org/robot_playground/actions/workflows/tests.yml/badge.svg)](https://github.com/your-org/robot_playground/actions/workflows/tests.yml)
[![Python 3.10+](https://img.shields.io/badge/python-3.10%2B-blue.svg)](https://www.python.org/)
[![Robot Framework 7](https://img.shields.io/badge/Robot%20Framework-7.x-red.svg)](https://robotframework.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A lean, production-ready Robot Framework template for QA teams. Clone it, run the examples immediately against real public services, then swap in your own URLs and credentials.

Covers **API**, **Web UI (Browser Library / Playwright)**, **Database (SQLite → Postgres/MySQL/MongoDB)**, and opt-in **Mobile (AppiumLibrary)** testing. OWASP ZAP security scanning is handled by the CI/CD pipeline as a passive proxy — no dedicated security test files to maintain.

---

## Getting Started

### Prerequisites

| Tool | Version |
| --- | --- |
| Python | 3.10+ (3.12 recommended) |
| Chrome | latest |
| Make | any (optional) |
| Appium 2 + device/emulator | only for `RUN_MOBILE_TESTS=true` |

### Install

```bash
git clone https://github.com/your-org/robot_playground.git
cd robot_playground

python3 -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate

make install                    # installs dependencies and Browser Library's Playwright runtime
# If using pip directly: pip install -r requirements.txt && rfbrowser init
cp .env.example .env            # edit if targeting your own application

# (optional) activate pre-commit hooks
pip install pre-commit && pre-commit install
```

### Run the examples immediately

```bash
make test          # all suites — API, GUI, DB all pass against public demo sites
make test-smoke    # fast subset
make serve         # open results at http://localhost:8000
```

The bundled examples work out of the box with no configuration:

| Suite | Target | Auth |
| --- | --- | --- |
| `tests/api/` | [jsonplaceholder.typicode.com](https://jsonplaceholder.typicode.com) | none |
| `tests/gui/` | [the-internet.herokuapp.com](https://the-internet.herokuapp.com) | tomsmith / SuperSecretPassword! |
| `tests/db/` | SQLite (`results/test.db`) | none |
| `tests/mobile/` | Appium Android/iOS target | skipped unless `RUN_MOBILE_TESTS=true` |

---

## Project Structure

```
robot_playground/
├── .github/workflows/tests.yml   # CI: lint → audit → test matrix → ZAP passive scan
├── tests/
│   ├── api/
│   │   └── user_api_tests.robot  # REST API examples (CRUD + edge cases)
│   ├── gui/
│   │   └── login_tests.robot     # Scenario-level Browser Library login / logout examples
│   ├── pages/
│   │   └── login_page.robot      # Page Object resource: login locators and page actions
│   ├── db/
│   │   └── database_tests.robot  # SQLite by default; swap DB_TYPE for real DBs
│   ├── mobile/
│   │   └── appium_smoke_tests.robot # Appium starter suite, opt-in by env
│   ├── resources/
│   │   ├── common.robot          # Shared keywords: browser, API session, DB
│   │   ├── mobile.robot          # Shared AppiumLibrary keywords and capabilities
│   │   ├── TestUtils.py          # Timestamps, JSON comparison, data generation
│   │   └── DatabaseUtils.py      # SQLite / Postgres / MySQL / MongoDB abstraction
│   └── data/
│       └── test_data.json        # Static test data
├── .env.example                  # Environment variable reference
├── .pre-commit-config.yaml       # Robocop, Robotidy, pip-audit on commit
├── .robocop                      # Robocop linting config
├── .robotidy                     # Robotidy formatter config
├── Makefile                      # Developer convenience commands
├── requirements.txt              # Pinned dependencies
└── robot.yaml                    # Default variable overrides
```

---

## How to Use

### Running tests

```bash
make test-api          # API tests
make test-gui          # GUI tests (Chrome, headless optional)
make test-db           # Database tests
make test-mobile       # Appium tests (skips unless RUN_MOBILE_TESTS=true)
make test-smoke        # smoke-tagged tests only
make test-parallel     # parallel with pabot
make test-rerun        # serial run with automatic rerunfailed merge
make test-tag          # prompts for any tag

# Override variables inline
robot --outputdir results --variable BROWSER:firefox tests/gui/
robot --outputdir results --variable HEADLESS:True tests/
```

### Adding new tests

**API suite** — copy the pattern from `tests/api/user_api_tests.robot`:

```robot
*** Settings ***
Resource    ../resources/common.robot
Suite Setup      Create API Session
Suite Teardown   Delete All Sessions

*** Test Cases ***
My Endpoint Returns 200
    [Tags]    api    smoke
    ${r}=    GET On Session    api    /my-endpoint
    Verify API Response    ${r}    200
```

**GUI suite** — use Page Object resources under `tests/pages/`.
Keep locators and Browser Library mechanics in page resources, then keep suites scenario-focused:

```robot
*** Settings ***
Resource     ../resources/common.robot
Resource     ../pages/login_page.robot
Test Setup   Open Login Page
Test Teardown    Take Screenshot On Failure

*** Test Cases ***
Valid User Login
    [Tags]    gui    smoke    login    positive
    Login With Credentials    ${VALID_USERNAME}    ${VALID_PASSWORD}
    Current Page Should Be Secure Area
```

**Database suite** — `DB_TYPE=sqlite` by default. Change to `postgresql` / `mysql` / `mongodb` via `.env` or `--variable DB_TYPE:postgresql`.

**Mobile suite** — `tests/mobile/appium_smoke_tests.robot` imports `tests/resources/mobile.robot`.
It is intentionally skipped unless `RUN_MOBILE_TESTS=true`, so new teams can keep CI
fast while still having a ready Appium pattern.

Android example:

```bash
appium --base-path /

RUN_MOBILE_TESTS=true \
MOBILE_PLATFORM=android \
MOBILE_APPIUM_SERVER=http://127.0.0.1:4723 \
ANDROID_DEVICE_NAME="Android Emulator" \
ANDROID_APP=/absolute/path/to/app-debug.apk \
MOBILE_STARTUP_LOCATOR=accessibility_id=Home \
make test-mobile
```

iOS example:

```bash
appium --base-path /

RUN_MOBILE_TESTS=true \
MOBILE_PLATFORM=ios \
MOBILE_APPIUM_SERVER=http://127.0.0.1:4723 \
IOS_DEVICE_NAME="iPhone 15" \
IOS_APP=/absolute/path/to/MyApp.app \
MOBILE_STARTUP_LOCATOR=accessibility_id=Home \
make test-mobile
```

### Environment configuration

Copy `.env.example` → `.env`. Key variables:

| Variable | Default | Purpose |
| --- | --- | --- |
| `BASE_URL` | `https://the-internet.herokuapp.com` | GUI test target |
| `API_BASE_URL` | `https://jsonplaceholder.typicode.com` | API test target |
| `BROWSER` | `chrome` | `chrome`, `firefox`, `edge` |
| `HEADLESS` | `false` | `true` for CI / Docker |
| `RUN_MOBILE_TESTS` | `false` | Set `true` only when an Appium server and device are ready |
| `MOBILE_PLATFORM` | `android` | `android` or `ios` |
| `MOBILE_APPIUM_SERVER` | `http://127.0.0.1:4723` | Appium server URL |
| `MOBILE_STARTUP_LOCATOR` | *(empty)* | Optional locator that proves the app launched |
| `DB_TYPE` | `sqlite` | `sqlite`, `postgresql`, `mysql`, `mongodb` |
| `ZAP_PROXY` | *(empty)* | Set to `http://localhost:8080` for local ZAP scan |

---

## Best Practices

### Test design

1. **One behaviour per test.** Split "login and verify profile" into two tests.
2. **Independent tests.** Never rely on a prior test having run. Use `Suite Setup` to build required state.
3. **Use IF/ELSE and BREAK** — not the legacy `Run Keyword If` and `Exit For Loop If`:

   ```robot
   # Good — RF 5+ syntax
   IF    '${ENV}' == 'staging'
       Skip    Not running on staging
   END

   FOR    ${i}    IN RANGE    10
       ${r}=    GET On Session    api    /status    expected_status=any
       IF    '${r.status_code}' == '200'    BREAK
   END
   ```

4. **Use TRY/EXCEPT** only for genuinely expected exceptions, not flow control.

### Keyword design

- **Single responsibility** — one keyword does one thing.
- **Descriptive names** — read like a sentence: `Verify User Cannot Access Admin Panel`.
- **Arguments over hardcoding** — pass selectors, URLs, timeouts as arguments with defaults.
- **Short keywords** — if a keyword exceeds ~10 steps, decompose it (Robocop enforces this).
- **Page Object Model for UI** — store page locators and page-level actions in `tests/pages/`, not in
  `tests/gui/` suites. Suites should express user behavior and assertions, not selector mechanics.

### Tags

Use a consistent layered strategy:

| Layer | Examples |
| --- | --- |
| Type | `api` `gui` `database` `mobile` |
| Priority | `smoke` `regression` |
| Operation | `get` `post` `crud` `login` |
| Polarity | `positive` `negative` |

```bash
robot --include smoke tests/          # fast CI gate
robot --include regression tests/     # full run
robot --include mobile tests/         # Appium suite; skips unless RUN_MOBILE_TESTS=true
robot --exclude wip tests/            # skip in-progress tests
```

---

## Security Testing (ZAP)

Security scanning is handled entirely in CI — no dedicated test files to write or maintain.

**How it works:**

1. ZAP starts as a daemon in the `security-zap` CI job.
2. The regular API and GUI test suites run through ZAP as a **passive proxy**.
3. ZAP observes all HTTP traffic and generates a finding report.
4. The job fails if any HIGH-risk finding is detected.

This means every new API or GUI test you write automatically increases the ZAP scan surface.

**Run locally:**

```bash
# Start ZAP
docker run -d -p 8080:8080 ghcr.io/zaproxy/zaproxy:stable \
  zap-x.sh -daemon -host 0.0.0.0 -port 8080

# Run tests through ZAP
make test-zap

# View the report
open results/zap-report.html   # generated by the ZAP daemon API
```

---

## How to Maintain

### Update dependencies

```bash
pip list --outdated             # see what's behind
pip-audit -r requirements.txt  # check for known CVEs
pre-commit autoupdate           # bump pre-commit hook revisions
```

### Code quality

```bash
make lint      # robocop static analysis
make format    # robotidy auto-format
make audit     # pip-audit vulnerability check
make check     # all three
```

### Debugging

```bash
robot --loglevel DEBUG --outputdir results tests/

# Run through the shared runner: pabot first, rerun failed tests, merge output
./scripts/run_robot_tests.sh tests/

# Re-run only the tests that failed last time by hand, if needed
robot --rerunfailed results/output.xml --outputdir results/rerun tests/
rebot --merge --outputdir results results/output.xml results/rerun/output.xml
```

Failure screenshots are written under `results/screenshots/` and
`results/rerun/screenshots/`, then uploaded by CI with the Robot reports.
The shared runner also imports `results/output.xml` into RobotDashboard and
writes `results/dashboard.html` plus `results/robot_results.db`.

---

## CI/CD Pipeline

| Job | Trigger | What it does |
| --- | --- | --- |
| `lint` | All pushes / PRs | Robocop + Robotidy check |
| `audit` | All pushes / PRs | `pip-audit` dependency scan |
| `test` | After `lint` | Full suite on Python 3.10–3.12 via `pabot` (`USE_PABOT=true`, `PABOT_PROCESSES=4`), then `rerunfailed` merge and RobotDashboard generation |
| `security-zap` | `main` + nightly | Passive ZAP scan through API + GUI suites via the same pabot runner |

---

## Resources

- [Robot Framework User Guide](https://robotframework.org/robotframework/latest/RobotFrameworkUserGuide.html)
- [Browser Library](https://github.com/MarketSquare/robotframework-browser)
- [RequestsLibrary](https://github.com/MarketSquare/robotframework-requests)
- [DatabaseLibrary](https://github.com/MarketSquare/Robotframework-Database-Library)
- [RobotDashboard](https://marketsquare.github.io/robotframework-dashboard/)
- [AppiumLibrary](https://github.com/serhatbolsu/robotframework-appiumlibrary)
- [Robocop](https://robocop.readthedocs.io/) · [Robotidy](https://robotidy.readthedocs.io/)
- [How to Write Good Test Cases](https://github.com/robotframework/HowToWriteGoodTestCases)
- [CHANGELOG](CHANGELOG.md) · [CONTRIBUTING](CONTRIBUTING.md)
