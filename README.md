# Team2 Infrastructure with Terraform

이 프로젝트는 AWS에서 EKS 클러스터와 데이터베이스를 포함한 완전한 인프라를 Terraform으로 관리합니다.

## 🏗️ 아키텍처 개요

### 0단계: VPC 및 네트워킹
- **VPC**: 10.0.0.0/16 CIDR
- **프라이빗 서브넷 6개** (2 AZ에 걸쳐):
  - EKS 서브넷: `10.0.10.0/24`, `10.0.11.0/24`
  - PostgreSQL 서브넷: `10.0.20.0/24`, `10.0.21.0/24`
  - MongoDB 서브넷: `10.0.30.0/24`, `10.0.31.0/24`
- **SSM VPC 엔드포인트**: 프라이빗 서브넷에서 SSM 접근 가능

### 1단계: EKS 클러스터
- **EKS 클러스터**: Kubernetes 1.28
- **노드 그룹**: 
  - 개인계정: t3.small (Spot), 최소 비용
  - 팀계정: t3.medium/large (On-Demand + Spot 혼합)
- **SSM 접근**: 모든 EKS 노드에서 SSM Session Manager 지원

## 📁 프로젝트 구조

```
final-team2-infra/
├── environments/
│   ├── personal/           # 개인계정 (프리티어)
│   │   ├── main.tf
│   │   ├── provider.tf     # Provider 및 Terraform Cloud 설정
│   │   ├── versions.tf     # Terraform 버전 제약
│   │   ├── variables.tf
│   │   └── terraform.tfvars.example
│   └── team/              # 팀계정 (프로덕션)
│       ├── main.tf
│       ├── provider.tf     # Provider 및 Terraform Cloud 설정
│       ├── versions.tf     # Terraform 버전 제약
│       ├── variables.tf
│       └── terraform.tfvars.example
├── modules/
│   ├── vpc/               # VPC 모듈
│   └── eks/               # EKS 모듈
├── scripts/
│   ├── set-env-vars.ps1   # DB 패스워드 설정
│   ├── deploy.ps1         # 배포 스크립트
│   ├── quick-start.ps1    # 빠른 시작 스크립트
│   ├── setup-backend.ps1  # S3 백엔드 설정 (선택사항)
│   └── setup-terraform-cloud.ps1  # Terraform Cloud 설정
└── README.md
```

## 🚀 시작하기

### 사전 요구사항

1. **Terraform 설치** (>= 1.0)
2. **AWS CLI 설치** 및 구성
3. **PowerShell** (Windows)
4. **AWS 계정 프로필 설정**:
   - `personal`: 개인 계정 (프리티어)
   - `default`: 팀 계정
5. **Terraform Cloud 계정** (선택사항)

### 1단계: AWS CLI 프로필 설정

```powershell
# 개인 계정 설정
aws configure --profile personal

# 팀 계정 설정 (기본 프로필)
aws configure --profile default
```

## 🌩️ Terraform Cloud 사용 (권장)

### Terraform Cloud 설정

```powershell
# 개인 환경용 Terraform Cloud 설정
.\scripts\setup-terraform-cloud.ps1 -Environment personal

# 팀 환경용 Terraform Cloud 설정
.\scripts\setup-terraform-cloud.ps1 -Environment team
```

### Terraform Cloud 워크스페이스 변수 설정

1. **Terraform Cloud 웹사이트**에서 워크스페이스로 이동
2. **Variables** 탭에서 다음 변수들을 설정:

**Environment Variables (환경변수):**
- `AWS_ACCESS_KEY_ID` (sensitive)
- `AWS_SECRET_ACCESS_KEY` (sensitive)
- `AWS_DEFAULT_REGION` = `ap-northeast-2`

**Terraform Variables:**
- `db_password_postgresql` (sensitive)
- `db_password_mongodb` (sensitive)

### Terraform Cloud로 배포

```powershell
# Plan 실행 (Terraform Cloud에서 실행됨)
.\scripts\deploy.ps1 -Environment personal -Action plan

# Apply는 Terraform Cloud UI에서 확인 후 실행
```

## 🖥️ 로컬 State 사용 (간단한 방법)

### 데이터베이스 패스워드 설정

```powershell
# 개인 환경용
.\scripts\set-env-vars.ps1 -Environment personal

# 팀 환경용  
.\scripts\set-env-vars.ps1 -Environment team
```

### 환경별 배포

#### 개인 계정 (프리티어) 배포

```powershell
# 빠른 시작 (권장)
.\scripts\quick-start.ps1 -Environment personal

# 또는 단계별 실행
.\scripts\deploy.ps1 -Environment personal -Action init
.\scripts\deploy.ps1 -Environment personal -Action plan
.\scripts\deploy.ps1 -Environment personal -Action apply
```

