<#
.SYNOPSIS
    A quick-start script for initializing and planning the Terraform infrastructure.
.DESCRIPTION
    This script automates the initial setup process:
    1. Sets required environment variables (DB passwords).
    2. Copies the example tfvars file.
    3. Runs terraform init, fmt, validate, and plan.
#>

# Configuration
$Config = @{
    ProjectName = "team2-infra"
    Region      = "ap-northeast-2"
    AwsProfile  = "default" # Using single profile now
}

# --- MAIN SCRIPT ---
Write-Host "--- Starting Quick-Start Setup for $($Config.ProjectName) ---" -ForegroundColor Cyan
Write-Host "--------------------------------------------------------"

# Navigate to the correct directory
$terraformDir = "final-team2-infra"
if (-not (Test-Path $terraformDir)) {
    Write-Host "ERROR: Terraform directory '$terraformDir' not found." -ForegroundColor Red
    exit 1
}
Push-Location $terraformDir

try {
    # Step 1: Set database passwords
    Write-Host "`nSTEP 1: Setting up database passwords..." -ForegroundColor Yellow
    & "$PSScriptRoot\set-env-vars.ps1"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Database password setup failed!" -ForegroundColor Red
        exit 1
    }

    # Step 2: Copy terraform.tfvars file
    $tfvarsExample = "terraform.tfvars.example"
    $tfvarsFile = "terraform.tfvars"
    if (-not (Test-Path $tfvarsFile)) {
        Write-Host "`nSTEP 2: Copying $tfvarsExample to $tfvarsFile..." -ForegroundColor Yellow
        Copy-Item -Path $tfvarsExample -Destination $tfvarsFile -Force
        Write-Host "SUCCESS: $tfvarsFile created. Please review and edit it if necessary."
    }
    else {
        Write-Host "`nSTEP 2: $tfvarsFile already exists, skipping copy."
    }

    # Step 3: Run Terraform commands
    Write-Host "`nSTEP 3: Running Terraform commands..." -ForegroundColor Yellow

    $deployScript = "$PSScriptRoot\deploy.ps1"

    # Init
    & $deployScript -Action init
    if ($LASTEXITCODE -ne 0) { throw "Terraform init failed!" }

    # Fmt
    & $deployScript -Action fmt
    if ($LASTEXITCODE -ne 0) { throw "Terraform fmt failed!" }

    # Validate
    & $deployScript -Action validate
    if ($LASTEXITCODE -ne 0) { throw "Terraform validate failed!" }

    # Plan
    & $deployScript -Action plan
    if ($LASTEXITCODE -ne 0) { throw "Terraform plan failed!" }

}
catch {
    Write-Host "`nERROR: An error occurred during the quick-start process." -ForegroundColor Red
    Write-Host $_
    exit 1
}
finally {
    Pop-Location
}

Write-Host "`n--- Quick-Start Setup Finished Successfully! ---" -ForegroundColor Green
Write-Host "Review the plan above. To apply the changes, run: & '$PSScriptRoot\deploy.ps1' -Action apply" 