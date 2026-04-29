# Documentation

This folder contains documentation, usage guides, and best practices for the Robot Framework QA template project.

## Contents
- Getting Started
- Folder Structure
- Test Writing Guidelines
- Custom Libraries
- Mobile Appium Guide: [mobile-appium.md](mobile-appium.md)
- CI/CD Integration
- Security Practices
- Runner Behavior: `scripts/run_robot_tests.sh` is the single entrypoint for
  parallel execution, failed-test reruns, report merging, and screenshot layout.
- MarketSquare Libraries: GUI tests use `robotframework-browser`, API tests use
  `robotframework-requests`, DB tests use `robotframework-databaselibrary`, and
  every canonical runner invocation generates `robotframework-dashboard` output.
- Mobile Testing: `tests/mobile/` provides an AppiumLibrary starter suite. It is
  skipped until `RUN_MOBILE_TESTS=true` and Appium/device capability variables
  are configured, which keeps normal CI fast and infrastructure-free.
- Parallel CI: `.github/workflows/tests.yml` runs the canonical runner with
  `USE_PABOT=true` and `PABOT_PROCESSES=4`; use the same runner locally for
  parity with CI.

Add more documentation files as needed for your team.
