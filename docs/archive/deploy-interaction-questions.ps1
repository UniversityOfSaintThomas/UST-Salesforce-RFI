# RFI Additional Questions Interactions - Deployment Script
# Created by Thaddaeus Dahlberg, Software Engineer, University of St. Thomas

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "RFI Interaction Questions Deployment" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Check if in correct directory
if (-not (Test-Path "cumulusci.yml")) {
    Write-Host "ERROR: Must be run from project root directory" -ForegroundColor Red
    exit 1
}

# Ask for org name
$orgName = Read-Host "Enter org name (default: dev)"
if ([string]::IsNullOrWhiteSpace($orgName)) {
    $orgName = "dev"
}

Write-Host ""
Write-Host "Step 1: Deploying custom field..." -ForegroundColor Yellow
try {
    cci task run deploy --path force-app/main/default/objects/RFI_Controller__c/fields/Interaction_Questions__c.field-meta.xml --org $orgName
    Write-Host "✓ Field deployed successfully" -ForegroundColor Green
} catch {
    Write-Host "✗ Field deployment failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 2: Deploying LWC component..." -ForegroundColor Yellow
try {
    cci task run deploy --path force-app/main/default/lwc/rfiAdditionalQuestionsInteractions --org $orgName
    Write-Host "✓ Component deployed successfully" -ForegroundColor Green
} catch {
    Write-Host "✗ Component deployment failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Navigate to an RFI Controller record in your org"
Write-Host "2. Click the gear icon and select 'Edit Page'"
Write-Host "3. Drag the 'rfiAdditionalQuestionsInteractions' component onto the page"
Write-Host "4. Save and activate the page"
Write-Host ""
Write-Host "Documentation: docs/RFI_INTERACTION_QUESTIONS_GUIDE.md" -ForegroundColor Cyan

