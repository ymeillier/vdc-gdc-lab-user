# Variables for GDC project creation
variable "user_account" {
  description = "The user account to grant permissions to"
  type        = string
}

variable "svc_account" {
  description = "The service account to grant permissions to"
  type        = string
}

variable "path_module" {
  description = "Path to the module"
  type        = string
}

variable "orgid" {
  description = "GCP Organization ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
}

variable "suffix" {
  description = "Project suffix (injected from main.sh)"
  type        = string
}
