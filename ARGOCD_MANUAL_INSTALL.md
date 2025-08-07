# ArgoCD Helm 수동 설치 매뉴얼

## 📋 개요

Terraform으로 ArgoCD 설치가 실패하는 경우, Helm을 사용하여 수동으로 ArgoCD를 설치하는 방법입니다.

## 🎯 사전 준비

### 1. 필수 도구 확인
```powershell
# kubectl 확인
kubectl version --client

# Helm 확인 (설치되어 있지 않다면 설치)
# Windows용 Helm 설치: https://github.com/helm/helm/releases
# 또는 Chocolatey: choco install kubernetes-helm
helm version
```

### 2. EKS 클러스터 연결 확인
```powershell
# 클러스터 연결 확인
kubectl get nodes

# 클러스터 정보 확인
kubectl cluster-info
```

### 3. ALB Controller 상태 확인
```powershell
# ALB Controller Pod 상태
kubectl get pods -n kube-system | Select-String aws-load-balancer-controller

# Webhook 엔드포인트 확인
kubectl get endpoints -n kube-system aws-load-balancer-webhook-service
```

## 🔧 ArgoCD 수동 설치

### 1. 기존 ArgoCD 리소스 정리 (필요시)
```powershell
# 기존 ArgoCD 네임스페이스 삭제
kubectl delete namespace argocd

# 또는 개별 리소스 삭제
kubectl delete deployment argocd-server -n argocd
kubectl delete svc argocd-server -n argocd
```

### 2. ArgoCD 네임스페이스 생성
```powershell
kubectl create namespace argocd
```

### 3. Helm Repository 추가
```powershell
# ArgoCD Helm repository 추가
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
```

### 4. ArgoCD Helm 설치

#### 기본 설치 (권장)
```powershell
helm install argocd argo/argo-cd --namespace argocd --version 5.51.6 --set server.service.type=LoadBalancer --set server.extraArgs[0]="--insecure" --set configs.params.server.insecure=true --set server.resources.requests.cpu=100m --set server.resources.requests.memory=128Mi --set server.resources.limits.cpu=200m --set server.resources.limits.memory=256Mi --set server.replicaCount=1 --timeout 15m
```

#### 고급 설치 (리소스 제한 포함)
```powershell
helm install argocd argo/argo-cd --namespace argocd --version 5.51.6 --set server.service.type=LoadBalancer --set server.extraArgs[0]="--insecure" --set configs.params.server.insecure=true --set server.resources.requests.cpu=100m --set server.resources.requests.memory=128Mi --set server.resources.limits.cpu=200m --set server.resources.limits.memory=256Mi --set server.replicaCount=1 --set applicationSet.resources.requests.cpu=100m --set applicationSet.resources.requests.memory=128Mi --set applicationSet.resources.limits.cpu=200m --set applicationSet.resources.limits.memory=256Mi --set repoServer.resources.requests.cpu=100m --set repoServer.resources.requests.memory=128Mi --set repoServer.resources.limits.cpu=200m --set repoServer.resources.limits.memory=256Mi --set redis.resources.requests.cpu=50m --set redis.resources.requests.memory=64Mi --set redis.resources.limits.cpu=100m --set redis.resources.limits.memory=128Mi --timeout 15m
```

## 📊 설치 상태 확인

### 1. Helm 릴리즈 상태 확인
```powershell
# Helm 릴리즈 목록
helm list -n argocd

# Helm 릴리즈 상태
helm status argocd -n argocd
```

### 2. Pod 상태 확인
```powershell
# 모든 Pod 상태
kubectl get pods -n argocd

# 실시간 모니터링
kubectl get pods -n argocd -w
```

### 3. 서비스 상태 확인
```powershell
# LoadBalancer 서비스 상태
kubectl get svc argocd-server -n argocd

# 모든 서비스 상태
kubectl get svc -n argocd
```

### 4. 로그 확인
```powershell
# ArgoCD Server 로그
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server --tail=50

# Application Controller 로그
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller --tail=50
```

