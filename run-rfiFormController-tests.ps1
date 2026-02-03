# Script to run rfiFormController tests and display coverage
Write-Host "Running rfiFormController_TEST with code coverage..." -ForegroundColor Cyan

# Run the tests
$result = sf apex run test --class-names rfiFormController_TEST --target-org dev --code-coverage --result-format json --wait 10 2>&1 | ConvertFrom-Json

if ($result.status -eq 0) {
    Write-Host "`nTest Results:" -ForegroundColor Green
    Write-Host "=============" -ForegroundColor Green

    # Display test summary
    $summary = $result.result.summary
    Write-Host "Tests Run: $($summary.testsRan)" -ForegroundColor Yellow
    Write-Host "Passed: $($summary.passing)" -ForegroundColor Green
    Write-Host "Failed: $($summary.failing)" -ForegroundColor $(if ($summary.failing -gt 0) { "Red" } else { "Green" })
    Write-Host "Skipped: $($summary.skipped)" -ForegroundColor Gray

    # Display code coverage
    Write-Host "`nCode Coverage:" -ForegroundColor Cyan
    Write-Host "==============" -ForegroundColor Cyan

    $coverage = $result.result.coverage.coverage | Where-Object { $_.name -eq 'rfiFormController' }
    if ($coverage) {
        $totalLines = $coverage.numLocations
        $coveredLines = $coverage.numLocations - $coverage.numLocationsNotCovered
        $percentage = [math]::Round(($coveredLines / $totalLines) * 100, 2)

        Write-Host "Class: rfiFormController" -ForegroundColor Yellow
        Write-Host "Lines Covered: $coveredLines / $totalLines" -ForegroundColor Yellow
        Write-Host "Coverage: $percentage%" -ForegroundColor $(if ($percentage -ge 75) { "Green" } else { "Red" })

        if ($percentage -ge 75) {
            Write-Host "`n✓ SUCCESS: Code coverage is above 75%!" -ForegroundColor Green
        } else {
            Write-Host "`n✗ FAILURE: Code coverage is below 75%" -ForegroundColor Red
            Write-Host "Uncovered lines:" -ForegroundColor Red
            $coverage.uncoveredLines | ForEach-Object { Write-Host "  Line $_" -ForegroundColor Red }
        }
    }

    # Display failed tests if any
    if ($summary.failing -gt 0) {
        Write-Host "`nFailed Tests:" -ForegroundColor Red
        Write-Host "=============" -ForegroundColor Red
        $result.result.tests | Where-Object { $_.Outcome -eq 'Fail' } | ForEach-Object {
            Write-Host "  - $($_.MethodName): $($_.Message)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "Error running tests:" -ForegroundColor Red
    Write-Host $result -ForegroundColor Red
}
ut