#### 팀 계정 배포

```powershell
# 빠른 시작 (권장)
.\scripts\quick-start.ps1 -Environment team

# 또는 단계별 실행
.\scripts\deploy.ps1 -Environment team -Action init
.\scripts\deploy.ps1 -Environment team -Action plan
.\scripts\deploy.ps1 -Environment team -Action apply
```

## 🔧 SSM 접근 방법

### EKS 노드에 SSM으로 접근

1. **실행 중인 인스턴스 목록 확인**:
```powershell
# 개인 계정
aws ec2 describe-instances --filters "Name=tag:kubernetes.io/cluster/team2-infra-personal-cluster,Values=owned" --query "Reservations[].Instances[].InstanceId" --output table --profile personal

# 팀 계정
aws ec2 describe-instances --filters "Name=tag:kubernetes.io/cluster/team2-infra-team-cluster,Values=owned" --query "Reservations[].Instances[].InstanceId" --output table --profile default
```

2. **SSM 세션 시작**:
```powershell
# 개인 계정
aws ssm start-session --target <instance-id> --profile personal

# 팀 계정
aws ssm start-session --target <instance-id> --profile default
```

### kubectl 설정

```powershell
# 개인 계정
aws eks update-kubeconfig --region ap-northeast-2 --name team2-infra-personal-cluster --profile personal

# 팀 계정
aws eks update-kubeconfig --region ap-northeast-2 --name team2-infra-team-cluster --profile default
```

## 💰 비용 최적화

### 개인 계정 (프리티어)
- **인스턴스**: t3.small (Spot)
- **노드 수**: 최소 1개, 최대 2개
- **디스크**: 20GB
- **NAT Gateway**: 2개 (고가용성)
- **예상 비용**: ~$130-150/월

### 팀 계정 (프로덕션)
- **인스턴스**: t3.medium/large (On-Demand + Spot 혼합)
- **노드 수**: 최소 2개, 최대 10개
- **디스크**: 50GB
- **Multiple 노드 그룹**: 워크로드별 최적화
- **예상 비용**: ~$200-500/월

## 🔄 Backend 옵션 비교

| Backend | 장점 | 단점 | 사용 시나리오 |
|---------|------|------|---------------|
| **Terraform Cloud** | 웹 UI, 팀 협업, 자동 실행, VCS 연동 | 외부 서비스 의존 | 팀 협업, 프로덕션 |
| **S3 Backend** | AWS 네이티브, 비용 저렴, 완전 제어 | 수동 설정 필요 | AWS 중심 팀 |
| **Local State** | 설정 불필요, 즉시 시작 | 협업 어려움, 백업 위험 | 개인 개발, 테스트 |

## 📋 다음 단계 (TODO)

### 2단계: 데이터베이스 구축
- [ ] RDS PostgreSQL 모듈
- [ ] DocumentDB MongoDB 모듈
- [ ] Database 서브넷 그룹 구성

### 3단계: S3 및 프론트엔드
- [ ] S3 버킷 모듈
- [ ] CloudFront 배포
- [ ] Route53 설정

### 4단계: 모니터링
- [ ] CloudWatch 설정
- [ ] Prometheus/Grafana
- [ ] 로그 수집 설정

## ⚠️ 보안 주의사항

1. **패스워드 관리**: 
   - `terraform.tfvars` 파일은 절대 커밋하지 마세요
   - 환경변수로 민감한 정보 관리
   - Terraform Cloud에서는 Sensitive 변수로 표시

2. **AWS 자격증명**:
   - IAM 역할 기반 접근 권장
   - 최소 권한 원칙 적용
   - 정기적인 키 로테이션

3. **네트워크 보안**:
   - 모든 데이터베이스는 프라이빗 서브넷에 배치
   - SSM을 통한 안전한 접근
   - 프로덕션에서는 EKS 퍼블릭 엔드포인트 IP 제한

## 🆘 문제 해결

### 일반적인 문제들

1. **AWS 자격증명 오류**:
```powershell
aws sts get-caller-identity --profile personal
```

2. **Terraform 상태 충돌**:
```powershell
terraform force-unlock <lock-id>
```

3. **환경변수 누락**:
```powershell
.\scripts\set-env-vars.ps1 -Environment personal
```

4. **Terraform Cloud 인증 오류**:
```powershell
terraform login
```

## 📞 지원

문제가 발생하면 다음을 확인하세요:
1. AWS CLI 설정 확인
2. Terraform 버전 확인
3. 환경변수 설정 확인
4. AWS 계정 권한 확인
5. Terraform Cloud 워크스페이스 변수 확인
