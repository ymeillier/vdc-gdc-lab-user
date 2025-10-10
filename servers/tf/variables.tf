variable "servers" {
  description = "List of server names following the naming convention: cluster-prefix-node-type-rack-10-rack-id-overlay-net-ip-stack-machine-type"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for server in var.servers : length(split("-", server)) >= 8
    ])
    error_message = "Each server name must follow the naming convention with at least 8 parts separated by hyphens."
  }
}

variable "base_image" {
  description = "Base image family or specific image to use for server instances. When using a family name (e.g., 'ubuntu-pro-2004-lts'), new instances will use the latest image in the family, but existing instances will not be recreated when newer images become available."
  type        = string
  default     = "ubuntu-pro-2004-lts"
}

variable "default_machine_type" {
  description = "Default machine type if not specified in server name"
  type        = string
  default     = "n2-standard-4"
}

variable "disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 128
}

variable "disk_type" {
  description = "Boot disk type"
  type        = string
  default     = "pd-balanced"
}

variable "enable_ip_forwarding" {
  description = "Enable IP forwarding on instances"
  type        = bool
  default     = true
}

variable "enable_oslogin" {
  description = "Enable OS Login on instances"
  type        = bool
  default     = true
}

variable "scopes" {
  description = "The scopes for the service account."
  type        = list(string)
  default     = ["cloud-platform"]
}

variable "enable_auto_shutdown" {
  description = "Enable automatic shutdown of server instances at 9pm MST"
  type        = bool
  default     = true
}

variable "enable_auto_startup" {
  description = "Enable automatic startup of server instances on weekday mornings"
  type        = bool
  default     = false
}
