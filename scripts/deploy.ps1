# PowerShell Script for Terraform Deployment
# Usage: .\scripts\deploy.ps1 -Environment personal -Action plan
# Usage: .\scripts\deploy.ps1 -Environment team -Action apply

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("personal", "team")]
    [string]$Environment,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("init", "plan", "apply", "destroy", "validate", "fmt")]
    [string]$Action,
    
    [switch]$AutoApprove,
    [switch]$SkipValidation
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

# Colors for output
$Green = "Green"
$Red = "Red"
$Yellow = "Yellow"
$Cyan = "Cyan"
$White = "White"
$Gray = "Gray"

# Function to display banner
function Show-Banner {
    param([string]$Text, [string]$Color = "Cyan")
    
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor $Color
    Write-Host "  $Text" -ForegroundColor $Color
    Write-Host "=" * 60 -ForegroundColor $Color
    Write-Host ""
}

# Function to check prerequisites
function Test-Prerequisites {
    Write-Host "Checking prerequisites..." -ForegroundColor $Yellow
    
    # Check if Terraform is installed
    try {
        $tfVersion = terraform version
        Write-Host "SUCCESS: Terraform found: $($tfVersion[0])" -ForegroundColor $Green
    } catch {
        Write-Host "ERROR: Terraform not found. Please install Terraform first." -ForegroundColor $Red
        exit 1
    }
    
    # Check if AWS CLI is configured
    try {
        $awsProfile = $Config.Profiles[$Environment]
        aws sts get-caller-identity --profile $awsProfile | Out-Null
        Write-Host "SUCCESS: AWS CLI configured for profile: $awsProfile" -ForegroundColor $Green
    } catch {
        Write-Host "ERROR: AWS CLI not configured for profile: $awsProfile" -ForegroundColor $Red
        Write-Host "Please run: aws configure --profile $awsProfile" -ForegroundColor $Yellow
        exit 1
    }
    
    # Check if environment variables are set (for apply/plan)
    if ($Action -in @("plan", "apply")) {
        if (-not $env:TF_VAR_db_password_postgresql -or -not $env:TF_VAR_db_password_mongodb) {
            Write-Host "WARNING: Database passwords not set. Run set-env-vars.ps1 first:" -ForegroundColor $Yellow
            Write-Host ".\scripts\set-env-vars.ps1 -Environment $Environment" -ForegroundColor $Gray
            if (-not $SkipValidation) {
                exit 1
            }
        } else {
            Write-Host "SUCCESS: Database environment variables are set" -ForegroundColor $Green
        }
    }
    
    Write-Host ""
}

# Function to run terraform command with error handling
function Invoke-TerraformCommand {
    param(
        [string]$Command,
        [string]$WorkingDirectory
    )
    
    Push-Location $WorkingDirectory
    try {
        Write-Host "Executing: $Command" -ForegroundColor $Cyan
        Write-Host ""
        
        # Execute the command
        Invoke-Expression $Command
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host ""
            Write-Host "ERROR: Command failed with exit code: $LASTEXITCODE" -ForegroundColor $Red
            exit $LASTEXITCODE
        } else {
            Write-Host ""
            Write-Host "SUCCESS: Command completed successfully!" -ForegroundColor $Green
        }
    } finally {
        Pop-Location
    }
}

# Main script execution
Show-Banner "Terraform Deployment Script - $Environment Environment"

# Set working directory
$workingDir = "environments\$Environment"
if (-not (Test-Path $workingDir)) {
    Write-Host "ERROR: Environment directory not found: $workingDir" -ForegroundColor $Red
    exit 1
}

Write-Host "Working directory: $workingDir" -ForegroundColor $Cyan
Write-Host "Action: $Action" -ForegroundColor $Cyan

# Check prerequisites
Test-Prerequisites

