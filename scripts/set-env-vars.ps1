# PowerShell Script for Setting Database Environment Variables
# Usage: .\scripts\set-env-vars.ps1 -Environment personal
# Usage: .\scripts\set-env-vars.ps1 -Environment team

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("personal", "team")]
    [string]$Environment
)

Write-Host "🔑 Setting up database password environment variables for $Environment environment" -ForegroundColor Green
Write-Host ""

# Function to read secure password
function Read-SecurePassword {
    param(
        [string]$Prompt
    )
    
    $securePassword = Read-Host -Prompt $Prompt -AsSecureString
    $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    try {
        $password = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
        return $password
    } finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
    }
}

# Function to validate password strength
function Test-PasswordStrength {
    param(
        [string]$Password
    )
    
    $isValid = $true
    $issues = @()
    
    if ($Password.Length -lt 12) {
        $issues += "Password must be at least 12 characters long"
        $isValid = $false
    }
    
    if ($Password -notmatch '[A-Z]') {
        $issues += "Password must contain at least one uppercase letter"
        $isValid = $false
    }
    
    if ($Password -notmatch '[a-z]') {
        $issues += "Password must contain at least one lowercase letter"
        $isValid = $false
    }
    
    if ($Password -notmatch '[0-9]') {
        $issues += "Password must contain at least one number"
        $isValid = $false
    }
    
    if ($Password -notmatch '[^a-zA-Z0-9]') {
        $issues += "Password must contain at least one special character"
        $isValid = $false
    }
    
    return @{
        IsValid = $isValid
        Issues = $issues
    }
}

# Set environment-specific variables
$envPrefix = $Environment.ToUpper()
Write-Host "Environment: $Environment" -ForegroundColor Cyan
Write-Host ""

# PostgreSQL Password
Write-Host "📊 Setting PostgreSQL password..." -ForegroundColor Yellow
do {
    $postgresPassword = Read-SecurePassword "Enter PostgreSQL database password"
    $validation = Test-PasswordStrength -Password $postgresPassword
    
    if (-not $validation.IsValid) {
        Write-Host "❌ Password validation failed:" -ForegroundColor Red
        $validation.Issues | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
        Write-Host ""
    }
} while (-not $validation.IsValid)

# MongoDB Password
Write-Host ""
Write-Host "🍃 Setting MongoDB password..." -ForegroundColor Yellow
do {
    $mongoPassword = Read-SecurePassword "Enter MongoDB database password"
    $validation = Test-PasswordStrength -Password $mongoPassword
    
    if (-not $validation.IsValid) {
        Write-Host "❌ Password validation failed:" -ForegroundColor Red
        $validation.Issues | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
        Write-Host ""
    }
} while (-not $validation.IsValid)

Write-Host ""
Write-Host "🔧 Setting environment variables..." -ForegroundColor Green

# Set environment variables for current session
$env:TF_VAR_db_password_postgresql = $postgresPassword
$env:TF_VAR_db_password_mongodb = $mongoPassword

# Set environment variables permanently for current user
[Environment]::SetEnvironmentVariable("TF_VAR_db_password_postgresql", $postgresPassword, "User")
[Environment]::SetEnvironmentVariable("TF_VAR_db_password_mongodb", $mongoPassword, "User")

Write-Host "✅ Environment variables set successfully!" -ForegroundColor Green
Write-Host ""

# Display current environment variables (masked)
Write-Host "📋 Current Terraform variables:" -ForegroundColor Cyan
Write-Host "  TF_VAR_db_password_postgresql = $('*' * $postgresPassword.Length)" -ForegroundColor Gray
Write-Host "  TF_VAR_db_password_mongodb = $('*' * $mongoPassword.Length)" -ForegroundColor Gray
Write-Host ""

# Instructions
Write-Host "📝 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Navigate to the environment directory:" -ForegroundColor White
Write-Host "   cd environments\$environment" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Copy terraform.tfvars.example to terraform.tfvars:" -ForegroundColor White
Write-Host "   Copy-Item terraform.tfvars.example terraform.tfvars" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Edit terraform.tfvars if needed" -ForegroundColor White
Write-Host ""
Write-Host "4. Initialize Terraform:" -ForegroundColor White
Write-Host "   terraform init" -ForegroundColor Gray
Write-Host ""
Write-Host "5. Plan the deployment:" -ForegroundColor White
Write-Host "   terraform plan" -ForegroundColor Gray
Write-Host ""
Write-Host "⚠️  Remember: Never commit terraform.tfvars to version control!" -ForegroundColor Red

# Clear sensitive variables from memory
$postgresPassword = $null
$mongoPassword = $null

Write-Host ""
Write-Host "🎉 Setup completed for $environment environment!" -ForegroundColor Green 