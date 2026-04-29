# Command: lint

## Purpose

Run static checks for Robot Framework suites and Python resource libraries.

---

## Steps

```bash
source venv/bin/activate
robocop tests/
python -m py_compile tests/resources/*.py
```

Shortcut:

```bash
make lint
```

---

## Success Criteria

- Robocop prints `No issues found.`
- `py_compile` exits `0`.

---

## On Failure

- Fix Robot issues in the reported file and line.
- Fix Python syntax errors before running tests.
- Do not disable a Robocop rule unless the project standard in `CLAUDE.md` is wrong.
