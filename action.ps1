#!/bin/env pwsh
[CmdletBinding()]
param (
    [String]$Path
)

if (-Not $Path) {
    $Path = Get-Location
}

$test_results_file = Get-ChildItem -Path $Path -Filter TestResults.xml -Recurse | ForEach-Object { $_.FullName } | Select-Object -First 1
if (-Not $test_results_file) {
    Write-Warning "No TestResults.xml file found in $Path"
    exit 0
}

[xml]$test_results = Get-Content $test_results_file -Raw

$markdown = @()
if ($test_results.testsuites.failures -gt 0) {
    $markdown += "# Failed tests"
    $markdown += "$($test_results.testsuites.failures) / $($test_results.testsuites.tests) tests failed."

    $markdown += "| Test Name | Message | Detail |"
    $markdown += "|------|---------|--------|"

    $test_results.testsuites.testsuite.testcase  | Where-Object { $_.error } | ForEach-Object {
        $message = $_.error.message.replace('|', '\|')
        $detail = $_.error.InnerText.replace('|', '\|').trim().replace("`n", "</br>")
        $markdown += "| $($_.name) | $message | $detail |"
    }

    $markdown | Add-Content $env:GITHUB_STEP_SUMMARY

    Write-Host "::error title=Unit Test Failures::$($test_results.testsuites.failures) / $($test_results.testsuites.tests) tests failed."
    exit 1
}


