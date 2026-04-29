# Command: audit

## Purpose

Run dependency vulnerability scanning for the pinned Python dependency set.

---

## Steps

```bash
source venv/bin/activate
pip install -r requirements.txt
pip-audit -r requirements.txt
```

Shortcut:

```bash
make audit
```

---

## Success Criteria

`pip-audit` prints:

```text
No known vulnerabilities found
```

---

## On Failure

Update the vulnerable package to a fixed version, then rerun:

```bash
pip install -r requirements.txt
pip-audit -r requirements.txt
make test-smoke
```

If the fix requires a newer Python version, update `README.md`, `CLAUDE.md`, and `.github/workflows/tests.yml` together.
