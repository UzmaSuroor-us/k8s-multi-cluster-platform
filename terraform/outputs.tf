output "dev_cluster_endpoint" {
  value = module.eks_dev.cluster_endpoint
}

output "dev_cluster_name" {
  value = module.eks_dev.cluster_name
}

output "prod_cluster_endpoint" {
  value = module.eks_prod.cluster_endpoint
}

output "prod_cluster_name" {
  value = module.eks_prod.cluster_name
}

output "configure_kubectl_dev" {
  value = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks_dev.cluster_name} --alias dev"
}

output "configure_kubectl_prod" {
  value = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks_prod.cluster_name} --alias prod"
}
