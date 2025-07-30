# final-team2-infra
✈️ GotEEgo 서비스의 인프라 설정 및 배포 코드를 관리하는 레포지토리입니다. CLD-3rd Team 2에서 운영합니다.
terraform/  
├── modules/  
│   ├── vpc/                    # VPC, 서브넷, 라우팅  
│   ├── eks/                    # EKS 클러스터  
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