# Confirmation for destructive actions
if ($Action -in @("apply", "destroy") -and -not $AutoApprove) {
    Show-Banner "CONFIRMATION REQUIRED" "Yellow"
    Write-Host "You are about to run 'terraform $Action' on the $Environment environment." -ForegroundColor $Yellow
    Write-Host ""
    
    if ($Action -eq "destroy") {
        Write-Host "WARNING: This will DESTROY all resources in this environment!" -ForegroundColor $Red
        Write-Host ""
    }
    
    $confirmation = Read-Host "Do you want to proceed? (y/n)"
    if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
        Write-Host "ERROR: Operation cancelled by user." -ForegroundColor $Red
        exit 0
    }
}

# Execute terraform commands based on action
switch ($Action) {
    "init" {
        Show-Banner "Initializing Terraform"
        Invoke-TerraformCommand "terraform init" $workingDir
    }
    
    "validate" {
        Show-Banner "Validating Terraform Configuration"
        Invoke-TerraformCommand "terraform validate" $workingDir
    }
    
    "fmt" {
        Show-Banner "Formatting Terraform Files"
        Invoke-TerraformCommand "terraform fmt -recursive" $workingDir
    }
    
    "plan" {
        Show-Banner "Planning Terraform Deployment"
        
        # Run additional checks before planning
        Write-Host "Running pre-plan checks..." -ForegroundColor $Yellow
        Invoke-TerraformCommand "terraform fmt -check" $workingDir
        Invoke-TerraformCommand "terraform validate" $workingDir
        
        # Generate plan
        $planFile = "terraform-$(Get-Date -Format 'yyyyMMdd-HHmmss').tfplan"
        Invoke-TerraformCommand "terraform plan -out=$planFile" $workingDir
        
        Write-Host ""
        Write-Host "Plan saved to: $planFile" -ForegroundColor $Green
        Write-Host "To apply this plan, run:" -ForegroundColor $Yellow
        Write-Host "terraform apply $planFile" -ForegroundColor $Gray
    }
    
    "apply" {
        Show-Banner "Applying Terraform Configuration"
        
        # Run pre-apply checks
        Write-Host "Running pre-apply checks..." -ForegroundColor $Yellow
        Invoke-TerraformCommand "terraform fmt -check" $workingDir
        Invoke-TerraformCommand "terraform validate" $workingDir
        
        # Apply configuration
        if ($AutoApprove) {
            Invoke-TerraformCommand "terraform apply -auto-approve" $workingDir
        } else {
            Invoke-TerraformCommand "terraform apply" $workingDir
        }
        
        # Show outputs
        Write-Host ""
        Show-Banner "Deployment Outputs"
        Invoke-TerraformCommand "terraform output" $workingDir
    }
    
    "destroy" {
        Show-Banner "Destroying Terraform Resources" "Red"
        
        if ($AutoApprove) {
            Invoke-TerraformCommand "terraform destroy -auto-approve" $workingDir
        } else {
            Invoke-TerraformCommand "terraform destroy" $workingDir
        }
    }
}

# Final message
Show-Banner "Operation Completed Successfully!" "Green"

if ($Action -eq "apply") {
    $profile = $Config.Profiles[$Environment]
    $clusterName = "$($Config.ProjectName)-$Environment-cluster"
    
    Write-Host "Next Steps:" -ForegroundColor $Yellow
    Write-Host "1. Verify resources in AWS Console" -ForegroundColor $White
    Write-Host "2. Test SSM connectivity:" -ForegroundColor $White
    Write-Host "   aws ec2 describe-instances --filters 'Name=tag:kubernetes.io/cluster/$clusterName,Values=owned' --query 'Reservations[].Instances[].InstanceId' --output table --profile $profile" -ForegroundColor $Gray
    Write-Host "3. Configure kubectl:" -ForegroundColor $White
    Write-Host "   aws eks update-kubeconfig --region $($Config.Region) --name $clusterName --profile $profile" -ForegroundColor $Gray
} 