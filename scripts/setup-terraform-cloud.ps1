# PowerShell Script for Setting up Terraform Cloud
# Usage: .\scripts\setup-terraform-cloud.ps1 -Environment personal
# Usage: .\scripts\setup-terraform-cloud.ps1 -Environment team

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("personal", "team")]
    [string]$Environment,
    
    [Parameter(Mandatory=$false)]
    [string]$Organization = "team2-infra",
    
    [Parameter(Mandatory=$false)]
    [string]$TerraformCloudToken = ""
)

# Configuration Variables
$Config = @{
    personal = @{
        WorkspaceName = "team2-infra-personal"
        Description = "Team2 Infrastructure - Personal Development Environment"
        AwsProfile = "personal"
    }
    team = @{
        WorkspaceName = "team2-infra-team"
        Description = "Team2 Infrastructure - Team Production Environment"
        AwsProfile = "default"
    }
}

$envConfig = $Config[$Environment]
$workspaceName = $envConfig.WorkspaceName
$description = $envConfig.Description
$awsProfile = $envConfig.AwsProfile

Write-Host "Setting up Terraform Cloud for $Environment environment" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host ""
Write-Host "Organization: $Organization" -ForegroundColor Cyan
Write-Host "Workspace: $workspaceName" -ForegroundColor Cyan
Write-Host ""

# Check if Terraform CLI is installed
try {
    $tfVersion = terraform version
    Write-Host "SUCCESS: Terraform found: $($tfVersion[0])" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Terraform not found. Please install Terraform first." -ForegroundColor Red
    exit 1
}

# Check if terraform login is configured
Write-Host "Checking Terraform Cloud authentication..." -ForegroundColor Yellow

if ([string]::IsNullOrEmpty($TerraformCloudToken)) {
    Write-Host ""
    Write-Host "STEP 1: Terraform Cloud Authentication" -ForegroundColor Yellow
    Write-Host "You need to authenticate with Terraform Cloud." -ForegroundColor White
    Write-Host ""
    Write-Host "Option A - Use terraform login (Interactive):" -ForegroundColor White
    Write-Host "  terraform login" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Option B - Set token manually:" -ForegroundColor White
    Write-Host "  1. Go to https://app.terraform.io/app/settings/tokens" -ForegroundColor Gray
    Write-Host "  2. Create a new API token" -ForegroundColor Gray
    Write-Host "  3. Run this script again with -TerraformCloudToken parameter" -ForegroundColor Gray
    Write-Host ""
    
    $choice = Read-Host "Do you want to run 'terraform login' now? (y/n)"
    if ($choice -eq 'y' -or $choice -eq 'Y') {
        Write-Host "Running terraform login..." -ForegroundColor Yellow
        terraform login
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "ERROR: Terraform login failed!" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "Please authenticate with Terraform Cloud and run this script again." -ForegroundColor Yellow
        exit 0
    }
} else {
    Write-Host "Using provided Terraform Cloud token..." -ForegroundColor Green
    
    # Set the token in credentials file
    $credentialsPath = "$env:APPDATA\terraform.d\credentials.tfrc.json"
    $credentialsDir = Split-Path $credentialsPath -Parent
    
    if (-not (Test-Path $credentialsDir)) {
        New-Item -ItemType Directory -Path $credentialsDir -Force | Out-Null
    }
    
    $credentials = @{
        credentials = @{
            "app.terraform.io" = @{
                token = $TerraformCloudToken
            }
        }
    }
    
    $credentials | ConvertTo-Json -Depth 3 | Set-Content $credentialsPath
    Write-Host "SUCCESS: Terraform Cloud token configured" -ForegroundColor Green
}

Write-Host ""
Write-Host "STEP 2: Workspace Configuration" -ForegroundColor Yellow

# Navigate to environment directory
$envDir = "environments\$Environment"
if (-not (Test-Path $envDir)) {
    Write-Host "ERROR: Environment directory not found: $envDir" -ForegroundColor Red
    exit 1
}

Push-Location $envDir

try {
    Write-Host "Initializing Terraform with Cloud backend..." -ForegroundColor Yellow
    
    # Initialize Terraform (this will create workspace if it doesn't exist)
    terraform init
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SUCCESS: Terraform Cloud workspace initialized!" -ForegroundColor Green
    } else {
        Write-Host "ERROR: Terraform initialization failed!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "STEP 3: Environment Variables Setup" -ForegroundColor Yellow
    Write-Host "You need to set up environment variables in Terraform Cloud workspace." -ForegroundColor White
    Write-Host ""
    Write-Host "Required Environment Variables:" -ForegroundColor White
    Write-Host "1. AWS_ACCESS_KEY_ID (sensitive)" -ForegroundColor Gray
    Write-Host "2. AWS_SECRET_ACCESS_KEY (sensitive)" -ForegroundColor Gray
    Write-Host "3. AWS_DEFAULT_REGION = ap-northeast-2" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Required Terraform Variables:" -ForegroundColor White
    Write-Host "1. db_password_postgresql (sensitive)" -ForegroundColor Gray
    Write-Host "2. db_password_mongodb (sensitive)" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "To set these variables:" -ForegroundColor Yellow
    Write-Host "1. Go to: https://app.terraform.io/app/$Organization/workspaces/$workspaceName/variables" -ForegroundColor Gray
    Write-Host "2. Add the environment variables listed above" -ForegroundColor Gray
    Write-Host "3. Mark sensitive variables as 'Sensitive'" -ForegroundColor Gray
    Write-Host ""
    
    # Get AWS credentials from local profile
    Write-Host "Getting AWS credentials from local profile..." -ForegroundColor Yellow
    try {
        $awsCredentials = aws configure list --profile $awsProfile
        Write-Host "Local AWS profile configuration:" -ForegroundColor Cyan
        Write-Host $awsCredentials -ForegroundColor Gray
        Write-Host ""
        Write-Host "You can copy these credentials to Terraform Cloud workspace variables." -ForegroundColor White
    } catch {
        Write-Host "WARNING: Could not retrieve AWS credentials from profile: $awsProfile" -ForegroundColor Yellow
    }
    
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "SUCCESS: Terraform Cloud setup completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Set up variables in Terraform Cloud workspace" -ForegroundColor White
Write-Host "2. Run: .\scripts\deploy.ps1 -Environment $Environment -Action plan" -ForegroundColor White
Write-Host "3. Review the plan in Terraform Cloud UI" -ForegroundColor White
Write-Host "4. Apply via Terraform Cloud UI or CLI" -ForegroundColor White
Write-Host ""
Write-Host "Terraform Cloud Workspace URL:" -ForegroundColor Cyan
Write-Host "https://app.terraform.io/app/$Organization/workspaces/$workspaceName" -ForegroundColor Gray 