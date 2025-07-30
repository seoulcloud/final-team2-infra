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
│   │   ├── variables.tf
│   │   └── terraform.tfvars.example
│   └── team/              # 팀계정 (프로덕션)
│       ├── main.tf
│       ├── variables.tf
│       └── terraform.tfvars.example
├── modules/
│   ├── vpc/               # VPC 모듈
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── eks/               # EKS 모듈
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── templates/
│           └── user-data.sh.tpl
├── scripts/
│   ├── set-env-vars.ps1   # DB 패스워드 설정
│   └── deploy.ps1         # 배포 스크립트
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

### 1단계: AWS CLI 프로필 설정

```powershell
# 개인 계정 설정
aws configure --profile personal

# 팀 계정 설정 (기본 프로필)
aws configure --profile default
```

### 2단계: 데이터베이스 패스워드 설정

```powershell
# 개인 환경용
.\scripts\set-env-vars.ps1 -Environment personal

# 팀 환경용
.\scripts\set-env-vars.ps1 -Environment team
```

### 3단계: 환경별 배포

#### 개인 계정 (프리티어) 배포

```powershell
# 환경 설정 복사
cd environments\personal
Copy-Item terraform.tfvars.example terraform.tfvars

# 필요시 terraform.tfvars 편집

# 배포 실행
..\..\scripts\deploy.ps1 -Environment personal -Action init
..\..\scripts\deploy.ps1 -Environment personal -Action plan
..\..\scripts\deploy.ps1 -Environment personal -Action apply
```

#### 팀 계정 배포

```powershell
# 환경 설정 복사
cd environments\team
Copy-Item terraform.tfvars.example terraform.tfvars

# 필요시 terraform.tfvars 편집

# 배포 실행
..\..\scripts\deploy.ps1 -Environment team -Action init
..\..\scripts\deploy.ps1 -Environment team -Action plan
..\..\scripts\deploy.ps1 -Environment team -Action apply
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

### 팀 계정 (프로덕션)
- **인스턴스**: t3.medium/large (On-Demand + Spot 혼합)
- **노드 수**: 최소 2개, 최대 10개
- **디스크**: 50GB
- **Multiple 노드 그룹**: 워크로드별 최적화

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

2. **AWS 자격증명**:
   - IAM 역할 기반 접근 권장
   - 최소 권한 원칙 적용

3. **네트워크 보안**:
   - 모든 데이터베이스는 프라이빗 서브넷에 배치
   - SSM을 통한 안전한 접근

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

## 📞 지원

문제가 발생하면 다음을 확인하세요:
1. AWS CLI 설정 확인
2. Terraform 버전 확인
3. 환경변수 설정 확인
4. AWS 계정 권한 확인
