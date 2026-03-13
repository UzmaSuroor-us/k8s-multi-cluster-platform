variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "k8s_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}
