#!/usr/bin/env python3
"""Build/test the local iOS app, selecting an installed iPhone simulator."""
import json
import os
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parent.parent
if len(sys.argv) < 2 or sys.argv[1] not in {"build", "test"}:
    raise SystemExit("Usage: python3 scripts/check-ios.py build|test [test files...]")
action = sys.argv[1]
device_id = os.environ.get("FOCUSMATE_SIMULATOR_ID")
if not device_id:
    inventory = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "devices", "available", "-j"]))
    candidates = []
    for runtime, devices in inventory["devices"].items():
        if ".iOS-" not in runtime:
            continue
        version = tuple(int(part) for part in runtime.split(".iOS-")[1].split("-"))
        if version[0] < 17:
            continue
        for device in devices:
            if device.get("isAvailable") and device["name"].startswith("iPhone"):
                candidates.append((version, "Pro" in device["name"] and "Max" not in device["name"], device["name"], device["udid"]))
    if not candidates:
        raise SystemExit("No available iPhone simulator with iOS 17 or later. Install a runtime in Xcode.")
    device_id = max(candidates)[3]
command = ["xcodebuild", "-project", "ios/FocusMate.xcodeproj", "-scheme", "FocusMate",
           "-destination", f"platform=iOS Simulator,id={device_id}",
           "-derivedDataPath", os.environ.get("FOCUSMATE_DERIVED_DATA", str(root / ".build/ios")),
           "-parallel-testing-enabled", "NO", action, "CODE_SIGNING_ALLOWED=NO"]
if action == "test":
    command.extend(["-collect-test-diagnostics", "never"])
    for file in sys.argv[2:]:
        path = Path(file)
        if path.parent.name not in {"FocusMateTests", "FocusMateUITests"} or path.suffix != ".swift":
            raise SystemExit(f"Unsupported test file: {file}")
        command.append(f"-only-testing:{path.parent.name}/{path.stem}")
elif len(sys.argv) != 2:
    raise SystemExit("Build does not accept test-file arguments.")
print(f"iOS {action}: simulator {device_id}", flush=True)
raise SystemExit(subprocess.call(command, cwd=root))
