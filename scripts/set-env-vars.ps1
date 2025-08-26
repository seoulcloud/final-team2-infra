<#
.SYNOPSIS
    Sets database passwords as environment variables for Terraform.
.DESCRIPTION
    This script securely prompts the user for PostgreSQL and MongoDB passwords
    and sets them as environment variables (TF_VAR_db_password_...).
    It includes password strength validation.
#>

# Function to validate password strength
function Test-PasswordStrength {
    param ($password)
    $minLength = 8
    $hasUpper = $password -cmatch "[A-Z]"
    $hasLower = $password -cmatch "[a-z]"
    $hasDigit = $password -cmatch "\d"
    $hasSpecial = $password -cmatch "[\W_]" # Non-word character

    return ($password.Length -ge $minLength) -and $hasUpper -and $hasLower -and $hasDigit -and $hasSpecial
}

# --- SET POSTGRESQL PASSWORD ---
Write-Host "--- Setting PostgreSQL Password ---" -ForegroundColor Cyan
while ($true) {
    $postgresqlPassword = Read-Host -Prompt "Enter PostgreSQL Password (will not be displayed)" -AsSecureString
    $plainTextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($postgresqlPassword))

    if (Test-PasswordStrength $plainTextPassword) {
        $env:TF_VAR_db_password_postgresql = $plainTextPassword
        Write-Host "SUCCESS: PostgreSQL password set as environment variable." -ForegroundColor Green
        break
    }
    else {
        Write-Host "WARNING: Password does not meet complexity requirements." -ForegroundColor Yellow
        Write-Host "Requirements: Minimum 8 characters, at least one uppercase, one lowercase, one number, and one special character."
    }
}

# --- SET MONGODB PASSWORD ---
Write-Host "`n--- Setting MongoDB Password ---" -ForegroundColor Cyan
while ($true) {
    $mongodbPassword = Read-Host -Prompt "Enter MongoDB Password (will not be displayed)" -AsSecureString
    $plainTextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($mongodbPassword))

    if (Test-PasswordStrength $plainTextPassword) {
        $env:TF_VAR_db_password_mongodb = $plainTextPassword
        Write-Host "SUCCESS: MongoDB password set as environment variable." -ForegroundColor Green
        break
    }
    else {
        Write-Host "WARNING: Password does not meet complexity requirements." -ForegroundColor Yellow
    }
}

Write-Host "`nSUCCESS: All database passwords are set for this session." -ForegroundColor Green
exit 0 