#!/usr/bin/env python3
"""Reject successful build commands that did not run a passing test suite."""

import json
from pathlib import Path
import sys
import xml.etree.ElementTree as ET


def verify_ios(path):
    summary = json.loads(path.read_text())
    if (
        summary["result"] != "Passed"
        or summary["passedTests"] == 0
        or summary["passedTests"] != summary["totalTestCount"]
        or summary["failedTests"] != 0
        or summary["skippedTests"] != 0
        or summary["expectedFailures"] != 0
    ):
        sys.exit(f"iOS tests did not all pass: {summary}")
    print(f"iOS: {summary['passedTests']} tests passed")


def verify_android(path):
    reports = sorted(path.glob("*/build/test-results/testDebugUnitTest/TEST-*.xml"))
    app_reports = [report for report in reports if report.relative_to(path).parts[0] == "app"]
    if not app_reports:
        sys.exit("Missing Android app JUnit results")
    total = 0
    app_total = 0
    for report in reports:
        suite = ET.parse(report).getroot()
        total += int(suite.attrib["tests"])
        if report in app_reports:
            app_total += int(suite.attrib["tests"])
        for key in ("failures", "errors", "skipped"):
            if int(suite.attrib.get(key, 0)):
                sys.exit(f"Android {key} in {report}")
    if app_total == 0:
        sys.exit("No Android app tests ran")
    print(f"Android: {total} tests passed")


if __name__ == "__main__":
    platform, result_path = sys.argv[1:]
    {"ios": verify_ios, "android": verify_android}[platform](Path(result_path))
