# AWS Load Balancer Controller 수동 설정 매뉴얼

## 개요
Terraform으로 ALB Controller를 배포한 후, webhook 서비스가 정상 동작하지 않는 경우 수동으로 설정을 확인하고 수정하는 방법입니다.

## 1. ALB Controller 상태 확인

### 1.1 Pod 상태 확인
```bash
# ALB Controller Pod 상태 확인
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Pod 로그 확인
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

### 1.2 Webhook 서비스 확인
```bash
# Webhook 서비스 상태 확인
kubectl get svc -n kube-system aws-load-balancer-webhook-service

# Webhook 서비스 엔드포인트 확인
kubectl get endpoints -n kube-system aws-load-balancer-webhook-service

# Webhook 서비스 상세 정보
kubectl describe svc aws-load-balancer-webhook-service -n kube-system
```

### 1.3 Mutating Admission Webhook 확인
```bash
# Webhook 설정 확인
kubectl get validatingwebhookconfigurations | grep aws-load-balancer
kubectl get mutatingwebhookconfigurations | grep aws-load-balancer

# Webhook 상세 정보
kubectl describe mutatingwebhookconfigurations aws-load-balancer-webhook
```

## 2. 문제 해결 단계

### 2.1 Webhook 서비스가 없는 경우
```bash
# ALB Controller 재배포
kubectl delete deployment aws-load-balancer-controller -n kube-system
kubectl apply -f https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/latest/download/v2_5_4_full.yaml
```

### 2.2 Webhook 서비스는 있지만 엔드포인트가 없는 경우
```bash
# ALB Controller Pod 재시작
kubectl rollout restart deployment aws-load-balancer-controller -n kube-system

# Pod가 Ready 상태가 될 때까지 대기
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=aws-load-balancer-controller -n kube-system --timeout=300s
```

### 2.3 Webhook 설정 문제인 경우
```bash
# Webhook 설정 삭제 후 재생성
kubectl delete mutatingwebhookconfigurations aws-load-balancer-webhook
kubectl delete validatingwebhookconfigurations aws-load-balancer-webhook

# ALB Controller 재배포
kubectl rollout restart deployment aws-load-balancer-controller -n kube-system
```

## 3. 수동 설치 (Terraform 실패 시)

### 3.1 IAM 정책 및 역할 확인
```bash
# IAM 역할 확인
aws iam get-role --role-name eksctl-final-team2-cluster-addon-iamserviceaccount-kube-system-aws-load-balancer-controller

# IAM 정책 확인
aws iam list-attached-role-policies --role-name eksctl-final-team2-cluster-addon-iamserviceaccount-kube-system-aws-load-balancer-controller
```

### 3.2 수동 Helm 설치
```bash
# Helm repository 추가
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# ALB Controller 수동 설치
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=final-team2-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=ap-northeast-2 \
  --set vpcId=vpc-xxxxxxxxx \
  --set replicaCount=1 \
  --set resources.requests.cpu=100m \
  --set resources.requests.memory=128Mi \
  --set resources.limits.cpu=500m \
  --set resources.limits.memory=512Mi \
  --set webhook.port=9443 \
  --set webhook.timeoutSeconds=30
```

## 4. 테스트 및 검증

### 4.1 LoadBalancer 서비스 테스트
```bash
# 테스트용 LoadBalancer 서비스 생성
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: test-lb
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: nlb
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app: test
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test
  template:
    metadata:
      labels:
        app: test
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
EOF

# LoadBalancer 생성 확인
kubectl get svc test-lb
```

### 4.2 Webhook 동작 확인
```bash
# Webhook 로그 확인
kubectl logs -n kube-system deployment/aws-load-balancer-controller | grep webhook

# Webhook 요청 테스트
kubectl get svc test-lb -o yaml | kubectl apply -f -
```

## 5. 문제 해결 체크리스트

- [ ] ALB Controller Pod가 Running 상태인가?
- [ ] Webhook 서비스가 존재하는가?
- [ ] Webhook 엔드포인트가 Ready 상태인가?
- [ ] Mutating Admission Webhook이 등록되어 있는가?
- [ ] IAM 역할과 정책이 올바르게 설정되어 있는가?
- [ ] 클러스터 이름과 VPC ID가 올바른가?

## 6. 로그 분석

### 6.1 ALB Controller 로그 확인
```bash
# 실시간 로그 확인
kubectl logs -f -n kube-system deployment/aws-load-balancer-controller

# 특정 시간대 로그 확인
kubectl logs -n kube-system deployment/aws-load-balancer-controller --since=10m
```

### 6.2 Webhook 관련 로그 필터링
```bash
# Webhook 관련 로그만 확인
kubectl logs -n kube-system deployment/aws-load-balancer-controller | grep -i webhook

# 에러 로그 확인
kubectl logs -n kube-system deployment/aws-load-balancer-controller | grep -i error
```

## 7. 완전 재설치 (최후의 수단)

```bash
# 1. 기존 ALB Controller 완전 제거
kubectl delete deployment aws-load-balancer-controller -n kube-system
kubectl delete svc aws-load-balancer-webhook-service -n kube-system
kubectl delete mutatingwebhookconfigurations aws-load-balancer-webhook
kubectl delete validatingwebhookconfigurations aws-load-balancer-webhook
kubectl delete serviceaccount aws-load-balancer-controller -n kube-system

# 2. Helm으로 완전 재설치
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=final-team2-cluster \
  --set serviceAccount.create=true \
  --set region=ap-northeast-2 \
  --set vpcId=vpc-xxxxxxxxx

# 3. 상태 확인
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
kubectl get svc -n kube-system aws-load-balancer-webhook-service
```

## 주의사항

1. **VPC ID 확인**: 위의 명령어에서 `vpc-xxxxxxxxx`를 실제 VPC ID로 변경하세요.
2. **클러스터 이름 확인**: `final-team2-cluster`를 실제 클러스터 이름으로 변경하세요.
3. **리전 확인**: `ap-northeast-2`를 실제 리전으로 변경하세요.
4. **IAM 권한**: AWS CLI가 올바른 권한을 가지고 있는지 확인하세요.

## 참고 자료

- [AWS Load Balancer Controller 공식 문서](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [EKS Helm Charts](https://github.com/aws/eks-charts)
- [Troubleshooting Guide](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/deploy/troubleshooting/) 