## 🔑 ArgoCD 초기 설정

### 1. Admin 비밀번호 확인
```powershell
# 초기 Admin 비밀번호 확인
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### 2. LoadBalancer URL 확인
```powershell
# LoadBalancer URL 확인
kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# 또는
kubectl get svc argocd-server -n argocd
```

### 3. ArgoCD CLI 설치 (선택사항)
```powershell
# Windows용 ArgoCD CLI 설치
# https://github.com/argoproj/argo-cd/releases 에서 다운로드

# 또는 Chocolatey 사용
choco install argocd

# 설치 확인
argocd version
```

### 4. ArgoCD 로그인
```powershell
# ArgoCD CLI 로그인
argocd login <LOAD_BALANCER_URL> --username admin --password <ADMIN_PASSWORD>

# 또는 브라우저에서 접속
# https://<LOAD_BALANCER_URL>
# 사용자: admin
# 비밀번호: <ADMIN_PASSWORD>
```

## 🔧 문제 해결

### 1. Pod가 Pending 상태인 경우
```powershell
# Pod 상세 정보 확인
kubectl describe pod -n argocd <POD_NAME>

# 노드 리소스 확인
kubectl describe nodes
```

### 2. LoadBalancer가 Pending 상태인 경우
```powershell
# ALB Controller 상태 확인
kubectl get pods -n kube-system | Select-String aws-load-balancer-controller

# ALB Controller 로그 확인
kubectl logs -n kube-system deployment/aws-load-balancer-controller --tail=20

# AWS LoadBalancer 생성 확인
aws elbv2 describe-load-balancers --region ap-northeast-2
```

### 3. Helm 설치 실패 시
```powershell
# Helm 릴리즈 삭제
helm uninstall argocd -n argocd

# 네임스페이스 삭제
kubectl delete namespace argocd

# 다시 설치
kubectl create namespace argocd
helm install argocd argo/argo-cd --namespace argocd [옵션들]
```

### 4. 리소스 부족 시
```powershell
# 노드 리소스 확인
kubectl top nodes

# Pod 리소스 사용량 확인
kubectl top pods -n argocd

# 리소스 제한을 더 낮게 설정하여 재설치
helm install argocd argo/argo-cd --namespace argocd --set server.resources.requests.cpu=50m --set server.resources.requests.memory=64Mi --set server.resources.limits.cpu=100m --set server.resources.limits.memory=128Mi
```

## 📋 설치 체크리스트

- [ ] Helm 설치 확인
- [ ] EKS 클러스터 연결 확인
- [ ] ALB Controller 상태 확인
- [ ] 기존 ArgoCD 리소스 정리
- [ ] ArgoCD 네임스페이스 생성
- [ ] Helm Repository 추가
- [ ] ArgoCD Helm 설치
- [ ] Pod 상태 확인 (모두 Running)
- [ ] LoadBalancer 서비스 확인 (External IP 할당)
- [ ] Admin 비밀번호 확인
- [ ] ArgoCD 로그인 테스트

## 🎯 다음 단계

1. **GitOps Repository 연결**: Git 저장소 추가
2. **Application 배포**: Dev/Prod 환경 Application 생성
3. **SSL 인증서 설정**: cert-manager ClusterIssuer 설정
4. **도메인 연결**: Route53 레코드 설정

## ⚠️ 주의사항

1. **리소스 제한**: 노드 리소스에 맞게 조정
2. **네트워크 설정**: LoadBalancer 생성 시간 고려
3. **보안**: Admin 비밀번호 안전하게 관리
4. **백업**: 설정 변경 전 백업 권장

## 📞 지원

- 📖 [ArgoCD 공식 문서](https://argo-cd.readthedocs.io/)
- 📚 [Helm 차트 문서](https://github.com/argoproj/argo-helm)
- 🐛 [문제 해결 가이드](https://argo-cd.readthedocs.io/en/stable/operator-manual/troubleshooting/) 