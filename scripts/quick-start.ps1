# Quick Start Script for Team2 Infrastructure
# Usage: .\scripts\quick-start.ps1 -Environment personal

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("personal", "team")]
    [string]$Environment
)

# Configuration Variables (Centralized)
$Config = @{
    ProjectName = "team2-infra"
    Region      = "ap-northeast-2"
    Profiles    = @{
        personal = "personal"
        team     = "default"
    }
}

Write-Host "Team2 Infrastructure Quick Start - $Environment Environment" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host ""

# Function to run command and check result
function Invoke-Command-WithCheck {
    param(
        [string]$Command,
        [string]$Description
    )
    
    Write-Host "Step: $Description..." -ForegroundColor Yellow
    try {
        Invoke-Expression $Command
        if ($LASTEXITCODE -eq 0) {
            Write-Host "SUCCESS: $Description completed successfully!" -ForegroundColor Green
        } else {
            Write-Host "ERROR: $Description failed!" -ForegroundColor Red
            exit 1
        }
    } catch {
        Write-Host "ERROR: $Description failed with error: $_" -ForegroundColor Red
        exit 1
    }
    Write-Host ""
}

# Step 1: Set environment variables
Write-Host "Step 1: Setting up database passwords"
Write-Host "This will prompt you for secure passwords..."
Write-Host ""
Invoke-Command-WithCheck ".\scripts\set-env-vars.ps1 -Environment $Environment" "Database password setup"

# Step 2: Navigate to environment directory
$envDir = "environments\$Environment"
Write-Host "Step 2: Navigating to $envDir"
if (-not (Test-Path $envDir)) {
    Write-Host "ERROR: Environment directory not found: $envDir" -ForegroundColor Red
    exit 1
}

Push-Location $envDir
Write-Host "SUCCESS: Changed to directory: $envDir" -ForegroundColor Green
Write-Host ""

try {
    # Step 3: Copy terraform.tfvars
    if (-not (Test-Path "terraform.tfvars")) {
        Write-Host "Step 3: Copying terraform.tfvars.example to terraform.tfvars"
        Copy-Item "terraform.tfvars.example" "terraform.tfvars"
        Write-Host "SUCCESS: terraform.tfvars created successfully!" -ForegroundColor Green
        Write-Host ""
    } else {
        Write-Host "INFO: terraform.tfvars already exists, skipping copy" -ForegroundColor Yellow
        Write-Host ""
    }
    
    # Step 4: Initialize Terraform
    Invoke-Command-WithCheck "terraform init" "Terraform initialization"
    
    # Step 5: Format and validate
    Invoke-Command-WithCheck "terraform fmt" "Terraform formatting"
    Invoke-Command-WithCheck "terraform validate" "Terraform validation"
    
    # Step 6: Plan
    Write-Host "Step 6: Planning Terraform deployment..."
    Write-Host "This will show you what resources will be created." -ForegroundColor Cyan
    Write-Host ""
    $planFile = "terraform-quickstart-$(Get-Date -Format 'yyyyMMdd-HHmmss').tfplan"
    Invoke-Command-WithCheck "terraform plan -out=$planFile" "Terraform planning"
    
    Write-Host "Quick Start Completed Successfully!" -ForegroundColor Green
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host ""
    
    # Generate dynamic variables for output
    $profile = $Config.Profiles[$Environment]
    $clusterName = "$($Config.ProjectName)-$Environment-cluster"
    
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Review the plan above to ensure it looks correct" -ForegroundColor White
    Write-Host ""
    Write-Host "2. Apply the plan to create resources:" -ForegroundColor White
    Write-Host "   terraform apply $planFile" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   OR use the deployment script:" -ForegroundColor White
    Write-Host "   ..\..\scripts\deploy.ps1 -Environment $Environment -Action apply" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. After successful deployment, test SSM connectivity:" -ForegroundColor White
    Write-Host "   aws ec2 describe-instances --filters 'Name=tag:kubernetes.io/cluster/$clusterName,Values=owned' --query 'Reservations[].Instances[].InstanceId' --output table --profile $profile" -ForegroundColor Gray
    Write-Host ""
    Write-Host "4. Configure kubectl:" -ForegroundColor White
    Write-Host "   aws eks update-kubeconfig --region $($Config.Region) --name $clusterName --profile $profile" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "Tips:" -ForegroundColor Cyan
    Write-Host "- Plan file saved as: $planFile" -ForegroundColor Gray
    Write-Host "- All sensitive data is stored in environment variables" -ForegroundColor Gray
    Write-Host "- Never commit terraform.tfvars to version control" -ForegroundColor Gray
    Write-Host ""
    
    if ($Environment -eq "personal") {
        Write-Host "Cost Optimization (Personal Account):" -ForegroundColor Yellow
        Write-Host "- Using t3.small instances with Spot pricing" -ForegroundColor Gray
        Write-Host "- Minimal node count (1-2 nodes)" -ForegroundColor Gray
        Write-Host "- 20GB disk size" -ForegroundColor Gray
        Write-Host "- Expected cost: ~`$30-50/month" -ForegroundColor Gray
    } else {
        Write-Host "Production Scale (Team Account):" -ForegroundColor Yellow
        Write-Host "- Using t3.medium/large instances" -ForegroundColor Gray
        Write-Host "- Higher node count (2-10 nodes)" -ForegroundColor Gray
        Write-Host "- 50GB disk size" -ForegroundColor Gray
        Write-Host "- Mixed On-Demand and Spot instances" -ForegroundColor Gray
    }

} finally {
    Pop-Location
} 