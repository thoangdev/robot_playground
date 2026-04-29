#!/usr/bin/env bash
set -u

RESULTS_DIR="${RESULTS_DIR:-results}"
RERUN_DIR="${RERUN_DIR:-${RESULTS_DIR}/rerun}"
ROBOT_DASHBOARD_DB="${ROBOT_DASHBOARD_DB:-${RESULTS_DIR}/robot_results.db}"
ROBOT_DASHBOARD_HTML="${ROBOT_DASHBOARD_HTML:-${RESULTS_DIR}/dashboard.html}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PABOT_PROCESSES="${PABOT_PROCESSES:-4}"
USE_PABOT="${USE_PABOT:-true}"
USE_XVFB="${USE_XVFB:-false}"
HEADLESS="${HEADLESS:-False}"

resolve_tool() {
    local tool_name="$1"
    if [ -x "${PROJECT_ROOT}/venv/bin/${tool_name}" ]; then
        printf '%s\n' "${PROJECT_ROOT}/venv/bin/${tool_name}"
    else
        printf '%s\n' "${tool_name}"
    fi
}

ROBOT_CMD="${ROBOT_CMD:-$(resolve_tool robot)}"
PABOT_CMD="${PABOT_CMD:-$(resolve_tool pabot)}"
REBOT_CMD="${REBOT_CMD:-$(resolve_tool rebot)}"
ROBOTDASHBOARD_CMD="${ROBOTDASHBOARD_CMD:-$(resolve_tool robotdashboard)}"

rm -rf "${RERUN_DIR}" "${RESULTS_DIR}/screenshots"
mkdir -p "${RESULTS_DIR}" "${RESULTS_DIR}/screenshots"

test_paths=("$@")
if [ "${#test_paths[@]}" -eq 0 ]; then
    test_paths=("tests/")
fi

shared_args=(--xunit xunit.xml --variable "HEADLESS:${HEADLESS}")

if [ -n "${ZAP_PROXY:-}" ]; then
    shared_args+=(--variable "ZAP_PROXY:${ZAP_PROXY}")
fi

if [ -n "${ROBOT_INCLUDE:-}" ]; then
    shared_args+=(--include "${ROBOT_INCLUDE}")
fi

if [ -n "${ROBOT_EXCLUDE:-}" ]; then
    shared_args+=(--exclude "${ROBOT_EXCLUDE}")
fi

if [ -n "${ROBOT_EXTRA_ARGS:-}" ]; then
    # shellcheck disable=SC2206
    extra_args=(${ROBOT_EXTRA_ARGS})
    shared_args+=("${extra_args[@]}")
fi

run_command() {
    if [ "${USE_XVFB}" = "true" ]; then
        xvfb-run -a "$@"
    else
        "$@"
    fi
}

run_initial() {
    if [ "${USE_PABOT}" = "true" ]; then
        echo "Running Robot Framework with pabot (${PABOT_PROCESSES} processes)."
        run_command "${PABOT_CMD}" \
            --processes "${PABOT_PROCESSES}" \
            --outputdir "${RESULTS_DIR}" \
            "${shared_args[@]}" \
            "${test_paths[@]}"
    else
        echo "Running Robot Framework serially with robot."
        run_command "${ROBOT_CMD}" --outputdir "${RESULTS_DIR}" "${shared_args[@]}" "${test_paths[@]}"
    fi
}

run_rerun() {
    mkdir -p "${RERUN_DIR}" "${RERUN_DIR}/screenshots"
    run_command "${ROBOT_CMD}" \
        --rerunfailed "${RESULTS_DIR}/output.xml" \
        --outputdir "${RERUN_DIR}" \
        "${shared_args[@]}" \
        "${test_paths[@]}"
}

merge_results() {
    "${REBOT_CMD}" \
        --merge \
        --outputdir "${RESULTS_DIR}" \
        --xunit xunit.xml \
        "${RESULTS_DIR}/output.xml" \
        "${RERUN_DIR}/output.xml"
}

generate_dashboard() {
    if [ ! -f "${RESULTS_DIR}/output.xml" ]; then
        echo "No ${RESULTS_DIR}/output.xml found; skipping RobotDashboard generation." >&2
        return 0
    fi

    "${ROBOTDASHBOARD_CMD}" \
        -o "${RESULTS_DIR}/output.xml" \
        -d "${ROBOT_DASHBOARD_DB}" \
        -n "${ROBOT_DASHBOARD_HTML}" \
        -t "Robot Framework QA Dashboard" \
        -u true
}

set +e
run_initial
initial_status=$?
set -e

if [ "${initial_status}" -eq 0 ]; then
    generate_dashboard
    exit 0
fi

if [ ! -f "${RESULTS_DIR}/output.xml" ]; then
    echo "Initial Robot run failed before output.xml was created; skipping rerun." >&2
    exit "${initial_status}"
fi

echo "Initial Robot run failed; rerunning failed tests from ${RESULTS_DIR}/output.xml."
set +e
run_rerun
set -e

if [ ! -f "${RERUN_DIR}/output.xml" ]; then
    echo "Rerun did not create ${RERUN_DIR}/output.xml; keeping initial failure." >&2
    exit "${initial_status}"
fi

set +e
merge_results
merge_status=$?
set -e

if [ "${merge_status}" -eq 0 ]; then
    generate_dashboard
else
    set +e
    generate_dashboard
    dashboard_status=$?
    set -e
    if [ "${dashboard_status}" -ne 0 ]; then
        echo "RobotDashboard generation failed after an already-failing test run." >&2
    fi
fi

exit "${merge_status}"
