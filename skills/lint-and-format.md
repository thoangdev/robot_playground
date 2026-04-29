# Skill: lint-and-format

## Purpose

Run Robot Framework static analysis, Robotidy formatting, and Python syntax checks for the shared resource libraries. Use this before finalizing any change to `.robot`, `.py`, or quality configuration files.

---

## When to Use

- After editing files under `tests/`.
- After changing `.robocop`, `.robotidy`, `.pre-commit-config.yaml`, or `requirements.txt`.
- Before opening a PR or handing work back to the user.
- When CI reports a lint or format failure.

---

## Inputs

| Parameter | Default | Description |
|-----------|---------|-------------|
| `path` | `tests/` | Robot file or directory to lint/format |
| `check_only` | `false` | Use Robotidy check mode instead of writing changes |
| `python_resources` | `tests/resources/*.py` | Python utility files to compile-check |

---

## Execution Steps

```bash
# Auto-format Robot files
robotidy tests/

# Check format without changing files
robotidy --check tests/

# Static analysis
robocop tests/

# Python syntax check for Robot libraries
python -m py_compile tests/resources/*.py
```

Makefile shortcuts:

```bash
make format
make lint
```

---

## Output

- Robotidy prints changed files or confirms no files would change.
- Robocop prints rule violations with file, line, severity, and rule id.
- `py_compile` exits non-zero on Python syntax errors.

---

## Failure Handling

| Failure | Response |
|---------|----------|
| Robotidy would reformat files | Run `robotidy tests/`, inspect diff, then rerun `robotidy --check tests/` |
| Robocop rule failure | Fix the file first; only adjust `.robocop` when the rule conflicts with project standards |
| Python syntax error | Fix the exact file/line from `py_compile` before running Robot tests |
| Tool missing | Run `make setup` or `pip install -r requirements.txt` |

---

## Constraints

- Do not silence Robocop rules just to make CI green.
- Do not commit generated `results/` artifacts.
- Do not run global formatters outside this repo.
- Keep Robot syntax compatible with RF 7+.
