server:
  service:
    type: ClusterIP
  extraArgs:
    - --insecure
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 200m
      memory: 256Mi
  replicaCount: 1
  ingress:
    enabled: true
    ingressClassName: alb
    annotations:
      kubernetes.io/ingress.class: alb
      alb.ingress.kubernetes.io/scheme: internet-facing
      alb.ingress.kubernetes.io/target-type: ip
      alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}]'
      alb.ingress.kubernetes.io/security-groups: ${alb_security_group_id}
      alb.ingress.kubernetes.io/backend-protocol: HTTP
      alb.ingress.kubernetes.io/healthcheck-path: /healthz
      alb.ingress.kubernetes.io/success-codes: "200-399"

configs:
  params:
    "server.insecure": true
  rbac:
    "policy.default": role:readonly
  repositories:
    - url: https://github.com/CLD-3rd/final-team2-manifest.git

applicationSet:
  enabled: true 