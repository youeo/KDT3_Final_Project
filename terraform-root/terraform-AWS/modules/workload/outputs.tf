output "cluster_name" {
  value = aws_eks_cluster.main.name
}

output "cluster_id" {
  value = aws_eks_cluster.main.id
}

output "cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "cluster_ca" {
  value = aws_eks_cluster.main.certificate_authority[0].data
}

output "node_security_group_id" {
  value = aws_security_group.eks_nodes.id
}

output "bastion_security_group_id" {
  value = aws_security_group.bastion_sg.id
}

output "bastion_role_arn" {
  value = aws_iam_role.bastion_role.arn
}

output "ca_role_arn" {
  value = aws_iam_role.cluster_autoscaler.arn
}

output "node_group_name" {
  value = aws_eks_node_group.system.id
}

output "iam_role_arn" {
  value = module.iam_assumable_role_external_secrets.iam_role_arn
}

output "ingress_dns_name" {
  description = "ingress의 DNS 이름"
  value = try(
    kubernetes_ingress_v1.petclinic_ingress.status.0.load_balancer.0.ingress.0.hostname,
    "ALB가 아직 생성 중입니다. 잠시 후 terraform refresh를 실행하세요."
  )
}
