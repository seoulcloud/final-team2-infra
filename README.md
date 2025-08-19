
# Team2 Infrastructure with Terraform

이 프로젝트는 AWS에서 EKS 클러스터와 데이터베이스를 포함한 완전한 인프라를 Terraform으로 관리합니다.

## 🏗️ 아키텍처 개요

### 0단계: VPC 및 네트워킹
- **VPC**: 10.0.0.0/16 CIDR
- **프라이빗 서브넷 8개** (2 AZ에 걸쳐):
  - EKS 서브넷: `10.0.10.0/24`, `10.0.11.0/24`
  - PostgreSQL 서브넷: `10.0.20.0/24`, `10.0.21.0/24`
  - MongoDB 서브넷: `10.0.30.0/24`, `10.0.31.0/24`
  - Elasticache 서브넷 : `10.0.40.0/24`, `10.0.41.0/24`
- **SSM VPC 엔드포인트**: 프라이빗 서브넷에서 SSM 접근 가능

### 1단계: EKS 클러스터
- **EKS 클러스터**: Kubernetes 1.33
- **노드 그룹**: `t3.medium/large` (On-Demand + Spot 혼합) << 테스트환경에서 small사용>>
- **SSM 접근**: 모든 EKS 노드에서 SSM Session Manager 지원
- **AccessEntry only : Configmap이 아닌 AWS 공식 권장사항 적용


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
terraform apply  # EKS + ArgoCD 자동 배포

# 2단계: GitOps 설정 (수동 - 1회만)
# EKS 클러스터 접근 설정
aws eks update-kubeconfig --region ap-northeast-2 --name goteego-team-cluster

1. Terraform apply 완료 후 ACM ARN 확인:
       terraform output acm_certificate_arn_ap_northeast_2
    
    2. Backend ingress 매니페스트 수정:
       final-team2-manifest/overlays/dev/applications/backend-api.yaml
       
       annotations 섹션에서:
       alb.ingress.kubernetes.io/certificate-arn:
       "${AP_NORTHEAST_2_ACM_ARN}"
       ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
       alb.ingress.kubernetes.io/certificate-arn: "arn:aws:acm:ap-northeast-2:ACCOUNT:certificate/CERT-ID"
    
    3. ArgoCD로 배포:
       kubectl apply -f base/apps/app-of-apps.yaml
   4.argocd 비밀번호 확인 :
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

### 배포 후 확인

```bash
# ArgoCD 접속 정보 확인
kubectl get svc -n argocd argocd-server
# ArgoCD Application 확인
kubectl get application -n argocd
```

## 🌩️ Terraform Cloud 사용 (권장)

### Terraform Cloud 설정

terraform login
토큰발행해서 등록

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


# 등록한 git에 push 후 run > plan > apply
# Terraform Cloud UI에서 확인 후 실행
```


## 🔧 SSM 접근 방법

### EKS 노드에 SSM으로 접근
노드아이디 확인하는 절차가 불편하니 그냥 콘솔 session manager 이용권장

### kubectl 설정

```
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



2. **Terraform Cloud 인증 오류**:
```
terraform login
```

3. **EKS 의존성**
권한 및 policy가 role보다 먼저생기는경우가 많고
클러스터보다 먼저 생겨서 create fail 되는경우 많았습니다.
depend on 설정하고 그래도 안되는건 timeout 처리해서 기다리는 방식으로 처리했고
AccessEntry 관련 권한도 마찬가지인 경우가 많아 의존성 체인을 향후 정리해놓으면 구축하거나 유지보수할때 용이해보입니다.

=======
# final-team2-infra
✈️ GotEEgo 서비스의 인프라 설정 및 배포 코드를 관리하는 레포지토리입니다. CLD-3rd Team 2에서 운영합니다.

├── modules/  
│   ├── acm_certificate/        # ACM 인증서 발급  
│   ├── acm_dns_validation/     # ACM DNS 검증  
│   ├── alb_controller/         # ALB 컨트롤러  
│   ├── argocd/                 # ArgoCD 설치  
│   ├── cert_manager/           # cert-manager 설치  
│   ├── cloudfront/             # CloudFront 배포  
│   ├── cloudfront_oac/         # CloudFront OAC  
│   ├── eks/                    # EKS 클러스터  
│   ├── external-dns/           # ExternalDNS  
│   ├── s3_frontend/           # S3 프론트엔드 버킷  
│   ├── vpc/                    # VPC, 서브넷, 라우팅  
│   └── web_hosting/           # 정적 웹 호스팅  
├── main.tf                     # 메인 Terraform 설정  
├── outputs.tf                  # 출력 변수  
├── providers.tf                # 프로바이더 설정  
├── terraform.tfvars.example    # 변수 예제  
├── variables.tf                # 변수 정의  
└── versions.tf                 # 버전 제약조건

