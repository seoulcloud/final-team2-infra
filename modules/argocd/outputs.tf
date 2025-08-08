output "release_name" {
  description = "Helm release name"
  value       = helm_release.argocd.name
}

output "namespace" {
  description = "Namespace where ArgoCD is installed"
  value       = helm_release.argocd.namespace
} 