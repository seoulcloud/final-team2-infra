# PowerShell Script for Setting up Terraform S3 Backend
# Usage: .\scripts\setup-backend.ps1 -Environment personal
# Usage: .\scripts\setup-backend.ps1 -Environment team

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("personal", "team")]
    [string]$Environment
)

# Configuration Variables
$Config = @{
    personal = @{
        BucketName = "terraform-state-personal-team2"
        DynamoTable = "terraform-lock-personal-team2"
        Profile = "personal"
    }
    team = @{
        BucketName = "terraform-state-team-team2"
        DynamoTable = "terraform-lock-team-team2"
        Profile = "default"
    }
}

$envConfig = $Config[$Environment]
$bucketName = $envConfig.BucketName
$dynamoTable = $envConfig.DynamoTable
$profile = $envConfig.Profile

Write-Host "🪣 Setting up Terraform S3 Backend for $Environment environment" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host ""

# Function to check if resource exists
function Test-AWSResource {
    param(
        [string]$ResourceType,
        [string]$ResourceName,
        [string]$Profile
    )
    
    try {
        switch ($ResourceType) {
            "s3" {
                aws s3api head-bucket --bucket $ResourceName --profile $Profile 2>$null
                return $LASTEXITCODE -eq 0
            }
            "dynamodb" {
                aws dynamodb describe-table --table-name $ResourceName --profile $Profile 2>$null
                return $LASTEXITCODE -eq 0
            }
        }
    } catch {
        return $false
    }
}

# Check if S3 bucket exists
Write-Host "🔍 Checking if S3 bucket exists: $bucketName"
if (Test-AWSResource -ResourceType "s3" -ResourceName $bucketName -Profile $profile) {
    Write-Host "✅ S3 bucket already exists: $bucketName" -ForegroundColor Green
} else {
    Write-Host "📦 Creating S3 bucket: $bucketName" -ForegroundColor Yellow
    
    # Create S3 bucket
    aws s3api create-bucket --bucket $bucketName --region ap-northeast-2 --create-bucket-configuration LocationConstraint=ap-northeast-2 --profile $profile
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ S3 bucket created successfully!" -ForegroundColor Green
        
        # Enable versioning
        Write-Host "🔄 Enabling versioning on S3 bucket..." -ForegroundColor Yellow
        aws s3api put-bucket-versioning --bucket $bucketName --versioning-configuration Status=Enabled --profile $profile
        
        # Enable server-side encryption
        Write-Host "🔐 Enabling server-side encryption..." -ForegroundColor Yellow
        aws s3api put-bucket-encryption --bucket $bucketName --server-side-encryption-configuration '{
            "Rules": [
                {
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }
            ]
        }' --profile $profile
        
        # Block public access
        Write-Host "🚫 Blocking public access..." -ForegroundColor Yellow
        aws s3api put-public-access-block --bucket $bucketName --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" --profile $profile
        
        Write-Host "✅ S3 bucket configured with security best practices!" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to create S3 bucket!" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""

# Check if DynamoDB table exists
Write-Host "🔍 Checking if DynamoDB table exists: $dynamoTable"
if (Test-AWSResource -ResourceType "dynamodb" -ResourceName $dynamoTable -Profile $profile) {
    Write-Host "✅ DynamoDB table already exists: $dynamoTable" -ForegroundColor Green
} else {
    Write-Host "🗄️ Creating DynamoDB table: $dynamoTable" -ForegroundColor Yellow
    
    # Create DynamoDB table for state locking
    aws dynamodb create-table --table-name $dynamoTable --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --profile $profile
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ DynamoDB table created successfully!" -ForegroundColor Green
        
        # Wait for table to be active
        Write-Host "⏳ Waiting for table to be active..." -ForegroundColor Yellow
        aws dynamodb wait table-exists --table-name $dynamoTable --profile $profile
        Write-Host "✅ DynamoDB table is now active!" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to create DynamoDB table!" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "🎉 S3 Backend setup completed successfully!" -ForegroundColor Green
Write-Host ""

# Instructions for enabling backend
Write-Host "📋 Next Steps to Enable S3 Backend:" -ForegroundColor Yellow
Write-Host "1. Edit environments/$Environment/main.tf" -ForegroundColor White
Write-Host "2. Uncomment the backend configuration:" -ForegroundColor White
Write-Host ""
Write-Host "   backend `"s3`" {" -ForegroundColor Gray
Write-Host "     bucket         = `"$bucketName`"" -ForegroundColor Gray
Write-Host "     key            = `"$Environment/terraform.tfstate`"" -ForegroundColor Gray
Write-Host "     region         = `"ap-northeast-2`"" -ForegroundColor Gray
Write-Host "     dynamodb_table = `"$dynamoTable`"" -ForegroundColor Gray
Write-Host "     encrypt        = true" -ForegroundColor Gray
Write-Host "   }" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Run: terraform init -migrate-state" -ForegroundColor White
Write-Host ""

Write-Host "💡 Note: You can continue with local state if you prefer!" -ForegroundColor Cyan
Write-Host "Local state works fine for individual development and testing." -ForegroundColor Gray 