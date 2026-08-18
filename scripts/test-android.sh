#!/bin/bash
set -euo pipefail

APP_ID="com.opsecurestorageexample"
LOGCAT_FILE=""
LOGCAT_PID=""

cleanup() {
  if [[ -n "${LOGCAT_PID}" ]]; then
    kill "${LOGCAT_PID}" 2>/dev/null || true
  fi
}

wait_for_test_result() {
  local timeout_seconds=180
  local waited=0

  while true; do
    if grep -q "OPS2_TEST_RESULT:PASS" "${LOGCAT_FILE}"; then
      echo "🟢 Test suite passed (from logcat marker)"
      return 0
    fi

    if grep -q "OPS2_TEST_RESULT:FAIL" "${LOGCAT_FILE}"; then
      echo "🟥 Test suite failed (from logcat marker)"
      return 1
    fi

    if (( waited >= timeout_seconds )); then
      echo "⚠️ No test result after ${timeout_seconds}s."
      return 1
    fi

    sleep 5
    waited=$((waited + 5))
  done
}

print_diagnostics() {
  echo "=== Android diagnostics ==="
  adb shell pidof "${APP_ID}" || true
  adb shell dumpsys activity activities | grep -A 30 "${APP_ID}" || true
  echo ""
  echo "=== ReactNativeJS test logs ==="
  grep -E "ReactNativeJS: (App has started|TESTS STARTED|TESTS FINISHED|TEST FAILED|OPS2_TEST_RESULT)" "${LOGCAT_FILE}" | tail -200 || true
  echo ""
  echo "=== logcat errors ==="
  adb logcat -d "*:E" || true
  if [[ -n "${LOGCAT_FILE}" && -f "${LOGCAT_FILE}" ]]; then
    echo ""
    echo "=== Tail of captured logcat (${LOGCAT_FILE}) ==="
    tail -400 "${LOGCAT_FILE}" || true
  fi
}

on_error() {
  local exit_code=$?
  echo "❌ Android test script failed with exit code ${exit_code}"
  print_diagnostics
  exit "${exit_code}"
}

trap cleanup EXIT
trap on_error ERR

cd example || exit

adb wait-for-device
echo "Waiting for boot to complete..."
adb shell 'while [[ -z $(getprop sys.boot_completed) ]]; do sleep 1; done'
echo "Boot completed!"
adb shell input keyevent 82

LOGCAT_FILE="${PWD}/android-logcat.txt"
adb logcat -c || true
adb logcat -v threadtime > "${LOGCAT_FILE}" &
LOGCAT_PID=$!

yarn run:android:release

sleep 10

wait_for_test_result
