# Terraform Apply 이후 수동 설정 매뉴얼

## 📋 개요

Terraform으로 인프라 배포가 완료된 후, ArgoCD GitOps 설정과 애플리케이션 배포를 위한 수동 설정 가이드입니다.

## 🎯 설정 순서

1. [EKS 클러스터 연결](#1-eks-클러스터-연결)
2. [ALB Controller 상태 확인](#2-alb-controller-상태-확인)
3. [ArgoCD 초기 설정](#3-argocd-초기-설정)
4. [cert-manager ClusterIssuer 설정](#4-cert-manager-clusterissuer-설정)
5. [GitOps Repository 연결](#5-gitops-repository-연결)
6. [Application 배포](#6-application-배포)
7. [도메인 및 SSL 설정](#7-도메인-및-ssl-설정)
8. [검증 및 테스트](#8-검증-및-테스트)

---

## 1. EKS 클러스터 연결

### 1.1 클러스터 연결
```powershell
# EKS 클러스터 연결
aws eks update-kubeconfig --region ap-northeast-2 --name goteego-team-cluster

# 연결 확인
kubectl get nodes
```

### 1.2 클러스터 정보 확인
```powershell
# 클러스터 정보
kubectl cluster-info

# 네임스페이스 확인
kubectl get namespaces
```

---

## 2. ALB Controller 상태 확인

### 2.1 ALB Controller Pod 상태
```powershell
# Pod 상태 확인
kubectl get pods -n kube-system | findstr aws-load-balancer-controller

# 예상 결과: 1/1 Running
```

### 2.2 Webhook 서비스 확인
```powershell
# Webhook 서비스 상태
kubectl get svc -n kube-system aws-load-balancer-webhook-service

# Webhook 엔드포인트 확인
kubectl get endpoints -n kube-system aws-load-balancer-webhook-service

# 예상 결과: 엔드포인트 IP가 표시됨
```

### 2.3 Webhook 설정 확인
```powershell
# Mutating Admission Webhook 확인
kubectl get mutatingwebhookconfigurations | findstr aws-load-balancer

# 예상 결과: aws-load-balancer-webhook
```

---

## 3. ArgoCD 초기 설정

### 3.1 ArgoCD 상태 확인
```powershell
# ArgoCD Pod 상태 확인
kubectl get pods -n argocd

# ArgoCD 서비스 확인
kubectl get svc -n argocd argocd-server
```

### 3.2 ArgoCD Admin 비밀번호 확인
```powershell
# 초기 Admin 비밀번호 확인
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# 비밀번호를 안전한 곳에 저장
```

### 3.3 ArgoCD LoadBalancer URL 확인
```powershell
# LoadBalancer URL 확인
kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# 또는
kubectl get svc argocd-server -n argocd
```

### 3.4 ArgoCD CLI 설치 (선택사항)
```powershell
# Windows용 ArgoCD CLI 설치
# https://github.com/argoproj/argo-cd/releases 에서 다운로드

# 또는 Chocolatey 사용
choco install argocd

# 설치 확인
argocd version
```

---

## 4. cert-manager ClusterIssuer 설정

### 4.1 cert-manager 상태 확인
```powershell
# cert-manager Pod 상태
kubectl get pods -n cert-manager

# ClusterIssuer 확인
kubectl get clusterissuer
```

### 4.2 Route53 DNS Challenge용 ClusterIssuer 생성

#### Dev 환경 (Staging 인증서)
```powershell
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
    - dns01:
        route53:
          region: ap-northeast-2
          hostedZoneID: <YOUR_HOSTED_ZONE_ID>
EOF
```

#### Prod 환경 (Production 인증서)
```powershell
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - dns01:
        route53:
          region: ap-northeast-2
          hostedZoneID: <YOUR_HOSTED_ZONE_ID>
EOF
```

### 4.3 ClusterIssuer 상태 확인
```powershell
# ClusterIssuer 상태 확인
kubectl get clusterissuer

# ClusterIssuer 상세 정보
kubectl describe clusterissuer letsencrypt-staging
kubectl describe clusterissuer letsencrypt-prod
```

---

## 5. GitOps Repository 연결

### 5.1 ArgoCD 로그인
```powershell
# ArgoCD CLI 로그인
argocd login <LOAD_BALANCER_URL> --username admin --password <ADMIN_PASSWORD>

# 또는 브라우저에서 접속
# https://<LOAD_BALANCER_URL>
# 사용자: admin
# 비밀번호: <ADMIN_PASSWORD>
```

### 5.2 Repository 추가
```powershell
# Git Repository 추가
argocd repo add https://github.com/your-username/final-team2-manifest.git

# Repository 목록 확인
argocd repo list
```

### 5.3 Repository 연결 확인
```powershell
# Repository 상태 확인
argocd repo get https://github.com/your-username/final-team2-manifest.git
```

---

## 6. Application 배포

### 6.1 Dev 환경 Application 배포
```powershell
# Dev 환경 Application 생성
kubectl apply -f final-team2-manifest/overlays/dev/applications/backend-api.yaml

# Application 상태 확인
kubectl get application -n argocd
```

### 6.2 Prod 환경 Application 배포 (필요시)
```powershell
# Prod 환경 Application 생성
kubectl apply -f final-team2-manifest/overlays/prod/applications/backend-api.yaml

# Application 상태 확인
kubectl get application -n argocd
```

### 6.3 ArgoCD에서 Application 확인
```powershell
# ArgoCD CLI로 Application 확인
argocd app list

# 또는 브라우저에서 ArgoCD UI 접속
# Applications 탭에서 확인
```

---

## 7. 도메인 및 SSL 설정

### 7.1 Route53 레코드 확인
```powershell
# Hosted Zone ID 확인
aws route53 list-hosted-zones

# 레코드 확인
aws route53 list-resource-record-sets --hosted-zone-id <YOUR_HOSTED_ZONE_ID>
```

### 7.2 SSL 인증서 상태 확인
```powershell
# Certificate 상태 확인
kubectl get certificates -A

# Certificate 상세 정보
kubectl describe certificate -n backend-dev backend-api-cert-dev
```

### 7.3 도메인 접속 테스트
```powershell
# Dev 환경 도메인 테스트
curl -I https://api-dev.yourdomain.com

# Prod 환경 도메인 테스트
curl -I https://api.yourdomain.com
```

---

## 8. 검증 및 테스트

### 8.1 전체 시스템 상태 확인
```powershell
# 모든 Pod 상태 확인
kubectl get pods -A

# 모든 Service 상태 확인
kubectl get svc -A

# 모든 Ingress 상태 확인
kubectl get ingress -A
```

### 8.2 ArgoCD Application 동기화
```powershell
# Application 동기화
argocd app sync backend-api-dev

# 동기화 상태 확인
argocd app get backend-api-dev
```

### 8.3 로그 확인
```powershell
# Backend API 로그 확인
kubectl logs -n backend-dev deployment/backend-api-dev

# ALB Controller 로그 확인
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

---

## 🔧 문제 해결

### 자주 발생하는 문제

#### 1. ALB Controller Pod CrashLoopBackOff
```powershell
# Pod 로그 확인
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Pod 상세 정보 확인
kubectl describe pod -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

#### 2. Webhook 엔드포인트 없음
```powershell
# ALB Controller 재시작
kubectl rollout restart deployment aws-load-balancer-controller -n kube-system

# 엔드포인트 대기
kubectl wait --for=condition=ready endpoints/aws-load-balancer-webhook-service -n kube-system --timeout=300s
```

#### 3. SSL 인증서 발급 실패
```powershell
# cert-manager 로그 확인
kubectl logs -n cert-manager deployment/cert-manager

# ClusterIssuer 상태 확인
kubectl describe clusterissuer letsencrypt-staging
```

#### 4. ArgoCD Application 동기화 실패
```powershell
# Application 이벤트 확인
kubectl describe application backend-api-dev -n argocd

# Repository 연결 확인
argocd repo list
```

---

## 📋 체크리스트

### Phase 1: 인프라 배포 (Terraform)
- [x] EKS 클러스터 배포
- [x] ALB Controller 배포
- [x] cert-manager 배포
- [x] ArgoCD 배포

### Phase 2: 기본 설정
- [ ] EKS 클러스터 연결
- [ ] ALB Controller 상태 확인
- [ ] ArgoCD 초기 접속
- [ ] Admin 비밀번호 확인

### Phase 3: SSL/TLS 설정
- [ ] ClusterIssuer 생성 (Staging)
- [ ] ClusterIssuer 생성 (Production)
- [ ] SSL 인증서 발급 확인
- [ ] 도메인 연결 확인

### Phase 4: GitOps 설정
- [ ] Git Repository 연결
- [ ] Dev Application 배포
- [ ] Prod Application 배포 (필요시)
- [ ] Application 동기화 확인

### Phase 5: 검증
- [ ] 모든 Pod Running 상태
- [ ] LoadBalancer 서비스 정상 동작
- [ ] SSL 인증서 정상 발급
- [ ] 도메인 접속 테스트

---

## 🎯 다음 단계

1. **모니터링 설정**: Prometheus, Grafana 설정
2. **백업 설정**: 데이터베이스 백업 정책 설정
3. **보안 강화**: Network Policy, Pod Security Policy 설정
4. **CI/CD 파이프라인**: GitHub Actions 설정

---

## 📞 지원

- 📖 [ALB Controller 수동 설정](ALB_CONTROLLER_MANUAL_SETUP.md)
- 📚 [ArgoCD 매뉴얼](../final-team2-manifest/MANUAL.md)
- 🐛 [문제 해결 가이드](ALB_CONTROLLER_MANUAL_SETUP.md#문제-해결-체크리스트)

---

## ⚠️ 주의사항

1. **Hosted Zone ID**: 위의 명령어에서 `<YOUR_HOSTED_ZONE_ID>`를 실제 값으로 변경하세요.
2. **이메일 주소**: ClusterIssuer 설정에서 `your-email@example.com`을 실제 이메일로 변경하세요.
3. **도메인**: `yourdomain.com`을 실제 도메인으로 변경하세요.
4. **Git Repository**: `your-username`을 실제 GitHub 사용자명으로 변경하세요.
5. **비밀번호 보안**: ArgoCD Admin 비밀번호를 안전하게 관리하세요. 