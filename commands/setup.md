# Command: setup

## Purpose

Bootstrap a local development environment for `robot_playground`.

---

## Steps

```bash
python3 -m venv venv
venv/bin/pip install --upgrade pip
venv/bin/pip install -r requirements.txt
cp -n .env.example .env
```

Optional pre-commit setup:

```bash
venv/bin/pip install pre-commit
venv/bin/pre-commit install
```

---

## Verification

```bash
venv/bin/robot --version
venv/bin/pabot --version
venv/bin/robocop --version
venv/bin/robotidy --version
venv/bin/pip-audit --version
```

Expected result: every command prints a version and exits `0`.

---

## Notes

- Python 3.10+ is required.
- Chrome is required for GUI tests; CI installs it with `browser-actions/setup-chrome`.
- `.env` is local-only and must not be committed.
