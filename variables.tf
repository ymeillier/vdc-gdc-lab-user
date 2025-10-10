variable "gcp_orgid" {
  type        = string
  description = "The GCP Organization ID."
}

variable "gcp_project" {
  type        = string
  description = "The GCP Project ID."
}

variable "gcp_region" {
  type        = string
  description = "The GCP Region."
}

variable "gcp_zone" {
  type        = string
  description = "The GCP Zone for GCE instances."
}

variable "gcp_project_number" {
  type        = string
  description = "The GCP Project Number."
}

variable "gcp_project_folder_id" {
  type        = string
  description = "The GCP Project parent folder."
}

variable "user_account" {
  type        = string
  description = "The user account email."
}

variable "svc_account" {
  type        = string
  description = "The service account created by main.sh and used for terraform applies."
}

variable "path_module" {
  type        = string
  description = "The local path to the module directory."
}

variable "gce_sa_eve_ng_368801" {
  type        = string
  description = "The GCE service account for the EVE-NG project."
}

variable "pnetlab_server_name" {
  type        = string
  description = "The name of the PNet Lab server instance."
  default     = "vdc-pnetlab-v5-2"
}

variable "instance_timezone" {
  type        = string
  description = "Timezone for instance scheduling (e.g., America/Denver for MST/MDT)"
  default     = "America/Denver"
}

variable "auto_shutdown_time" {
  type        = string
  description = "Time to automatically shutdown instances (24-hour format, e.g., '21' for 9pm)"
  default     = "21"
}

variable "auto_startup_time" {
  type        = string
  description = "Time to automatically startup instances on weekdays (24-hour format, e.g., '08' for 8am)"
  default     = "08"
}

variable "enable_auto_startup" {
  type        = bool
  description = "Whether to enable automatic startup of instances on weekdays"
  default     = false
}

variable "enable_auto_shutdown" {
  type        = bool
  description = "Whether to enable automatic shutdown of instances at night"
  default     = true
}
