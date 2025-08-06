
# Team2 Infrastructure with Terraform

이 프로젝트는 AWS에서 EKS 클러스터와 데이터베이스를 포함한 완전한 인프라를 Terraform으로 관리합니다.

## 🏗️ 아키텍처 개요

### 0단계: VPC 및 네트워킹
- **VPC**: 10.0.0.0/16 CIDR
- **프라이빗 서브넷 6개** (2 AZ에 걸쳐):
  - EKS 서브넷: `10.0.10.0/24`, `10.0.11.0/24`
  - PostgreSQL 서브넷: `10.0.20.0/24`, `10.0.21.0/24`
  - MongoDB 서브넷: `10.0.30.0/24`, `10.0.31.0/24`
  - Elasticache 서브넷 : `10.0.40.0/24`, `10.0.41.0/24`
- **SSM VPC 엔드포인트**: 프라이빗 서브넷에서 SSM 접근 가능

### 1단계: EKS 클러스터
- **EKS 클러스터**: Kubernetes 1.30
- **노드 그룹**: `t3.medium/large` (On-Demand + Spot 혼합) << 테스트환경에서 small사용>>
- **SSM 접근**: 모든 EKS 노드에서 SSM Session Manager 지원
- **AccessEntry only : Configmap이 아닌 AWS 공식 권장사항 적용

## 📁 프로젝트 구조 (단일 환경)

```
final-team2-infra/
├── main.tf                 # 메인 리소스 정의
├── provider.tf             # Provider 및 Terraform Cloud 설정
├── versions.tf             # Terraform 버전 제약
├── variables.tf            # 모든 변수 정의
├── terraform.tfvars.example # 변수 예시
├── modules/
│   ├── vpc/                # VPC 모듈
│   └── eks/                # EKS 모듈
├── scripts/
│   ├── set-env-vars.ps1    # DB 패스워드 설정
│   ├── deploy.ps1          # 배포 스크립트
│   ├── quick-start.ps1     # 빠른 시작 스크립트
│   └── setup-terraform-cloud.ps1 # Terraform Cloud 설정
└── README.md
```

## 🚀 시작하기

### 사전 요구사항

1. **Terraform 설치** (>= 1.0)
2. **AWS CLI 설치** 및 `default` 프로필 구성
3. **PowerShell** (Windows)
4. **Terraform Cloud 계정** (선택사항)

### 완전 자동화 배포 방법

#### **Terraform Cloud 환경 (권장)**
```bash
# 1단계: Terraform Cloud에서 자동 배포
terraform plan   # 모든 인프라 + Helm 차트 계획
terraform apply  # EKS + cert-manager + ArgoCD 자동 배포

# 2단계: GitOps 설정 (수동 - 1회만)
# EKS 클러스터 접근 설정
aws eks update-kubeconfig --region ap-northeast-2 --name <cluster-name>

# ClusterIssuer 생성
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@your-domain.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - dns01:
        route53:
          region: ap-northeast-2
EOF

# ArgoCD App-of-Apps 생성  
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app-of-apps
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-username/final-team2-manifest.git
    targetRevision: HEAD
    path: final-team2-manifest/overlays/team
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF
```

#### **로컬 환경에서 단계별 배포** (디버깅용)
```bash
# 1단계: 인프라 먼저 배포
terraform apply -target=module.eks -target=module.vpc

# 2단계: Helm 차트 배포  
terraform apply -target=helm_release.cert_manager -target=helm_release.argocd

# 3단계: 나머지 리소스
terraform apply  # 모든 리소스
```

### 배포 후 확인

```bash
# ArgoCD 접속 정보 확인
kubectl get svc -n argocd argocd-server

# ClusterIssuer 상태 확인
kubectl get clusterissuer

# ArgoCD Application 확인
kubectl get application -n argocd
```

### AWS CLI 프로필 설정

```powershell
# 기본 프로필 설정
aws configure
```

## 🌩️ Terraform Cloud 사용 (권장)

### Terraform Cloud 설정

