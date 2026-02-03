# Check rfiFormController Code Coverage
# Run this after tests have completed

Write-Host "`nChecking code coverage for rfiFormController..." -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan

try {
    $result = sf data query --query "SELECT ApexClassOrTrigger.Name, NumLinesCovered, NumLinesUncovered FROM ApexCodeCoverageAggregate WHERE ApexClassOrTrigger.Name = 'rfiFormController'" --target-org UST-Salesforce-RFI__dev --result-format json | ConvertFrom-Json

    if ($result.result.records.Count -gt 0) {
        $record = $result.result.records[0]
        $covered = $record.NumLinesCovered
        $uncovered = $record.NumLinesUncovered
        $total = $covered + $uncovered
        $percent = [math]::Round(($covered / $total) * 100, 2)

        Write-Host "`nClass: rfiFormController" -ForegroundColor Yellow
        Write-Host "Lines Covered: $covered" -ForegroundColor Yellow
        Write-Host "Lines Uncovered: $uncovered" -ForegroundColor Yellow
        Write-Host "Total Lines: $total" -ForegroundColor Yellow
        Write-Host "`nCoverage: $percent%" -ForegroundColor $(if ($percent -ge 75) { 'Green' } else { 'Red' }) -BackgroundColor Black

        if ($percent -ge 75) {
            Write-Host "`n✓ SUCCESS: Code coverage is above 75%!" -ForegroundColor Green
            Write-Host "  The rfiFormController class meets the coverage requirement." -ForegroundColor Green
        } else {
            Write-Host "`n✗ FAILURE: Code coverage is below 75%" -ForegroundColor Red
            Write-Host "  Need to add $([math]::Ceiling((75 - $percent) * $total / 100)) more covered lines" -ForegroundColor Red

            # Show uncovered lines
            Write-Host "`nTo see uncovered lines, run:" -ForegroundColor Yellow
            Write-Host 'sf data query --query "SELECT Coverage FROM ApexCodeCoverage WHERE ApexClassOrTriggerId IN (SELECT Id FROM ApexClass WHERE Name = ''rfiFormController'') LIMIT 1" --target-org UST-Salesforce-RFI__dev --result-format json' -ForegroundColor Gray
        }
    } else {
        Write-Host "`n⚠ No coverage data found for rfiFormController" -ForegroundColor Yellow
        Write-Host "  This usually means tests haven't run yet or need to be deployed." -ForegroundColor Yellow
        Write-Host "`nRun tests with:" -ForegroundColor Cyan
        Write-Host "  cci task run run_tests --org dev --test_name_match rfiFormController_TEST" -ForegroundColor Gray
    }
} catch {
    Write-Host "`n✗ ERROR: Failed to query coverage data" -ForegroundColor Red
    Write-Host "  $_" -ForegroundColor Red
    Write-Host "`nTry running:" -ForegroundColor Yellow
    Write-Host "  cci task run run_tests --org dev --test_name_match rfiFormController_TEST" -ForegroundColor Gray
}

Write-Host "`n" -NoNewline
