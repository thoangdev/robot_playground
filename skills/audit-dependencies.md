# Skill: audit-dependencies

## Purpose

Check dependency security posture for the pinned Python requirements and document safe upgrade paths for any CVEs.

---

## When to Use

- After editing `requirements.txt`.
- When CI `Dependency Audit` fails.
- Before adding a new Python package.
- During scheduled maintenance or release readiness checks.

---

## Inputs

| Parameter | Default | Description |
|-----------|---------|-------------|
| `requirements_file` | `requirements.txt` | Requirement file to audit |
| `python_version` | active venv | Interpreter used to resolve dependencies |

---

## Execution Steps

```bash
# Install/update dependencies in the active environment
pip install -r requirements.txt

# Audit pinned and resolved dependencies
pip-audit -r requirements.txt
```

Makefile shortcut:

```bash
make audit
```

---

## Output

- Exit code `0`: no known vulnerabilities found.
- Non-zero exit: table with package, installed version, vulnerability id, and fixed versions.

---

## Remediation Workflow

1. Identify the vulnerable direct or transitive package.
2. Prefer upgrading a direct dependency in `requirements.txt`.
3. If the fixed version drops Python support, update the Python support policy and CI matrix together.
4. Run:

```bash
pip install -r requirements.txt
pip-audit -r requirements.txt
make lint
make test-smoke
```

5. Update `README.md` and `CLAUDE.md` if the support policy changed.

---

## Constraints

- Do not pin a vulnerable version to preserve old interpreter support.
- Do not ignore CVEs without a written reason and user approval.
- Keep dependencies pinned; this template favors repeatable CI over floating installs.
