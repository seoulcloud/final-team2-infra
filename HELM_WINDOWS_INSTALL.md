# Helm Windows 설치 가이드

## 📋 개요

Windows 환경에서 Helm을 설치하는 다양한 방법을 안내합니다.

## 🎯 방법 1: 공식 바이너리 다운로드 (권장)

### 1. Helm 버전 확인
```powershell
# 최신 버전 확인 (웹에서)
# https://github.com/helm/helm/releases
```

### 2. Helm 다운로드
```powershell
# PowerShell에서 실행
# 최신 버전 (예: v3.14.0)
$HELM_VERSION = "v3.14.0"
$HELM_URL = "https://get.helm.sh/helm-$HELM_VERSION-windows-amd64.zip"
$HELM_ZIP = "$env:TEMP\helm-$HELM_VERSION-windows-amd64.zip"
$HELM_DIR = "$env:TEMP\helm-$HELM_VERSION-windows-amd64"

# Helm 다운로드
Invoke-WebRequest -Uri $HELM_URL -OutFile $HELM_ZIP

# 압축 해제
Expand-Archive -Path $HELM_ZIP -DestinationPath $env:TEMP -Force

# Helm 실행 파일을 PATH에 추가할 디렉토리 생성
$HELM_INSTALL_DIR = "$env:USERPROFILE\helm"
if (!(Test-Path $HELM_INSTALL_DIR)) {
    New-Item -ItemType Directory -Path $HELM_INSTALL_DIR -Force
}

# Helm 실행 파일 복사
Copy-Item "$HELM_DIR\windows-amd64\helm.exe" -Destination $HELM_INSTALL_DIR -Force

# PATH에 추가
$PATH = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($PATH -notlike "*$HELM_INSTALL_DIR*") {
    [Environment]::SetEnvironmentVariable("PATH", "$PATH;$HELM_INSTALL_DIR", "User")
}

# 임시 파일 정리
Remove-Item $HELM_ZIP -Force
Remove-Item $HELM_DIR -Recurse -Force

Write-Host "Helm 설치 완료! 새 PowerShell 창을 열어주세요."
```

### 3. 설치 확인
```powershell
# 새 PowerShell 창에서 실행
helm version
```

## 🎯 방법 2: Chocolatey 사용

### 1. Chocolatey 설치 (없는 경우)
```powershell
# 관리자 권한으로 PowerShell 실행
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

### 2. Helm 설치
```powershell
# 관리자 권한으로 PowerShell 실행
choco install kubernetes-helm -y
```

### 3. 설치 확인
```powershell
helm version
```

## 🎯 방법 3: Scoop 사용

### 1. Scoop 설치 (없는 경우)
```powershell
# PowerShell에서 실행
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex
```

### 2. Helm 설치
```powershell
scoop install helm
```

### 3. 설치 확인
```powershell
helm version
```

## 🎯 방법 4: Winget 사용 (Windows 10/11)

### 1. Helm 설치
```powershell
# 관리자 권한으로 PowerShell 실행
winget install Helm.Helm
```

### 2. 설치 확인
```powershell
helm version
```

## 🔧 설치 후 설정

### 1. Helm Repository 추가
```powershell
# ArgoCD Repository 추가
helm repo add argo https://argoproj.github.io/argo-helm

# Bitnami Repository 추가 (필요시)
helm repo add bitnami https://charts.bitnami.com/bitnami

# Repository 업데이트
helm repo update
```

### 2. Repository 목록 확인
```powershell
helm repo list
```

### 3. Helm 차트 검색
```powershell
# ArgoCD 차트 검색
helm search repo argo/argo-cd

# 사용 가능한 차트 목록
helm search repo
```

## 🔧 환경 변수 설정

### 1. KUBECONFIG 설정
```powershell
# AWS EKS 클러스터 설정
aws eks update-kubeconfig --name goteego-team-cluster --region ap-northeast-2

# 또는 수동으로 설정
$env:KUBECONFIG = "$env:USERPROFILE\.kube\config"
```

### 2. AWS 자격 증명 설정
```powershell
# AWS CLI 설정
aws configure

# 또는 환경 변수로 설정
$env:AWS_ACCESS_KEY_ID = "your-access-key"
$env:AWS_SECRET_ACCESS_KEY = "your-secret-key"
$env:AWS_DEFAULT_REGION = "ap-northeast-2"
```

## 🔧 문제 해결

### 1. PATH 문제
```powershell
# PATH 확인
$env:PATH -split ';'

# Helm 경로 확인
Get-Command helm -ErrorAction SilentlyContinue
```

### 2. 권한 문제
```powershell
# 관리자 권한으로 PowerShell 실행
# 또는 실행 정책 변경
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 3. 네트워크 문제
```powershell
# 프록시 설정 (필요시)
$env:HTTP_PROXY = "http://proxy.company.com:8080"
$env:HTTPS_PROXY = "http://proxy.company.com:8080"
```

### 4. SSL 인증서 문제
```powershell
# SSL 검증 비활성화 (개발 환경에서만)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
```

## 📊 설치 확인 스크립트

### 1. 전체 환경 확인
```powershell
Write-Host "=== Helm 설치 확인 ===" -ForegroundColor Green
helm version

Write-Host "`n=== kubectl 설치 확인 ===" -ForegroundColor Green
kubectl version --client

Write-Host "`n=== AWS CLI 설치 확인 ===" -ForegroundColor Green
aws --version

Write-Host "`n=== EKS 클러스터 연결 확인 ===" -ForegroundColor Green
kubectl get nodes

Write-Host "`n=== Helm Repository 확인 ===" -ForegroundColor Green
helm repo list
```

### 2. ArgoCD 설치 테스트
```powershell
# ArgoCD 차트 정보 확인
helm show chart argo/argo-cd

# ArgoCD 설치 시뮬레이션 (실제 설치하지 않음)
helm install argocd argo/argo-cd --dry-run --namespace argocd
```

## 📋 설치 체크리스트

- [ ] Helm 바이너리 다운로드 또는 패키지 매니저 설치
- [ ] PATH 환경 변수 설정
- [ ] Helm 버전 확인
- [ ] ArgoCD Repository 추가
- [ ] Repository 업데이트
- [ ] EKS 클러스터 연결 확인
- [ ] AWS 자격 증명 설정

## ⚠️ 주의사항

1. **관리자 권한**: 일부 설치 방법은 관리자 권한이 필요
2. **실행 정책**: PowerShell 실행 정책 확인 필요
3. **네트워크**: 회사 네트워크에서는 프록시 설정 필요할 수 있음
4. **버전 호환성**: Kubernetes 버전과 Helm 버전 호환성 확인

## 📞 지원

- 📖 [Helm 공식 문서](https://helm.sh/docs/)
- 📚 [Windows 설치 가이드](https://helm.sh/docs/intro/install/)
- 🐛 [문제 해결](https://helm.sh/docs/faq/)
- 💬 [GitHub Issues](https://github.com/helm/helm/issues)

## 🎯 다음 단계

Helm 설치 완료 후:
1. **ArgoCD Repository 추가**: `helm repo add argo https://argoproj.github.io/argo-helm`
2. **Repository 업데이트**: `helm repo update`
3. **ArgoCD 설치**: `ARGOCD_MANUAL_INSTALL.md` 참조 