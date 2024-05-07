# variables.tf

variable "location" {
  description = "Azure region"
  default     = "East US"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  default     = "10.0.2.0/24"
}

variable "admin_password" {
  description = "Admin password for virtual machines"
}
