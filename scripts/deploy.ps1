# PowerShell Script for Terraform Deployment
# Usage: .\scripts\deploy.ps1 -Environment personal -Action plan
# Usage: .\scripts\deploy.ps1 -Environment team -Action apply

<#
.SYNOPSIS
    Deploys or destroys infrastructure using Terraform.
.DESCRIPTION
    A wrapper script for Terraform commands (init, plan, apply, destroy).
    It ensures prerequisites are met and provides user confirmation for critical actions.
.PARAMETER Action
    The Terraform action to perform (init, plan, apply, destroy, validate, fmt).
#>
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("init", "plan", "apply", "destroy", "validate", "fmt")]
    [string]$Action
)

# Configuration
$Config = @{
    ProjectName = "team2-infra"
    Region      = "ap-northeast-2"
    AwsProfile  = "default" # Using single profile now
}

$ProjectName = $Config.ProjectName
$Region = $Config.Region
$AwsProfile = $Config.AwsProfile

# Function to check for required commands
function Test-Command {
    param([string]$command)
    return (Get-Command $command -ErrorAction SilentlyContinue) -ne $null
}

# --- PREREQUISITE CHECKS ---
Write-Host "--- Checking Prerequisites ---" -ForegroundColor Cyan

# Check for AWS CLI
if (-not (Test-Command "aws")) {
    Write-Host "ERROR: AWS CLI is not installed. Please install it and configure your profile." -ForegroundColor Red
    exit 1
}
Write-Host "SUCCESS: AWS CLI found."

# Check for Terraform
if (-not (Test-Command "terraform")) {
    Write-Host "ERROR: Terraform is not installed. Please install it." -ForegroundColor Red
    exit 1
}
Write-Host "SUCCESS: Terraform found."

# Check AWS Profile
try {
    $identity = aws sts get-caller-identity --profile $AwsProfile --output json | ConvertFrom-Json
    Write-Host "SUCCESS: AWS Profile '$AwsProfile' is configured. User: $($identity.Arn)" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: AWS Profile '$AwsProfile' not found or configured correctly." -ForegroundColor Red
    Write-Host "Please run 'aws configure --profile $AwsProfile' to set it up."
    exit 1
}

Write-Host "----------------------------"
Write-Host ""

# --- MAIN LOGIC ---
$terraformDir = "final-team2-infra"
if (-not (Test-Path $terraformDir)) {
    Write-Host "ERROR: Terraform directory '$terraformDir' not found." -ForegroundColor Red
    exit 1
}
Push-Location $terraformDir

try {
    switch ($Action) {
        "init" {
            Write-Host "--- Initializing Terraform ---" -ForegroundColor Cyan
            terraform init
        }
        "plan" {
            Write-Host "--- Planning Infrastructure ---" -ForegroundColor Cyan
            terraform plan
        }
        "apply" {
            Write-Host "--- Applying Infrastructure ---" -ForegroundColor Cyan
            $confirmation = Read-Host "Are you sure you want to apply the changes? (y/n)"
            if ($confirmation -eq 'y') {
                terraform apply -auto-approve
            }
            else {
                Write-Host "Apply cancelled."
            }
        }
        "destroy" {
            Write-Host "--- Destroying Infrastructure ---" -ForegroundColor Red
            $confirmation = Read-Host "ARE YOU SURE you want to destroy all resources? This is irreversible. (y/n)"
            if ($confirmation -eq 'y') {
                terraform destroy -auto-approve
            }
            else {
                Write-Host "Destroy cancelled."
            }
        }
        "validate" {
            Write-Host "--- Validating Terraform Configuration ---" -ForegroundColor Cyan
            terraform validate
        }
        "fmt" {
            Write-Host "--- Formatting Terraform Files ---" -ForegroundColor Cyan
            terraform fmt -recursive
        }
    }
}
finally {
    Pop-Location
}

Write-Host "`nSUCCESS: Action '$Action' completed." -ForegroundColor Green 