```powershell
# Terraform Cloud 설정
.\scripts\setup-terraform-cloud.ps1
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
- `db_password_elasticache` (sensitive)

### Terraform Cloud로 배포

```powershell
# Plan 실행 (Terraform Cloud에서 실행됨)
.\scripts\deploy.ps1 -Action plan

# Apply는 Terraform Cloud UI에서 확인 후 실행
```


### 배포

```powershell
# 빠른 시작 (권장)
.\scripts\quick-start.ps1

# 또는 단계별 실행
.\scripts\deploy.ps1 -Action init
.\scripts\deploy.ps1 -Action plan
.\scripts\deploy.ps1 -Action apply
```

## 🔧 SSM 접근 방법

### EKS 노드에 SSM으로 접근

1. **실행 중인 인스턴스 목록 확인**:
```powershell
aws ec2 describe-instances --filters "Name=tag:kubernetes.io/cluster/team2-infra-team-cluster,Values=owned" --query "Reservations[].Instances[].InstanceId" --output table
```

2. **SSM 세션 시작**: 플러그인 없으면 설치해서 하면되는데 없이 쓸 수 있는 명령어 사용해도 됩니다.
```powershell
aws ssm start-session --target <instance-id>
```

### kubectl 설정

```powershell
aws eks update-kubeconfig --region ap-northeast-2 --name team2-infra-team-cluster
```

## 💰 비용 최적화

- **인스턴스**: t3.medium/large (On-Demand + Spot 혼합)
- **노드 수**: 최소 2개, 최대 10개
- **디스크**: 50GB
- **예상 비용**: ~$200-500/월

## ⚠️ 보안 주의사항

1. **패스워드 관리**: 
   - `terraform.tfvars` 파일은 절대 커밋하지 마세요
   - 환경변수로 민감한 정보 관리
   - Terraform Cloud에서는 Sensitive 변수로 표시

2. **AWS 자격증명**:
   - IAM 역할 기반 접근 권장
   - 최소 권한 원칙 적용

3. **네트워크 보안**:
   - 모든 데이터베이스는 프라이빗 서브넷에 배치
   - SSM을 통한 안전한 접근
   - EKS 퍼블릭 엔드포인트 IP 제한

## 🆘 문제 해결

1. **AWS 자격증명 오류**:
```powershell
aws sts get-caller-identity
```

2. **환경변수 누락**:
```powershell
.\scripts\set-env-vars.ps1
```

3. **Terraform Cloud 인증 오류**:
```powershell
terraform login
```

4. **EKS 의존성**
권한 및 policy가 role보다 먼저생기는경우가 많고
클러스터보다 먼저 생겨서 create fail 되는경우 많았습니다.
depend on 설정하고 그래도 안되는건 timeout 처리해서 기다리는 방식으로 처리했고
AccessEntry 관련 권한도 마찬가지인 경우가 많아 의존성 체인을 향후 정리해놓으면 구축하거나 유지보수할때 용이해보입니다.

=======
# final-team2-infra
✈️ GotEEgo 서비스의 인프라 설정 및 배포 코드를 관리하는 레포지토리입니다. CLD-3rd Team 2에서 운영합니다.
terraform/  
├── modules/  
│   ├── vpc/                    # VPC, 서브넷, 라우팅 (완)  
│   ├── eks/                    # EKS 클러스터 (완)  
│   ├── rds/                    # PostgreSQL  
│   ├── mongodb/                # MongoDB  
│   ├── elasticache/            # Redis  
│   ├── s3-cloudfront/          # S3 + CloudFront + Route53  
│   ├── monitoring/             # Prometheus, Grafana  
│   ├── argocd/                 # ArgoCD  
│   └── iam/                    # IAM Role, Policy  
├── environments/  
│   ├── dev/  
│   └── prod/  
├── variables.tf  
├── outputs.tf  
├── backend.tf  
└── versions.tf  

테스트 환경에서 구축시간 단축시킬려고 우선 적은용량 적용했는데 마무리테스트 할때쯤엔 최초계획대로 올려야 합니다.