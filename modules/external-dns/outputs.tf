output "service_account_name" { value = kubernetes_service_account.externaldns.metadata[0].name }
output "role_arn" { value = aws_iam_role.externaldns.arn }
output "release_name" { value = helm_release.external_dns.name }