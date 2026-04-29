# Skill: analyze-test-results

## Purpose

Read Robot Framework result artifacts and produce a concise diagnosis of failures, skips, screenshots, and rerun behavior.

---

## When to Use

- After `make test` or `scripts/run_robot_tests.sh` returns non-zero.
- When CI uploads `results/output.xml`, `log.html`, or screenshots.
- When tests pass but contain unexpected skips.
- Before deciding whether a failure belongs to QA Engineer or CI Guardian.

---

## Inputs

| Parameter | Default | Description |
|-----------|---------|-------------|
| `output_xml` | `results/output.xml` | Merged Robot output file |
| `rerun_xml` | `results/rerun/output.xml` | Failed-test rerun output, when present |
| `screenshots` | `results/screenshots/` | Failure screenshot directory |

---

## Execution Steps

```bash
# Quick status counts
grep -n '<stat ' results/output.xml | tail -20

# Failure and skip messages
grep -n 'status="FAIL"\\|status="SKIP"\\|level="FAIL"\\|level="WARN"' results/output.xml

# Rerun evidence, if any
test -f results/rerun/output.xml && grep -n '<stat ' results/rerun/output.xml | tail -20

# Artifacts
find results -maxdepth 3 -type f | sort
```

For a clean Robot summary without changing results:

```bash
rebot --nostatusrc --output NONE --log NONE --report NONE results/output.xml
```

---

## Diagnosis Rules

| Signal | Interpretation |
|--------|----------------|
| Initial failure, rerun pass | likely flaky or timing-sensitive; inspect first-run failure and screenshot |
| Same failure in rerun | deterministic product/test issue |
| Suite setup skip | environment/configuration issue; do not report as passing coverage |
| Screenshot exists | inspect UI state before changing selectors |
| API status mismatch | confirm target service behavior before changing assertions |
| DB keyword ambiguity | qualify the library name in Robot or Python keyword calls |

---

## Output Format

Report:

```text
Summary: <pass/fail/skip counts>
Failure: <suite/test/error>
Evidence: <output.xml line or artifact path>
Likely owner: QA Engineer | CI Guardian
Next action: <smallest fix or rerun>
```

---

## Constraints

- Do not call skipped tests "passing."
- Do not claim a flaky fix unless the same command passes after the change.
- Do not delete artifacts while diagnosing.
